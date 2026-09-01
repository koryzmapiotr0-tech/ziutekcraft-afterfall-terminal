-- ZiutekCraft Afterfall // Brama glownego wjazdu v1.1
-- CC:Tweaked + Advanced Peripherals Player Detector + Create Sequenced Gearshift
-- Monitor 2x2: reczne otwarcie dotykiem + automatyczne zamkniecie po 10 s.

local DETECT_RANGE = 18
local TRAVEL = 7
local AUTO_HOLD_OPEN = 4       -- auto: zamknij 4 s po odejsciu ostatniego gracza
local MANUAL_HOLD_OPEN = 10    -- reczne otwarcie: minimum 10 s
local OPEN_MOD = -2
local CLOSE_MOD = 2
local POLL = 0.20
local MONITOR_SCALE = 0.5

local STATE_FILE = "/afterfall_gate_state.txt"
local CONFIG_FILE = "/afterfall_gate_reverse.txt"

local detector
local gearshift
local speaker
local monitor
local W,H = 0,0

local gateState = "closed"
local reverse = false
local clearSince = nil
local manualCloseAt = nil
local lastPlayers = -1
local lastSecond = -1

local function methods(name)
  local ok, list = pcall(peripheral.getMethods, name)
  return ok and list or {}
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

local function findMonitor()
  local best, area = nil, -1
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" then
      local p = peripheral.wrap(name)
      if p and p.getSize and p.setTextScale then
        pcall(p.setTextScale, MONITOR_SCALE)
        local ok,w,h = pcall(p.getSize)
        if ok and w and h and w*h > area then
          best,area = p,w*h
        end
      end
    end
  end
  return best
end

local function connect()
  detector = peripheral.find("player_detector") or peripheral.find("playerDetector")
  gearshift = select(1, findGearshift())
  speaker = peripheral.find("speaker")
  monitor = findMonitor()
  if monitor then
    pcall(monitor.setTextScale, MONITOR_SCALE)
    pcall(monitor.setCursorBlink, false)
    pcall(monitor.setBackgroundColor, colors.black)
    pcall(monitor.clear)
    W,H = monitor.getSize()
  end
  return detector ~= nil and gearshift ~= nil
end

local function loadFile(path)
  if not fs.exists(path) then return nil end
  local h = fs.open(path, "r")
  if not h then return nil end
  local v = h.readAll()
  h.close()
  return v
end

local function saveFile(path, value)
  local h = fs.open(path, "w")
  if h then h.write(tostring(value)); h.close() end
end

local remembered = loadFile(STATE_FILE)
if remembered == "open" or remembered == "closed" then gateState = remembered end
reverse = loadFile(CONFIG_FILE) == "1"

local function beep(note, instrument)
  if speaker then pcall(speaker.playNote, instrument or "bit", 0.7, note or 12) end
end

local function getPlayers()
  if not detector then return {} end
  local ok, list = pcall(detector.getPlayersInRange, DETECT_RANGE)
  if ok and type(list) == "table" then return list end
  return {}
end

local function waitForGearshift()
  while true do
    local ok, running = pcall(gearshift.isRunning)
    if not ok or running ~= true then break end
    sleep(0.05)
  end
end

local function direction(target)
  local open = OPEN_MOD
  local close = CLOSE_MOD
  if reverse then open, close = close, open end
  return target == "open" and open or close
end

local function moveGate(target)
  if gateState == target then return true end
  if not gearshift then return false, "Brak Sequenced Gearshift" end

  local okRunning, running = pcall(gearshift.isRunning)
  if okRunning and running then waitForGearshift() end

  term.setTextColor(colors.orange)
  print("[BRAMA] " .. (target == "open" and "OTWIERANIE" or "ZAMYKANIE") .. "...")

  local ok, err = pcall(gearshift.move, TRAVEL, direction(target))
  if not ok then
    term.setTextColor(colors.red)
    print("[BRAMA] BLAD: " .. tostring(err))
    term.setTextColor(colors.white)
    return false, err
  end

  waitForGearshift()
  gateState = target
  saveFile(STATE_FILE, gateState)

  if target == "closed" then
    manualCloseAt = nil
    clearSince = nil
  end

  beep(target == "open" and 16 or 8)
  term.setTextColor(target == "open" and colors.lime or colors.cyan)
  print("[BRAMA] " .. string.upper(target))
  term.setTextColor(colors.white)
  return true
