-- ZiutekCraft Afterfall // Brama glownego wjazdu v1.2
-- CC:Tweaked + Advanced Peripherals Player Detector + Create Sequenced Gearshift
-- FIX: monitor dziala nawet gdy brakuje detectora/gearshiftu + diagnostyka na ekranie.
-- Monitor 2x2: dotykowe OTWORZ + auto-zamkniecie po 10 s.

local DETECT_RANGE = 18
local TRAVEL = 7
local AUTO_HOLD_OPEN = 4
local MANUAL_HOLD_OPEN = 10
local OPEN_MOD = -2
local CLOSE_MOD = 2
local POLL = 0.20
local MONITOR_SCALE = 0.5

local STATE_FILE = "/afterfall_gate_state.txt"
local CONFIG_FILE = "/afterfall_gate_reverse.txt"

local detector, detectorName
local gearshift, gearshiftName
local speaker
local monitor, monitorName
local W,H = 0,0

local gateState = "closed"
local reverse = false
local clearSince = nil
local manualCloseAt = nil
local lastPlayers = -1
local lastSecond = -1
local lastDiag = ""
local flashMessage = nil
local flashUntil = 0

local function methods(name)
  local ok, list = pcall(peripheral.getMethods, name)
  return ok and type(list)=="table" and list or {}
end

local function hasMethod(name, wanted)
  for _, m in ipairs(methods(name)) do
    if m == wanted then return true end
  end
  return false
end

local function findGearshift()
  for _, name in ipairs(peripheral.getNames()) do
    if hasMethod(name, "move") and hasMethod(name, "isRunning") then
      return peripheral.wrap(name), name
    end
  end
  return nil, nil
end

local function findDetector()
  local p = peripheral.find("player_detector") or peripheral.find("playerDetector")
  if p then
    for _,name in ipairs(peripheral.getNames()) do
      local wrapped=peripheral.wrap(name)
      if wrapped==p then return p,name end
    end
    return p,"player_detector"
  end
  -- fallback po metodzie, gdy typ peryferium ma inna nazwe
  for _,name in ipairs(peripheral.getNames()) do
    if hasMethod(name,"getPlayersInRange") then return peripheral.wrap(name),name end
  end
  return nil,nil
end

local function findMonitor()
  local best,bestName,area=nil,nil,-1
  for _,name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name)=="monitor" then
      local p=peripheral.wrap(name)
      if p and p.getSize and p.setTextScale then
        pcall(p.setTextScale,MONITOR_SCALE)
        local ok,w,h=pcall(p.getSize)
        if ok and w and h and w*h>area then
          best,bestName,area=p,name,w*h
        end
      end
    end
  end
  return best,bestName
end

local function discover()
  detector,detectorName=findDetector()
  gearshift,gearshiftName=findGearshift()
  speaker=peripheral.find("speaker")
  local m,mn=findMonitor()
  if m then
    monitor,monitorName=m,mn
    pcall(monitor.setTextScale,MONITOR_SCALE)
    pcall(monitor.setCursorBlink,false)
    pcall(monitor.setBackgroundColor,colors.black)
    local ok,w,h=pcall(monitor.getSize)
    if ok then W,H=w,h end
  else
    monitor,monitorName=nil,nil
    W,H=0,0
  end
end

local function loadFile(path)
  if not fs.exists(path) then return nil end
  local h=fs.open(path,"r")
  if not h then return nil end
  local v=h.readAll();h.close();return v
end

local function saveFile(path,value)
  local h=fs.open(path,"w")
  if h then h.write(tostring(value));h.close() end
end

local remembered=loadFile(STATE_FILE)
if remembered=="open" or remembered=="closed" then gateState=remembered end
reverse=loadFile(CONFIG_FILE)=="1"

local function beep(note,instrument)
  if speaker then pcall(speaker.playNote,instrument or "bit",0.7,note or 12) end
end

local function getPlayers()
  if not detector then return {} end
  local ok,list=pcall(detector.getPlayersInRange,DETECT_RANGE)
  if ok and type(list)=="table" then return list end
  return {}
end

local function waitForGearshift()
  if not gearshift then return end
  while true do
    local ok,running=pcall(gearshift.isRunning)
    if not ok or running~=true then break end
    sleep(0.05)
  end
end

local function direction(target)
  local o,c=OPEN_MOD,CLOSE_MOD
  if reverse then o,c=c,o end
  return target=="open" and o or c
end

local function setFlash(msg,seconds)
  flashMessage=tostring(msg)
  flashUntil=os.epoch("utc")+(seconds or 2)*1000
end

