-- ZiutekCraft Afterfall // Brama glownego wjazdu v1.3
-- 2+ monitory, reczne OTWORZ, auto-close 10 s, Player Detector, Create Sequenced Gearshift

local DETECT_RANGE = 18
local TRAVEL = 7
local AUTO_HOLD_OPEN = 4
local MANUAL_HOLD_OPEN = 10
local OPEN_MOD = -2
local CLOSE_MOD = 2
local POLL = 0.20
local MONITOR_SCALE = 0.5

local CONFIG_FILE = "/afterfall_gate_reverse.txt"

local detector, detectorName
local gearshift, gearshiftName
local speaker
local monitors = {}
local gateState = "closed"
local reverse = false
local clearSince = nil
local manualCloseAt = nil
local flashMessage = nil
local flashUntil = 0
local lastMoveError = nil

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
  for _,m in ipairs(methods(name)) do if m==wanted then return true end end
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

local function findDetector()
  for _,name in ipairs(peripheral.getNames()) do
    if hasMethod(name,"getPlayersInRange") then
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

local function discover()
  detector,detectorName=findDetector()
  gearshift,gearshiftName=findGearshift()
  speaker=peripheral.find("speaker")
  monitors=findMonitors()
end

local function beep(note,instrument)
  if speaker then pcall(speaker.playNote,instrument or "bit",0.7,note or 12) end
end

local function setFlash(msg,seconds)
  flashMessage=tostring(msg)
  flashUntil=os.epoch("utc")+(seconds or 2)*1000
end

local function getPlayers()
  if not detector then return {} end
  local ok,list=pcall(detector.getPlayersInRange,DETECT_RANGE)
  return ok and type(list)=="table" and list or {}
end

local function direction(target)
  local o,c=OPEN_MOD,CLOSE_MOD
  if reverse then o,c=c,o end
  return target=="open" and o or c
end

local function waitForGearshift()
  if not gearshift then return end
  while true do
    local ok,running=pcall(gearshift.isRunning)
    if not ok or running~=true then break end
    sleep(0.05)
  end
end

local function moveGate(target,force)
  if not force and gateState==target then return true end
  if not gearshift then
    lastMoveError="BRAK GEARSHIFT"
    setFlash(lastMoveError,3)
    beep(3,"bass")
    return false
  end

  local okRun,running=pcall(gearshift.isRunning)
  if okRun and running then waitForGearshift() end

  setFlash(target=="open" and "OTWIERANIE..." or "ZAMYKANIE...",1)
  local ok,err=pcall(gearshift.move,TRAVEL,direction(target))
  if not ok then
    lastMoveError=tostring(err)
    setFlash("BLAD RUCHU",4)
    beep(2,"bass")
    return false
  end

  waitForGearshift()
  gateState=target
  lastMoveError=nil
  if target=="closed" then
    manualCloseAt=nil
    clearSince=nil
  end
  beep(target=="open" and 16 or 8)
  return true
end

local function manualOpen()
  if not moveGate("open",true) then return false end
  manualCloseAt=os.epoch("utc")+MANUAL_HOLD_OPEN*1000
  clearSince=nil
  setFlash("OTWARTA // 10 SEK",1.5)
  beep(18,"bell")
  return true
end

local function countdown()
  if not manualCloseAt then return nil end
  return math.max(0,math.ceil((manualCloseAt-os.epoch("utc"))/1000))
end

