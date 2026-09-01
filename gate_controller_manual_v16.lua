-- ZiutekCraft Afterfall // Brama G-01 MANUAL v1.6
-- BEZ Player Detectora.
-- 2+ monitory, osobne OTWORZ / ZAMKNIJ, auto-close 10 s + awaryjny watchdog.

local TRAVEL = 7
local HOLD_OPEN = 10
local OPEN_MOD = -2
local CLOSE_MOD = 2
local POLL = 0.10
local MONITOR_SCALE = 0.5
local MOTION_TIMEOUT = 20
local FAILSAFE_CLOSE = 30
local CONFIG_FILE = "/afterfall_gate_reverse.txt"

local gearshift, gearshiftName
local speaker
local monitors = {}
local reverse = false

local state = "closed" -- closed/opening/open/closing/error
local motionTarget = nil
local motionStarted = 0
local autoCloseAt = nil
local failsafeAt = nil
local lastError = nil
local flash = nil
local flashUntil = 0

local function now() return os.epoch("utc") end

local function readFile(path)
  if not fs.exists(path) then return nil end
  local h=fs.open(path,"r"); if not h then return nil end
  local v=h.readAll(); h.close(); return v
end
local function writeFile(path,v)
  local h=fs.open(path,"w"); if h then h.write(tostring(v)); h.close() end
end
reverse = readFile(CONFIG_FILE)=="1"

local function methods(name)
  local ok,list=pcall(peripheral.getMethods,name)
  return ok and type(list)=="table" and list or {}
end
local function hasMethod(name,wanted)
  for _,m in ipairs(methods(name)) do if m==wanted then return true end end
  return false
end
local function findGearshift()
  for _,name in ipairs(peripheral.getNames()) do
    if hasMethod(name,"move") and hasMethod(name,"isRunning") then
      return peripheral.wrap(name),name
    end
  end