local function moveGate(target)
  if gateState==target then return true end
  if not gearshift then
    setFlash("BLAD: BRAK GEARSHIFT",3)
    beep(3,"bass")
    return false,"Brak Sequenced Gearshift"
  end

  local okRunning,running=pcall(gearshift.isRunning)
  if okRunning and running then waitForGearshift() end

  local ok,err=pcall(gearshift.move,TRAVEL,direction(target))
  if not ok then
    setFlash("BLAD RUCHU BRAMY",3)
    return false,err
  end

  waitForGearshift()
  gateState=target
  saveFile(STATE_FILE,gateState)
  if target=="closed" then manualCloseAt=nil;clearSince=nil end
  beep(target=="open" and 16 or 8)
  return true
end

local function manualOpen()
  if not gearshift then
    setFlash("BRAK GEARSHIFT",3)
    return false
  end
  if gateState=="closed" then
    local ok=moveGate("open")
    if not ok then return false end
  end
  manualCloseAt=os.epoch("utc")+MANUAL_HOLD_OPEN*1000
  clearSince=nil
  setFlash("OTWARTA // 10 SEK",1.5)
  beep(18,"bell")
  return true
end

local function mFill(x,y,w,bg)
  if not monitor or y<1 or y>H or x>W then return end
  x=math.max(1,x);w=math.max(0,math.min(w,W-x+1))
  if w<=0 then return end
  monitor.setCursorPos(x,y);monitor.setBackgroundColor(bg);monitor.write(string.rep(" ",w))
end

local function mPut(x,y,text,fg,bg)
  if not monitor or y<1 or y>H then return end
  x=math.max(1,math.floor(x));if x>W then return end
  monitor.setCursorPos(x,y);monitor.setTextColor(fg or colors.white);monitor.setBackgroundColor(bg or colors.black)
  monitor.write(tostring(text):sub(1,W-x+1))
end

