-- ZiutekCraft Afterfall // Brama G-01 MANUAL v1.5
-- BEZ Player Detectora.
-- 2+ monitory, osobne przyciski OTWORZ / ZAMKNIJ, auto-close 10 s.
-- Sterowanie NIEBLOKUJACE: brak while isRunning().

local TRAVEL = 7
local HOLD_OPEN = 10
local OPEN_MOD = -2
local CLOSE_MOD = 2
local POLL = 0.10
local DISCOVER_EVERY = 1.0
local MONITOR_SCALE = 0.5
local MOTION_TIMEOUT = 20

local CONFIG_FILE = "/afterfall_gate_reverse.txt"

local gearshift, gearshiftName
local speaker
local monitors = {}
local reverse = false

local gateState = "closed" -- closed/opening/open/closing/error
local motionTarget = nil
local motionStarted = 0
local closeAt = nil
local lastMoveError = nil
local flashMessage = nil
local flashUntil = 0
local lastDiscover = 0

local function now()
  return os.epoch("utc")
end

local function readFile(path)
  if not fs.exists(path) then return nil end
  local h = fs.open(path,"r")
  if not h then return nil end
  local v = h.readAll(); h.close(); return v
end

local function writeFile(path,value)
  local h = fs.open(path,"w")
  if h then h.write(tostring(value)); h.close() end
end

reverse = readFile(CONFIG_FILE) == "1"

local function methods(name)
  local ok,list = pcall(peripheral.getMethods,name)
  return ok and type(list)=="table" and list or {}
end

local function hasMethod(name,wanted)
  for _,m in ipairs(methods(name)) do
    if m==wanted then return true end
  end
  return false
end

local function findGearshift()
  for _,name in ipairs(peripheral.getNames()) do
    if hasMethod(name,"move") and hasMethod(name,"isRunning") then
      return peripheral.wrap(name),name
    end
  end
  return nil,nil
end