end
local function findMonitors()
  local out={}
  for _,name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name)=="monitor" then
      local p=peripheral.wrap(name)
      if p and p.getSize then
        pcall(p.setTextScale,MONITOR_SCALE)
        pcall(p.setCursorBlink,false)
        out[#out+1]={name=name,p=p}
      end
    end
  end
  return out
end
local function discover()
  gearshift,gearshiftName=findGearshift()
  speaker=peripheral.find("speaker")
  monitors=findMonitors()
end
local function beep(note,inst)
  if speaker then pcall(speaker.playNote,inst or "bit",0.6,note or 12) end
end
local function setFlash(t,sec)
  flash=t; flashUntil=now()+(sec or 2)*1000
end
local function direction(target)
  local o,c=OPEN_MOD,CLOSE_MOD
  if reverse then o,c=c,o end
  return target=="open" and o or c
end
local function isRunning()
  if not gearshift then return false,"BRAK GEARSHIFT" end
  local ok,r=pcall(gearshift.isRunning)
  if not ok then return false,tostring(r) end
  return r==true,nil
end

local function startMove(target)
  if not gearshift then
    lastError="BRAK GEARSHIFT"; state="error"; setFlash("BRAK GEARSHIFT",3); beep(2,"bass"); return false
  end
  local ok,err=pcall(gearshift.move,TRAVEL,direction(target))
  if not ok then
    lastError=tostring(err); state="error"; setFlash("BLAD MOVE",4); beep(2,"bass"); return false
  end
  motionTarget=target
  motionStarted=now()
  state=target=="open" and "opening" or "closing"
  lastError=nil
  if target=="open" then
    autoCloseAt=nil
    failsafeAt=now()+FAILSAFE_CLOSE*1000
    setFlash("OTWIERANIE...",1)
    beep(15)
  else
    autoCloseAt=nil
    setFlash("ZAMYKANIE...",1)
    beep(7)
  end
  return true
end

local function openGate()
  if state=="open" then
    autoCloseAt=now()+HOLD_OPEN*1000
    failsafeAt=now()+FAILSAFE_CLOSE*1000
    setFlash("AUTO CLOSE = 10 SEK",1.5)
    beep(18,"hat")
    return
  end
  if state=="opening" then
    failsafeAt=now()+FAILSAFE_CLOSE*1000
    setFlash("JUZ SIE OTWIERA",1)
    return
  end
  startMove("open")
end

local function closeGate()
  autoCloseAt=nil
  failsafeAt=nil
  if state=="closing" then return end
  if state=="closed" then setFlash("JUZ ZAMKNIETA",1); return end
  startMove("closed")
end

local function finishMotion(target)
  motionTarget=nil
  motionStarted=0
  if target=="open" then
    state="open"
    autoCloseAt=now()+HOLD_OPEN*1000
    -- failsafe pozostaje aktywny jako dodatkowe zabezpieczenie
    setFlash("OTWARTA // AUTO 10 SEK",1.5)
    beep(18,"bell")
  else
    state="closed"
    autoCloseAt=nil
    failsafeAt=nil
    setFlash("ZAMKNIETA",1)
    beep(8)
  end
end

local function updateMotion()
  if not motionTarget then return end
  local elapsed=now()-motionStarted
  local running,err=isRunning()
  if err then lastError=err end

  if elapsed>=300 and not running and not err then
    local target=motionTarget
    finishMotion(target)
    return
  end

  if elapsed>=MOTION_TIMEOUT*1000 then
    lastError="TIMEOUT isRunning"
    state="error"
    motionTarget=nil
    setFlash("TIMEOUT // FAILSAFE AKTYWNY",4)
    beep(2,"bass")
  end
end

local function secondsLeft()
  if not autoCloseAt then return nil end
  return math.max(0,math.ceil((autoCloseAt-now())/1000))
end

local function stateLabel()
  if state=="closed" then return "ZAMKNIETA",colors.red end
  if state=="opening" then return "OTWIERANIE",colors.yellow end
  if state=="open" then return "OTWARTA",colors.lime end
  if state=="closing" then return "ZAMYKANIE",colors.orange end
  return "BLAD",colors.red
end

local function buttonBounds(W,H)
  local top=math.max(7,math.floor(H*0.32))
  local bottom=math.max(top+5,H-5)
  local gap=1
  local inner=math.max(8,W-4-gap)
  local lw=math.floor(inner/2)
  local rw=inner-lw
  local lx1=2; local lx2=lx1+lw-1
  local rx1=lx2+gap+1; local rx2=math.min(W-1,rx1+rw-1)
  return lx1,lx2,rx1,rx2,top,bottom
end

local function drawOne(entry)
  local m=entry.p
  local ok,W,H=pcall(m.getSize); if not ok then return end
  local function fill(x,y,w,bg)
    if y<1 or y>H or x>W then return end
    w=math.max(0,math.min(w,W-x+1)); if w<1 then return end
    m.setCursorPos(x,y); m.setBackgroundColor(bg); m.write(string.rep(" ",w))
  end
  local function put(x,y,t,fg,bg)
    if y<1 or y>H or x>W then return end
    m.setCursorPos(x,y); m.setTextColor(fg or colors.white); m.setBackgroundColor(bg or colors.black)
    m.write(tostring(t):sub(1,W-x+1))
  end
  local function center(y,t,fg,bg,x1,x2)
    x1=x1 or 1; x2=x2 or W; t=tostring(t)
    put(x1+math.max(0,math.floor((x2-x1+1-#t)/2)),y,t,fg,bg)
  end

  m.setBackgroundColor(colors.black); m.clear()
  fill(1,1,W,colors.orange); center(1," AFTERFALL // BRAMA G-01 ",colors.black,colors.orange)
  center(2,gearshift and "GEAR:OK // AUTO-CLOSE ON" or "GEAR:BRAK // OFFLINE",gearshift and colors.lime or colors.red)

  local label,col=stateLabel()
  if flash and now()<flashUntil then center(4,flash,colors.yellow)
  else center(4,"STAN: "..label,col) end

  local sec=secondsLeft()
  if sec then center(5,"SAMOCZYNNE ZAMKNIECIE: "..sec.." s",colors.yellow)
  elseif state=="open" then center(5,"AUTO-CLOSE AKTYWNE",colors.yellow)
  else center(5,"BEZ PLAYER DETECTORA",colors.lightGray) end

  local lx1,lx2,rx1,rx2,top,bottom=buttonBounds(W,H)
  local openBg=gearshift and colors.green or colors.gray
  local closeBg=gearshift and colors.red or colors.gray
  for y=top,bottom do
    fill(lx1,y,lx2-lx1+1,openBg)
    fill(rx1,y,rx2-rx1+1,closeBg)
  end
  local cy=math.floor((top+bottom)/2)
  center(cy-1,"OTWORZ",colors.black,openBg,lx1,lx2); center(cy+1,"BRAME",colors.black,openBg,lx1,lx2)
  center(cy-1,"ZAMKNIJ",colors.white,closeBg,rx1,rx2); center(cy+1,"BRAME",colors.white,closeBg,rx1,rx2)

  if lastError then center(H-3,"ERR: "..lastError:sub(1,math.max(1,W-6)),colors.red) end
  fill(1,H-2,W,colors.gray); center(H-2," OTWORZ | ZAMKNIJ | AUTO 10 s ",colors.black,colors.gray)
  center(H,"UWAGA // RUCH BRAMY",colors.orange)
end

local function drawAll()
  for _,e in ipairs(monitors) do pcall(drawOne,e) end
end
local function handleTouch(side,x,y)
  for _,e in ipairs(monitors) do
    if e.name==side then
      local ok,W,H=pcall(e.p.getSize); if not ok then return end
      local lx1,lx2,rx1,rx2,top,bottom=buttonBounds(W,H)
      if y>=top and y<=bottom then
        if x>=lx1 and x<=lx2 then openGate()
        elseif x>=rx1 and x<=rx2 then closeGate() end
      end
      return
    end
  end
end
local function redrawTerminal()
  term.clear(); term.setCursorPos(1,1)
  term.setTextColor(colors.orange); print("AFTERFALL // BRAMA G-01 MANUAL v1.6")
  term.setTextColor(colors.white)
  print("MONITORY: "..#monitors)
  print("GEARSHIFT: "..(gearshiftName or "BRAK"))
  print("PLAYER DETECTOR: WYLACZONY")
  print("STAN: "..string.upper(state))
  local sec=secondsLeft(); if sec then print("AUTO-CLOSE: "..sec.." s") end
  if failsafeAt and state~="closed" then print("FAILSAFE: AKTYWNY") end
  if motionTarget then
    local running=isRunning(); print("RUCH: "..motionTarget.." | isRunning="..tostring(running))
  end
  if lastError then term.setTextColor(colors.red); print("BLAD: "..lastError); term.setTextColor(colors.white) end
  print("")
  term.setTextColor(colors.lightGray)
  print("OTWORZ -> po pelnym otwarciu auto-zamkniecie 10 s")
  print("Jesli Create sie zatnie: watchdog i tak wymusi ZAMKNIJ")
  print("O=open | C=close | R=reverse | Q=stop")
end

discover(); redrawTerminal(); drawAll(); beep(12)
local timer=os.startTimer(POLL)

while true do
  local e={os.pullEvent()}
  if e[1]=="timer" and e[2]==timer then
    discover()
    updateMotion()

    if autoCloseAt and now()>=autoCloseAt and state~="closed" and state~="closing" then
      setFlash("AUTO ZAMYKANIE",1)
      closeGate()
    end

    -- awaryjne zamkniecie niezalezne od tego, czy isRunning poprawnie wykrylo koniec otwierania
    if failsafeAt and now()>=failsafeAt and state~="closed" and state~="closing" then
      lastError="FAILSAFE CLOSE"
      setFlash("FAILSAFE // ZAMYKANIE",2)
      failsafeAt=nil
      startMove("closed")
    end

    redrawTerminal(); drawAll(); timer=os.startTimer(POLL)

  elseif e[1]=="monitor_touch" then
    handleTouch(e[2],e[3],e[4]); redrawTerminal(); drawAll()

  elseif e[1]=="key" then
    if e[2]==keys.o then openGate()
    elseif e[2]==keys.c then closeGate()
    elseif e[2]==keys.r then
      reverse=not reverse; writeFile(CONFIG_FILE,reverse and "1" or "0"); setFlash("REVERSE: "..tostring(reverse),2); beep(10)
    elseif e[2]==keys.q then
      for _,m in ipairs(monitors) do pcall(function() m.p.setBackgroundColor(colors.black); m.p.clear() end) end
      term.clear(); term.setCursorPos(1,1); print("BRAMA G-01 // OFFLINE"); return
    end
    redrawTerminal(); drawAll()

  elseif e[1]=="peripheral" or e[1]=="peripheral_detach" or e[1]=="monitor_resize" then
    discover(); redrawTerminal(); drawAll()
  end
end