end

local function manualOpen()
  if gateState == "closed" then moveGate("open") end
  manualCloseAt = os.epoch("utc") + MANUAL_HOLD_OPEN * 1000
  clearSince = nil
  beep(18, "bell")
end

local function mFill(x,y,w,bg)
  if not monitor or y < 1 or y > H or x > W then return end
  x = math.max(1,x)
  w = math.max(0,math.min(w,W-x+1))
  if w <= 0 then return end
  monitor.setCursorPos(x,y)
  monitor.setBackgroundColor(bg)
  monitor.write(string.rep(" ",w))
end

local function mPut(x,y,text,fg,bg)
  if not monitor or y < 1 or y > H then return end
  x = math.max(1,math.floor(x))
  if x > W then return end
  monitor.setCursorPos(x,y)
  monitor.setTextColor(fg or colors.white)
  monitor.setBackgroundColor(bg or colors.black)
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

local function drawMonitor(playerCount)
  if not monitor then return end

  monitor.setBackgroundColor(colors.black)
  monitor.clear()

  mFill(1,1,W,colors.orange)
  mCenter(1," AFTERFALL // BRAMA G-01 ",colors.black,colors.orange)

  local stateColor = gateState == "open" and colors.lime or colors.red
  mCenter(3,"STAN: " .. (gateState == "open" and "OTWARTA" or "ZAMKNIETA"),stateColor)
  mCenter(4,"STREFA: " .. tostring(playerCount) .. " graczy",colors.lightGray)

  local btnTop = math.max(6, math.floor(H*0.32))
  local btnBottom = math.max(btnTop+4, H-7)
  local btnColor = gateState == "open" and colors.gray or colors.green

  for y=btnTop,btnBottom do mFill(3,y,math.max(1,W-4),btnColor) end
  if gateState == "closed" then
    mCenter(math.floor((btnTop+btnBottom)/2)-1,"DOTKNIJ ABY",colors.black,btnColor)
    mCenter(math.floor((btnTop+btnBottom)/2)+1,"OTWORZ BRAME",colors.black,btnColor)
  else
    local sec = countdownSeconds()
    if sec ~= nil then
      mCenter(math.floor((btnTop+btnBottom)/2)-1,"BRAMA OTWARTA",colors.white,btnColor)
      mCenter(math.floor((btnTop+btnBottom)/2)+1,"AUTO CLOSE: "..sec.." s",colors.yellow,btnColor)
    elseif playerCount > 0 then
      mCenter(math.floor((btnTop+btnBottom)/2)-1,"BRAMA OTWARTA",colors.white,btnColor)
      mCenter(math.floor((btnTop+btnBottom)/2)+1,"GRACZ W STREFIE",colors.yellow,btnColor)
    else
      mCenter(math.floor((btnTop+btnBottom)/2),"BRAMA OTWARTA",colors.white,btnColor)
    end
  end

  mFill(1,H-2,W,colors.gray)
  mCenter(H-2," AUTOMATYKA + PLAYER DETECTOR ",colors.black,colors.gray)
  mCenter(H,"UWAGA // STREFA RUCHU BRAMY",colors.orange)
end

local function redrawTerminal(players)
  term.clear()
  term.setCursorPos(1,1)
  term.setTextColor(colors.orange)
  print("AFTERFALL // BRAMA GLOWNA G-01")
  term.setTextColor(colors.white)
  print("AUTO: AKTYWNE")
  print("STAN: " .. string.upper(gateState))
  print("GRACZE W STREFIE: " .. tostring(players))
  local sec=countdownSeconds()
  if sec then print("RECZNE AUTO-CLOSE: "..sec.." s") end
  print("")
  term.setTextColor(colors.lightGray)
  print("MONITOR 2x2: dotknij aby otworzyc")
  print("O = otworz | C = zamknij")
  print("R = odwroc kierunek")
  print("Q = zatrzymaj program")
  term.setTextColor(reverse and colors.yellow or colors.gray)
  print("REVERSE: " .. tostring(reverse))
  term.setTextColor(colors.white)
