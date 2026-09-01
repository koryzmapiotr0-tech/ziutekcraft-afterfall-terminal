-- ZiutekCraft Afterfall Terminal
-- CC:Tweaked spawn terminal for a 5x3 monitor wall

local monitor = peripheral.find("monitor")

if not monitor then
  term.setTextColor(colors.red)
  print("[AFTERFALL] Nie znaleziono monitora.")
  print("Podlacz monitor do komputera i uruchom ponownie.")
  return
end

monitor.setTextScale(0.5)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)
monitor.clear()
monitor.setCursorBlink(false)

local W, H = monitor.getSize()

local function clearLine(y, bg)
  monitor.setBackgroundColor(bg or colors.black)
  monitor.setCursorPos(1, y)
  monitor.write(string.rep(" ", W))
end

local function writeAt(x, y, text, fg, bg)
  if y < 1 or y > H then return end
  x = math.max(1, math.floor(x))
  monitor.setBackgroundColor(bg or colors.black)
  monitor.setTextColor(fg or colors.white)
  monitor.setCursorPos(x, y)
  monitor.write(tostring(text):sub(1, math.max(0, W - x + 1)))
end

local function center(y, text, fg, bg)
  local x = math.floor((W - #text) / 2) + 1
  writeAt(x, y, text, fg, bg)
end

local function line(y, ch, fg)
  writeAt(1, y, string.rep(ch or "-", W), fg or colors.gray)
end

local function getPlayerCount()
  local detector = peripheral.find("playerDetector")
  if detector and detector.getOnlinePlayers then
    local ok, players = pcall(detector.getOnlinePlayers)
    if ok and type(players) == "table" then
      return #players
    end
  end

  if fs.exists("/.afterfall_players") then
    local h = fs.open("/.afterfall_players", "r")
    if h then
      local n = tonumber(h.readAll())
      h.close()
      if n then return math.max(0, math.floor(n)) end
    end
  end

  return nil
end

local tips = {
  "FTB Quests prowadzi przez odzyskiwanie technologii.",
  "Najpierw zabezpiecz baze. Ruiny nie zawsze sa puste.",
  "Create i Mekanism to rdzen odbudowy infrastruktury.",
  "Energia i surowce sa wazniejsze niz szybki progres.",
  "Plecak i waypoint potrafia uratowac ekspedycje.",
  "Czytaj opisy zadan - czesc z nich zawiera fragmenty fabuly.",
  "Automatyzacja zmniejsza ryzyko wypraw po podstawowe zasoby.",
  "Nie wszystko, co znajdziesz pod ziemia, nalezy budzic."
}

local commands = {
  "/ftbquests  - dziennik misji",
  "/sethome    - ustaw punkt powrotu",
  "/home       - powrot do bazy",
  "/spawn      - powrot do bunkra"
}

local bootFrames = {
  "URUCHAMIANIE SIECI AWARYJNEJ...",
  "ODZYSKIWANIE ARCHIWOW...",
  "SYNCHRONIZACJA TERMINALA...",
  "KANAL CYWILNY: ONLINE"
}

local function boot()
  monitor.clear()
  center(math.max(2, math.floor(H / 2) - 3), "ZIUTEKCRAFT // AFTERFALL", colors.orange)
  for i, text in ipairs(bootFrames) do
    clearLine(math.floor(H / 2) - 1 + i)
    center(math.floor(H / 2) - 1 + i, text, i == #bootFrames and colors.lime or colors.lightGray)
    sleep(0.35)
  end
  sleep(0.6)
end

local tipIndex = 1

local function draw()
  monitor.setBackgroundColor(colors.black)
  monitor.clear()

  writeAt(1, 1, string.rep(" ", W), colors.white, colors.gray)
  center(1, " ZIUTEKCRAFT // AFTERFALL ", colors.black, colors.orange)

  center(3, "TERMINAL OCALALYCH", colors.orange)
  center(4, "SEKTOR SPAWN // KANAL PUBLICZNY", colors.gray)
  line(5, "=", colors.gray)

  local count = getPlayerCount()
  writeAt(3, 7, "STATUS SIECI", colors.lightGray)
  writeAt(18, 7, "ONLINE", colors.lime)
  writeAt(3, 8, "OCALALI", colors.lightGray)
  writeAt(18, 8, count and tostring(count) or "BRAK DANYCH", count and colors.cyan or colors.gray)
  writeAt(3, 9, "PROTOKOL", colors.lightGray)
  writeAt(18, 9, "AFTERFALL-01", colors.yellow)

  local rightX = math.floor(W / 2) + 2
  writeAt(rightX, 7, "PRIORYTET", colors.lightGray)
  writeAt(rightX + 12, 7, "PRZETRWAJ", colors.red)
  writeAt(rightX, 8, "STREFA", colors.lightGray)
  writeAt(rightX + 12, 8, "BUNKIER", colors.orange)
  writeAt(rightX, 9, "ARCHIWA", colors.lightGray)
  writeAt(rightX + 12, 9, "CZESCIOWE", colors.yellow)

  line(11, "-", colors.gray)
  writeAt(3, 12, "DOSTEPNE KOMENDY", colors.orange)
  for i, cmd in ipairs(commands) do
    if 12 + i <= H - 7 then
      writeAt(4, 12 + i, cmd, colors.lightGray)
    end
  end

  local tipY = math.max(18, H - 5)
  line(tipY - 1, "-", colors.gray)
  writeAt(3, tipY, "KOMUNIKAT ARCHIWUM:", colors.orange)
  clearLine(tipY + 1)
  center(tipY + 1, tips[tipIndex], colors.white)

  writeAt(2, H, "AFTERFALL TERMINAL v1.0", colors.gray)
  local clock = textutils.formatTime(os.time(), true)
  writeAt(W - #clock - 1, H, clock, colors.gray)
end

boot()
while true do
  draw()
  for _ = 1, 10 do sleep(1) end
  tipIndex = tipIndex % #tips + 1
end