local function drawOne(entry,players)
  local m=entry.p
  local ok,W,H=pcall(m.getSize)
  if not ok then return end
  local function fill(x,y,w,bg)
    if y<1 or y>H or x>W then return end
    x=math.max(1,x); w=math.max(0,math.min(w,W-x+1)); if w<1 then return end
    m.setCursorPos(x,y); m.setBackgroundColor(bg); m.write(string.rep(" ",w))
  end
  local function put(x,y,t,fg,bg)
    if y<1 or y>H then return end
    x=math.max(1,math.floor(x)); if x>W then return end
    m.setCursorPos(x,y); m.setTextColor(fg or colors.white); m.setBackgroundColor(bg or colors.black)
    m.write(tostring(t):sub(1,W-x+1))
  end
  local function center(y,t,fg,bg)
    t=tostring(t); put(math.max(1,math.floor((W-#t)/2)+1),y,t,fg,bg)
  end

  m.setBackgroundColor(colors.black); m.clear()
  fill(1,1,W,colors.orange)
  center(1," AFTERFALL // BRAMA G-01 ",colors.black,colors.orange)

  local diag=(detector and "DET:OK" or "DET:BRAK").."  "..(gearshift and "GEAR:OK" or "GEAR:BRAK")
  center(2,diag,(detector and gearshift) and colors.lime or colors.yellow)

  if flashMessage and os.epoch("utc")<flashUntil then
    center(4,flashMessage,colors.yellow)
  else
    center(4,"STAN: "..(gateState=="open" and "OTWARTA" or "ZAMKNIETA"),gateState=="open" and colors.lime or colors.red)
  end
  center(5,"STREFA: "..players,colors.lightGray)

  local top=math.max(7,math.floor(H*0.28))
  local bottom=math.max(top+5,H-5)
  local bg=gearshift and (gateState=="closed" and colors.green or colors.orange) or colors.gray
  for y=top,bottom do fill(2,y,math.max(1,W-2),bg) end
  local cy=math.floor((top+bottom)/2)

  if not gearshift then
    center(cy-1,"STEROWANIE OFFLINE",colors.white,bg)
    center(cy+1,"BRAK GEARSHIFT",colors.white,bg)
  elseif gateState=="closed" then
    center(cy-1,"DOTKNIJ EKRAN",colors.black,bg)
    center(cy+1,"OTWORZ BRAME",colors.black,bg)
  else
    center(cy-1,"BRAMA OTWARTA",colors.black,bg)
    local sec=countdown()
    if sec then center(cy+1,"ZAMKNIECIE: "..sec.." s",colors.black,bg)
    elseif players>0 then center(cy+1,"GRACZ W STREFIE",colors.black,bg)
    else center(cy+1,"AUTO AKTYWNE",colors.black,bg) end
  end

  if lastMoveError then center(H-3,"ERR: "..lastMoveError:sub(1,math.max(1,W-6)),colors.red) end
  fill(1,H-2,W,colors.gray)
  center(H-2," OBA EKRANY AKTYWNE ",colors.black,colors.gray)
  center(H,"UWAGA // RUCH BRAMY",colors.orange)
end

local function drawAll(players)
  for _,entry in ipairs(monitors) do pcall(drawOne,entry,players) end
end

local function redrawTerminal(players)
  term.clear();term.setCursorPos(1,1)
  term.setTextColor(colors.orange); print("AFTERFALL // BRAMA G-01 v1.3")
  term.setTextColor(colors.white)
  print("MONITORY: "..#monitors)
  for i,e in ipairs(monitors) do print("  "..i..": "..e.name) end
  print("DETECTOR: "..(detectorName or "BRAK"))
  print("GEARSHIFT: "..(gearshiftName or "BRAK"))
  print("STAN SW: "..string.upper(gateState))
  print("GRACZE: "..players)
  if lastMoveError then term.setTextColor(colors.red);print("BLAD: "..lastMoveError);term.setTextColor(colors.white) end
  print("")
  term.setTextColor(colors.lightGray)
  print("DOTYK dowolnego monitora = OTWORZ / reset 10 s")
  print("O = FORCE OPEN | C = CLOSE | R = reverse | Q = stop")
  term.setTextColor(colors.white)
end

discover()
redrawTerminal(#getPlayers())
drawAll(#getPlayers())
beep(12)
local timer=os.startTimer(POLL)

while true do
  local e={os.pullEvent()}
  if e[1]=="timer" and e[2]==timer then
    discover()
    local count=#getPlayers()
    local now=os.epoch("utc")

    if gearshift then
      if manualCloseAt then
        if now>=manualCloseAt then
          if count==0 then moveGate("closed",false) else manualCloseAt=nil;clearSince=nil end
        end
      elseif detector and count>0 then
        clearSince=nil
        if gateState=="closed" then moveGate("open",false) end
      elseif detector then
        if not clearSince then clearSince=now end
        if gateState=="open" and now-clearSince>=AUTO_HOLD_OPEN*1000 then
          if #getPlayers()==0 then moveGate("closed",false) else clearSince=nil end
        end
      end
    end

    redrawTerminal(count)
    drawAll(count)
    timer=os.startTimer(POLL)

  elseif e[1]=="monitor_touch" then
    local count=#getPlayers()
    if gateState=="closed" then manualOpen()
    elseif gearshift then
      manualCloseAt=os.epoch("utc")+MANUAL_HOLD_OPEN*1000
      setFlash("LICZNIK = 10 SEK",1)
      beep(14,"hat")
    end
    redrawTerminal(count);drawAll(count)

  elseif e[1]=="key" then
    if e[2]==keys.o then
      manualOpen()
    elseif e[2]==keys.c then
      manualCloseAt=nil;moveGate("closed",true)
    elseif e[2]==keys.r then
      reverse=not reverse;writeFile(CONFIG_FILE,reverse and "1" or "0")
      setFlash("REVERSE: "..tostring(reverse),2);beep(10)
    elseif e[2]==keys.q then
      for _,entry in ipairs(monitors) do pcall(entry.p.clear) end
      term.clear();term.setCursorPos(1,1);print("BRAMA G-01 // OFFLINE")
      return
    end
    local count=#getPlayers();redrawTerminal(count);drawAll(count)

  elseif e[1]=="peripheral" or e[1]=="peripheral_detach" or e[1]=="monitor_resize" then
    discover();local count=#getPlayers();redrawTerminal(count);drawAll(count)
  end
end