end

while not connect() do
  term.clear(); term.setCursorPos(1,1)
  term.setTextColor(colors.red)
  print("AFTERFALL // BRAMA G-01")
  print("Brak wymaganych peryferiow.")
  term.setTextColor(colors.white)
  print("Potrzebne:")
  print("- Player Detector")
  print("- Sequenced Gearshift")
  print("Monitor 2x2 jest opcjonalny dla sterowania dotykiem.")
  sleep(1)
end

beep(12)
local timer = os.startTimer(POLL)
redrawTerminal(0)
drawMonitor(0)

while true do
  local e = {os.pullEvent()}

  if e[1] == "timer" and e[2] == timer then
    detector = detector or peripheral.find("player_detector") or peripheral.find("playerDetector")
    if not gearshift then gearshift = select(1, findGearshift()) end
    speaker = speaker or peripheral.find("speaker")
    if not monitor then monitor=findMonitor(); if monitor then monitor.setTextScale(MONITOR_SCALE); W,H=monitor.getSize() end end

    local players = getPlayers()
    local count = #players
    local now = os.epoch("utc")

    if manualCloseAt then
      -- Reczne otwarcie: odliczamy 10 s. Jesli ktos jest w strefie w chwili
      -- zamkniecia, nie ryzykujemy przyciecia gracza i czekamy az odejdzie.
      if now >= manualCloseAt then
        if count == 0 then
          moveGate("closed")
          manualCloseAt = nil
        else
          manualCloseAt = nil
          clearSince = nil
        end
      end
    elseif count > 0 then
      clearSince = nil
      if gateState == "closed" then moveGate("open") end
    else
      if not clearSince then clearSince = now end
      if gateState == "open" and (now-clearSince) >= AUTO_HOLD_OPEN*1000 then
        local again=getPlayers()
        if #again==0 then moveGate("closed") else clearSince=nil end
      end
    end

    local sec=countdownSeconds() or -1
    if count ~= lastPlayers or sec ~= lastSecond then
      redrawTerminal(count)
      drawMonitor(count)
      lastPlayers=count
      lastSecond=sec
    end

    timer=os.startTimer(POLL)

  elseif e[1] == "monitor_touch" then
    -- caly duzy zielony panel jest przyciskiem OTWORZ.
    if gateState == "closed" then
      manualOpen()
    elseif gateState == "open" then
      -- ponowne dotkniecie odswieza licznik do pelnych 10 sekund.
      manualCloseAt = os.epoch("utc") + MANUAL_HOLD_OPEN*1000
      beep(14,"hat")
    end
    local count=#getPlayers()
    redrawTerminal(count)
    drawMonitor(count)

  elseif e[1] == "key" then
    if e[2] == keys.o then
      manualOpen()
      redrawTerminal(#getPlayers()); drawMonitor(#getPlayers())
    elseif e[2] == keys.c then
      manualCloseAt=nil
      moveGate("closed")
      redrawTerminal(#getPlayers()); drawMonitor(#getPlayers())
    elseif e[2] == keys.r then
      reverse=not reverse
      saveFile(CONFIG_FILE,reverse and "1" or "0")
      beep(10)
      redrawTerminal(#getPlayers()); drawMonitor(#getPlayers())
    elseif e[2] == keys.q then
      if monitor then
        monitor.setBackgroundColor(colors.black);monitor.clear();mCenter(math.floor(H/2),"BRAMA G-01 // OFFLINE",colors.red)
      end
      term.clear();term.setCursorPos(1,1);term.setTextColor(colors.red)
      print("BRAMA G-01 // AUTOMATYKA OFFLINE")
      term.setTextColor(colors.white)
      return
    end

  elseif e[1] == "peripheral" or e[1] == "peripheral_detach" or e[1] == "monitor_resize" then
    detector,gearshift,speaker,monitor=nil,nil,nil,nil
    connect()
    local count=#getPlayers()
    redrawTerminal(count);drawMonitor(count)
  end
end