local function findMonitors()
  local out={}
  for _,name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name)=="monitor" then
      local p=peripheral.wrap(name)
      if p and p.getSize and p.setTextScale then
        pcall(p.setTextScale,MONITOR_SCALE)
        pcall(p.setCursorBlink,false)
        pcall(p.setBackgroundColor,colors.black)
        out[#out+1]={name=name,p=p}
      end
    end
  end
  return out
end

local function discover(force)
  if not force and (now()-lastDiscover)<DISCOVER_EVERY*1000 then return end
  lastDiscover=now()
  gearshift,gearshiftName=findGearshift()
  speaker=peripheral.find("speaker")
  monitors=findMonitors()
end

local function beep(note,instrument)
  if speaker then pcall(speaker.playNote,instrument or "bit",0.7,note or 12) end
end

local function setFlash(msg,seconds)
  flashMessage=tostring(msg)
  flashUntil=now()+(seconds or 2)*1000
end

local function direction(target)
  local o,c=OPEN_MOD,CLOSE_MOD
  if reverse then o,c=c,o end
  return target=="open" and o or c
end

local function isRunning()
  if not gearshift then return false,nil end
  local ok,running=pcall(gearshift.isRunning)
  if not ok then return false,"isRunning: "..tostring(running) end
  return running==true,nil
end

local function startMove(target)
  if not gearshift then
    lastMoveError="BRAK GEARSHIFT"
    gateState="error"
    setFlash("BRAK GEARSHIFT",3)
    beep(2,"bass")
    return false
  end

  local ok,err=pcall(gearshift.move,TRAVEL,direction(target))
  if not ok then
    lastMoveError=tostring(err)
    gateState="error"
    setFlash("BLAD MOVE",4)
    beep(2,"bass")
    return false
  end

  motionTarget=target
  motionStarted=now()
  closeAt=nil
  gateState=(target=="open") and "opening" or "closing"
  lastMoveError=nil
  setFlash(target=="open" and "OTWIERANIE..." or "ZAMYKANIE...",1)
  beep(target=="open" and 15 or 7)
  return true
end

local function forceOpen()
  if gateState=="open" then
    closeAt=now()+HOLD_OPEN*1000
    setFlash("LICZNIK = 10 SEK",1.2)
    beep(18,"hat")
    return true
  end
  return startMove("open")
end

local function forceClose()
  closeAt=nil
  if gateState=="closed" then
    setFlash("JUZ ZAMKNIETA",1)
    return true
  end
  return startMove("closed")
end

local function finishMotion(target)
  motionTarget=nil
  motionStarted=0
  if target=="open" then
    gateState="open"
    closeAt=now()+HOLD_OPEN*1000
    setFlash("OTWARTA // 10 SEK",1.5)
    beep(18,"bell")
  else
    gateState="closed"
    closeAt=nil
    setFlash("ZAMKNIETA",1)
    beep(8,"bit")
  end
end

local function updateMotion()
  if not motionTarget then return end

  local elapsed=now()-motionStarted
  local running,err=isRunning()
  if err then
    lastMoveError=err
    return
  end

  if elapsed>=300 and not running then
    local target=motionTarget
    finishMotion(target)
    return
  end

  if elapsed>=MOTION_TIMEOUT*1000 then
    lastMoveError="TIMEOUT isRunning"
    gateState="error"
    motionTarget=nil
    closeAt=nil
    setFlash("TIMEOUT // SPRAWDZ BRAME",5)
    beep(2,"bass")
  end
end

local function secondsLeft()
  if gateState~="open" or not closeAt then return nil end
  return math.max(0,math.ceil((closeAt-now())/1000))
end

local function stateLabel()
  if gateState=="closed" then return "ZAMKNIETA",colors.red end
  if gateState=="opening" then return "OTWIERANIE",colors.yellow end
  if gateState=="open" then return "OTWARTA",colors.lime end
  if gateState=="closing" then return "ZAMYKANIE",colors.orange end
  return "BLAD",colors.red
end

local function buttonBounds(W,H)
  local top=math.max(7,math.floor(H*0.32))
  local bottom=math.max(top+5,H-5)
  local gap=1
  local innerW=math.max(8,W-4-gap)
  local leftW=math.floor(innerW/2)
  local rightW=innerW-leftW
  local lx1=2
  local lx2=lx1+leftW-1
  local rx1=lx2+gap+1
  local rx2=rx1+rightW-1
  if rx2>W-1 then rx2=W-1 end
  return lx1,lx2,rx1,rx2,top,bottom
end

local function drawOne(entry)
  local m=entry.p
  local ok,W,H=pcall(m.getSize)
  if not ok then return end

  local function fill(x,y,w,bg)
    if y<1 or y>H or x>W then return end
    x=math.max(1,x); w=math.max(0,math.min(w,W-x+1)); if w<1 then return end
    m.setCursorPos(x,y);m.setBackgroundColor(bg);m.write(string.rep(" ",w))
  end

  local function put(x,y,t,fg,bg)
    if y<1 or y>H then return end
    x=math.max(1,math.floor(x)); if x>W then return end
    m.setCursorPos(x,y);m.setTextColor(fg or colors.white);m.setBackgroundColor(bg or colors.black)
    m.write(tostring(t):sub(1,W-x+1))
  end

  local function centerIn(x1,x2,y,t,fg,bg)
    t=tostring(t)
    local width=x2-x1+1
    local x=x1+math.max(0,math.floor((width-#t)/2))
    put(x,y,t,fg,bg)
  end

  local function center(y,t,fg,bg)
    t=tostring(t)
    put(math.max(1,math.floor((W-#t)/2)+1),y,t,fg,bg)
  end

  m.setBackgroundColor(colors.black);m.clear()
  fill(1,1,W,colors.orange)
  center(1," AFTERFALL // BRAMA G-01 ",colors.black,colors.orange)

  center(2,gearshift and "GEAR:OK // MANUAL" or "GEAR:BRAK // OFFLINE",gearshift and colors.lime or colors.red)

  local label,col=stateLabel()
  if flashMessage and now()<flashUntil then
    center(4,flashMessage,colors.yellow)
  else
    center(4,"STAN: "..label,col)
  end

  local sec=secondsLeft()
  if sec then center(5,"AUTO CLOSE: "..sec.." s",colors.yellow)
  else center(5,"BEZ PLAYER DETECTORA",colors.lightGray) end

  local lx1,lx2,rx1,rx2,top,bottom=buttonBounds(W,H)
  local openBg=gearshift and colors.green or colors.gray
  local closeBg=gearshift and colors.red or colors.gray

  for y=top,bottom do
    fill(lx1,y,lx2-lx1+1,openBg)
    fill(rx1,y,rx2-rx1+1,closeBg)
  end

  local cy=math.floor((top+bottom)/2)
  if gearshift then
    centerIn(lx1,lx2,cy-1,"OTWORZ",colors.black,openBg)
    centerIn(lx1,lx2,cy+1,"BRAME",colors.black,openBg)
    centerIn(rx1,rx2,cy-1,"ZAMKNIJ",colors.white,closeBg)
    centerIn(rx1,rx2,cy+1,"BRAME",colors.white,closeBg)
  else
    centerIn(lx1,lx2,cy,"OFFLINE",colors.white,openBg)
    centerIn(rx1,rx2,cy,"OFFLINE",colors.white,closeBg)
  end

  if lastMoveError then
    center(H-3,"ERR: "..lastMoveError:sub(1,math.max(1,W-6)),colors.red)
  end

  fill(1,H-2,W,colors.gray)
  center(H-2," OTWORZ  |  ZAMKNIJ ",colors.black,colors.gray)
  center(H,"UWAGA // RUCH BRAMY",colors.orange)
end

local function drawAll()
  for _,entry in ipairs(monitors) do pcall(drawOne,entry) end
end

local function handleTouch(side,x,y)
  for _,entry in ipairs(monitors) do
    if entry.name==side then
      local ok,W,H=pcall(entry.p.getSize)
      if not ok then return end
      local lx1,lx2,rx1,rx2,top,bottom=buttonBounds(W,H)
      if y>=top and y<=bottom then
        if x>=lx1 and x<=lx2 then
          forceOpen()
        elseif x>=rx1 and x<=rx2 then
          forceClose()
        end
      end
      return
    end
  end
end

local function redrawTerminal()
  term.clear();term.setCursorPos(1,1)
  term.setTextColor(colors.orange);print("AFTERFALL // BRAMA G-01 MANUAL v1.5")
  term.setTextColor(colors.white)
  print("MONITORY: "..#monitors)
  for i,e in ipairs(monitors) do print("  "..i..": "..e.name) end
  print("GEARSHIFT: "..(gearshiftName or "BRAK"))
  print("PLAYER DETECTOR: WYLACZONY")
  print("STAN: "..string.upper(gateState))
  local sec=secondsLeft(); if sec then print("AUTO-CLOSE: "..sec.." s") end
  if motionTarget then
    local running=isRunning()
    print("RUCH: "..string.upper(motionTarget).." | isRunning="..tostring(running))
  end
  if lastMoveError then
    term.setTextColor(colors.red);print("BLAD: "..lastMoveError);term.setTextColor(colors.white)
  end
  print("")
  term.setTextColor(colors.lightGray)
  print("Monitor: zielony OTWORZ | czerwony ZAMKNIJ")
  print("O = OPEN | C = CLOSE | R = reverse | Q = stop")
  term.setTextColor(colors.white)
end

discover(true)
redrawTerminal();drawAll();beep(12)
local timer=os.startTimer(POLL)

while true do
  local e={os.pullEvent()}

  if e[1]=="timer" and e[2]==timer then
    discover(false)
    updateMotion()

    if gateState=="open" and closeAt and now()>=closeAt then
      forceClose()
    end

    redrawTerminal();drawAll()
    timer=os.startTimer(POLL)

  elseif e[1]=="monitor_touch" then
    handleTouch(e[2],e[3],e[4])
    redrawTerminal();drawAll()

  elseif e[1]=="key" then
    if e[2]==keys.o then
      forceOpen()
    elseif e[2]==keys.c then
      forceClose()
    elseif e[2]==keys.r then
      reverse=not reverse
      writeFile(CONFIG_FILE,reverse and "1" or "0")
      setFlash("REVERSE: "..tostring(reverse),2)
      beep(10)
    elseif e[2]==keys.q then
      for _,entry in ipairs(monitors) do
        pcall(function()
          entry.p.setBackgroundColor(colors.black)
          entry.p.clear()
        end)
      end
      term.clear();term.setCursorPos(1,1);print("BRAMA G-01 // OFFLINE")
      return
    end
    redrawTerminal();drawAll()

  elseif e[1]=="peripheral" or e[1]=="peripheral_detach" or e[1]=="monitor_resize" then
    discover(true);redrawTerminal();drawAll()
  end
end
