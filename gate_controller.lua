-- ZiutekCraft Afterfall // Brama glownego wjazdu v1.0
-- CC:Tweaked + Advanced Peripherals Player Detector + Create Sequenced Gearshift
-- Otwor bramy: 9 szer. x 7 wys. x 9 gleb.

local DETECT_RANGE = 18       -- Player Detector jest wysoko nad brama
local TRAVEL = 7              -- brama jedzie dokladnie 7 blokow
local HOLD_OPEN = 4           -- sekundy od odejscia ostatniego gracza
local OPEN_MOD = -2           -- jesli kierunek jest odwrotny: nacisnij R
local CLOSE_MOD = 2
local POLL = 0.25

local STATE_FILE = "/afterfall_gate_state.txt"
local CONFIG_FILE = "/afterfall_gate_reverse.txt"

local detector
local gearshift
local speaker
local gateState = "closed"
local reverse = false
local clearSince = nil
local lastPlayers = -1

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

local function connect()
  detector = peripheral.find("player_detector") or peripheral.find("playerDetector")
  gearshift = select(1, findGearshift())
  speaker = peripheral.find("speaker")
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

local function beep(note)
  if speaker then pcall(speaker.playNote, "bit", 0.7, note or 12) end
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
  beep(target == "open" and 16 or 8)
  term.setTextColor(target == "open" and colors.lime or colors.cyan)
  print("[BRAMA] " .. string.upper(target))
  term.setTextColor(colors.white)
  return true
end

local function redraw(players)
  term.clear()
  term.setCursorPos(1,1)
  term.setTextColor(colors.orange)
  print("AFTERFALL // BRAMA GLOWNA G-01")
  term.setTextColor(colors.white)
  print("AUTO: AKTYWNE")
  print("STAN: " .. string.upper(gateState))
  print("GRACZE W STREFIE: " .. tostring(players))
  print("ZASIEG: " .. DETECT_RANGE .. " blokow")
  print("RUCH: " .. TRAVEL .. " blokow")
  print("")
  term.setTextColor(colors.lightGray)
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
  print("Potrzebne obok komputera:")
  print("- Player Detector")
  print("- Sequenced Gearshift")
  sleep(1)
end

beep(12)
local timer = os.startTimer(POLL)
redraw(0)

while true do
  local e = {os.pullEvent()}

  if e[1] == "timer" and e[2] == timer then
    detector = detector or peripheral.find("player_detector") or peripheral.find("playerDetector")
    if not gearshift then gearshift = select(1, findGearshift()) end
    speaker = speaker or peripheral.find("speaker")

    local players = getPlayers()
    local count = #players

    if count > 0 then
      clearSince = nil
      if gateState == "closed" then moveGate("open") end
    else
      if not clearSince then clearSince = os.epoch("utc") end
      if gateState == "open" and (os.epoch("utc") - clearSince) >= HOLD_OPEN * 1000 then
        -- ostatnia kontrola bezpieczenstwa tuz przed zamknieciem
        local again = getPlayers()
        if #again == 0 then moveGate("closed") else clearSince = nil end
      end
    end

    if count ~= lastPlayers then redraw(count); lastPlayers = count end
    timer = os.startTimer(POLL)

  elseif e[1] == "key" then
    if e[2] == keys.o then moveGate("open"); redraw(#getPlayers())
    elseif e[2] == keys.c then moveGate("closed"); redraw(#getPlayers())
    elseif e[2] == keys.r then
      reverse = not reverse
      saveFile(CONFIG_FILE, reverse and "1" or "0")
      beep(10)
      redraw(#getPlayers())
    elseif e[2] == keys.q then
      term.clear(); term.setCursorPos(1,1)
      term.setTextColor(colors.red)
      print("BRAMA G-01 // AUTOMATYKA OFFLINE")
      term.setTextColor(colors.white)
      return
    end

  elseif e[1] == "peripheral" or e[1] == "peripheral_detach" then
    detector, gearshift, speaker = nil, nil, nil
    connect()
    redraw(#getPlayers())
  end
end