local function mCenter(y,text,fg,bg)
  text=tostring(text)
  mPut(math.max(1,math.floor((W-#text)/2)+1),y,text,fg,bg)
end

local function countdownSeconds()
  if not manualCloseAt then return nil end
  return math.max(0,math.ceil((manualCloseAt-os.epoch("utc"))/1000))
end

local function diagText()
  local d=detector and "DET:OK" or "DET:BRAK"
  local g=gearshift and "GEAR:OK" or "GEAR:BRAK"
  return d.."  "..g
end

local function drawMonitor(playerCount)
  if not monitor then return end
  monitor.setBackgroundColor(colors.black);monitor.clear()

  mFill(1,1,W,colors.orange)
  mCenter(1," AFTERFALL // BRAMA G-01 ",colors.black,colors.orange)

  -- zawsze widoczna diagnostyka, nawet gdy mechanizm nie jest podpiety
  local diag=diagText()
  mCenter(2,diag,(detector and gearshift) and colors.lime or colors.yellow)

  if flashMessage and os.epoch("utc")<flashUntil then
    mCenter(4,flashMessage,colors.red)
  else
    local stateColor=gateState=="open" and colors.lime or colors.red
    mCenter(4,"STAN: "..(gateState=="open" and "OTWARTA" or "ZAMKNIETA"),stateColor)
  end

  mCenter(5,"STREFA: "..tostring(playerCount),colors.lightGray)

  local btnTop=math.max(7,math.floor(H*0.30))
  local btnBottom=math.max(btnTop+4,H-5)
  local usable=gearshift~=nil
  local btnColor
  if not usable then btnColor=colors.gray
  elseif gateState=="closed" then btnColor=colors.green
  else btnColor=colors.orange end

  for y=btnTop,btnBottom do mFill(2,y,math.max(1,W-2),btnColor) end
  local cy=math.floor((btnTop+btnBottom)/2)

  if not gearshift then
    mCenter(cy-1,"STEROWANIE OFFLINE",colors.white,btnColor)
    mCenter(cy+1,"BRAK SEQUENCED GEARSHIFT",colors.white,btnColor)
  elseif gateState=="closed" then
    mCenter(cy-1,"DOTKNIJ EKRAN",colors.black,btnColor)
    mCenter(cy+1,"OTWORZ BRAME",colors.black,btnColor)
  else
    local sec=countdownSeconds()
    mCenter(cy-1,"BRAMA OTWARTA",colors.black,btnColor)
    if sec then
      mCenter(cy+1,"ZAMKNIECIE: "..sec.." s",colors.black,btnColor)
    elseif playerCount>0 then
      mCenter(cy+1,"GRACZ W STREFIE",colors.black,btnColor)
    else
      mCenter(cy+1,"AUTO AKTYWNE",colors.black,btnColor)
    end
  end

  mFill(1,H-2,W,colors.gray)
  if detector then
    mCenter(H-2," PLAYER DETECTOR // AUTO ",colors.black,colors.gray)
  else
    mCenter(H-2," MANUAL ONLY // BRAK DETECTORA ",colors.black,colors.gray)
  end
  mCenter(H,"UWAGA // STREFA RUCHU BRAMY",colors.orange)
end

local function redrawTerminal(players)
  term.clear();term.setCursorPos(1,1)
  term.setTextColor(colors.orange);print("AFTERFALL // BRAMA GLOWNA G-01 v1.2")
  term.setTextColor(colors.white)
  print("MONITOR: "..(monitorName or "BRAK"))
  print("PLAYER DETECTOR: "..(detectorName or "BRAK"))
  print("GEARSHIFT: "..(gearshiftName or "BRAK"))
  print("STAN: "..string.upper(gateState))
  print("GRACZE: "..tostring(players))
  local sec=countdownSeconds();if sec then print("AUTO-CLOSE: "..sec.." s") end
  print("")
  term.setTextColor(colors.lightGray)
  print("Monitor 2x2: dotknij aby otworzyc")
  print("O = otworz | C = zamknij | R = reverse | Q = stop")
  term.setTextColor(colors.white)
end

-- WAŻNE: nie czekamy juz na komplet peryferiow.
-- Program startuje zawsze, a brakujace elementy pokazuje jako diagnostyke.
discover()
beep(12)
redrawTerminal(#getPlayers())
drawMonitor(#getPlayers())
local timer=os.startTimer(POLL)

while true do
  local e={os.pullEvent()}

  if e[1]=="timer" and e[2]==timer then
    discover()
    local players=getPlayers();local count=#players;local now=os.epoch("utc")

    if gearshift then
      if manualCloseAt then
        if now>=manualCloseAt then
          if count==0 then
            moveGate("closed")
            manualCloseAt=nil
          else
            -- nie zamykaj na graczu; od tej chwili czekamy na opuszczenie strefy
            manualCloseAt=nil
            clearSince=nil
          end
        end
      elseif detector and count>0 then
        clearSince=nil
        if gateState=="closed" then moveGate("open") end
      elseif detector then
        if not clearSince then clearSince=now end
        if gateState=="open" and (now-clearSince)>=AUTO_HOLD_OPEN*1000 then
          local again=getPlayers()
          if #again==0 then moveGate("closed") else clearSince=nil end
        end
      end
    end

    local sec=countdownSeconds() or -1
    local diag=diagText()
    if count~=lastPlayers or sec~=lastSecond or diag~=lastDiag or (flashMessage and now<flashUntil) then
      redrawTerminal(count);drawMonitor(count)
      lastPlayers=count;lastSecond=sec;lastDiag=diag
    end

    timer=os.startTimer(POLL)

  elseif e[1]=="monitor_touch" then
    -- reaguj tylko na monitor wybrany przez program
    if not monitorName or e[2]==monitorName then
      if gateState=="closed" then
        manualOpen()
      elseif gateState=="open" and gearshift then
        manualCloseAt=os.epoch("utc")+MANUAL_HOLD_OPEN*1000
        setFlash("LICZNIK = 10 SEK",1)
        beep(14,"hat")
      end
      local count=#getPlayers();redrawTerminal(count);drawMonitor(count)
    end

  elseif e[1]=="key" then
    if e[2]==keys.o then
      manualOpen();redrawTerminal(#getPlayers());drawMonitor(#getPlayers())
    elseif e[2]==keys.c then
      manualCloseAt=nil;moveGate("closed");redrawTerminal(#getPlayers());drawMonitor(#getPlayers())
    elseif e[2]==keys.r then
      reverse=not reverse;saveFile(CONFIG_FILE,reverse and "1" or "0");beep(10)
      setFlash("REVERSE: "..tostring(reverse),2);redrawTerminal(#getPlayers());drawMonitor(#getPlayers())
    elseif e[2]==keys.q then
      if monitor then monitor.setBackgroundColor(colors.black);monitor.clear();mCenter(math.floor(H/2),"BRAMA G-01 // OFFLINE",colors.red) end
      term.clear();term.setCursorPos(1,1);term.setTextColor(colors.red);print("BRAMA G-01 // OFFLINE");return
    end

  elseif e[1]=="peripheral" or e[1]=="peripheral_detach" or e[1]=="monitor_resize" then
    discover();local count=#getPlayers();redrawTerminal(count);drawMonitor(count)
  end
end
