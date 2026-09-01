-- ZiutekCraft Afterfall // Command Center v1.0
-- Second 5x3 spawn display for CC:Tweaked + Advanced Peripherals
-- Live players/world data, radio feed, alerts, events and touch navigation.

local monitor = peripheral.find("monitor")
if not monitor then
  term.setTextColor(colors.red)
  print("[AFTERFALL] Nie znaleziono monitora.")
  print("Podlacz Advanced Monitor i uruchom ponownie.")
  return
end

monitor.setTextScale(0.5)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)
monitor.clear()
monitor.setCursorBlink(false)

local W, H = monitor.getSize()
local currentPage = "dashboard"
local buttons = {}
local refreshTimer
local radioIndex = 1
local bootTime = os.epoch("utc")

local radioFeed = {
  {time="ARCH-001", level="INFO", title="KANAL CYWILNY", text="Siec bunkra pozostaje aktywna. Ocalali powinni kontynuowac odbudowe infrastruktury."},
  {time="ARCH-002", level="UWAGA", title="SEKTOR ZEWN", text="Ekspedycje poza strefe spawn powinny zabrac zapas zywnosci, oswietlenie i droge powrotna."},
  {time="ARCH-003", level="INFO", title="ODZYSKIWANIE", text="Dostep do kolejnych technologii jest przywracany etapami przez system questow."},
  {time="ARCH-004", level="UWAGA", title="NIEZNANY SYGNAL", text="Archiwa zawieraja wzmianki o systemach, ktore mogly przetrwac katastrofe w trybie autonomicznym."}
}

local alertHistory = {
  "SYSTEM // Centrum dowodzenia uruchomione.",
  "SYSTEM // Kanal radiowy gotowy.",
  "SYSTEM // Oczekiwanie na dane z czujnikow."
}

local activeEvent = {
  title = "BRAK AKTYWNEGO EVENTU",
  text = "Centrala nie zarejestrowala obecnie zadnego wydarzenia globalnego.",
  source = "SYSTEM"
}

local manualAlert = nil

local function safeCall(obj, method, ...)
  if not obj or type(obj[method]) ~= "function" then return nil end
  local result = table.pack(pcall(obj[method], ...))
  if not result[1] then return nil end
  return table.unpack(result, 2, result.n)
end

local function findPlayerDetector()
  return peripheral.find("player_detector") or peripheral.find("playerDetector")
end

local function findEnvironmentDetector()
  return peripheral.find("environment_detector") or peripheral.find("environmentDetector")
end

local function writeAt(x, y, text, fg, bg)
  if y < 1 or y > H then return end
  x = math.max(1, math.floor(x))
  if x > W then return end
  monitor.setBackgroundColor(bg or colors.black)
  monitor.setTextColor(fg or colors.white)
  monitor.setCursorPos(x, y)
  monitor.write(tostring(text):sub(1, W - x + 1))
end

local function fill(x, y, width, bg)
  if y < 1 or y > H or width <= 0 then return end
  x = math.max(1, x)
  if x > W then return end
  width = math.min(width, W - x + 1)
  monitor.setBackgroundColor(bg or colors.black)
  monitor.setCursorPos(x, y)
  monitor.write(string.rep(" ", width))
end

local function line(y, x1, x2, ch, fg)
  x1 = x1 or 1
  x2 = x2 or W
  writeAt(x1, y, string.rep(ch or "-", math.max(0, x2 - x1 + 1)), fg or colors.gray)
end

local function center(y, text, fg, bg, x1, x2)
  x1 = x1 or 1
  x2 = x2 or W
  local width = x2 - x1 + 1
  local x = x1 + math.floor((width - #tostring(text)) / 2)
  writeAt(x, y, text, fg, bg)
end

local function wrap(text, width)
  local out, current = {}, ""
  for word in tostring(text or ""):gmatch("%S+") do
    if current == "" then
      current = word
    elseif #current + #word + 1 <= width then
      current = current .. " " .. word
    else
      out[#out + 1] = current
      current = word
    end
  end
  if current ~= "" then out[#out + 1] = current end
  if #out == 0 then out[1] = "" end
  return out
end

local function textBlock(x, y, width, text, fg, maxY)
  maxY = maxY or H - 2
  for _, value in ipairs(wrap(text, width)) do
    if y > maxY then break end
    writeAt(x, y, value, fg or colors.lightGray)
    y = y + 1
  end
  return y
end

local function addButton(x, y, width, label, id, active)
  width = math.max(width, #label + 2)
  width = math.min(width, W - x + 1)
  local bg = active and colors.orange or colors.gray
  local fg = active and colors.black or colors.white
  fill(x, y, width, bg)
  center(y, label, fg, bg, x, x + width - 1)
  buttons[#buttons + 1] = {x1=x, x2=x+width-1, y1=y, y2=y, id=id}
end

local function shortName(value)
  local s = tostring(value or "N/A")
  return s:match("^[^:]+:(.+)$") or s
end

local function getPlayers()
  local detector = findPlayerDetector()
  if detector then
    local players = safeCall(detector, "getOnlinePlayers")
    if type(players) == "table" then
      table.sort(players)
      return #players, players, "PLAYER DETECTOR"
    end
  end

  if commands and type(commands.exec) == "function" then
    local ok, output = commands.exec("list")
    if ok and type(output) == "table" and output[1] then
      local first = tostring(output[1])
      local count = tonumber(first:match("There are (%d+)") or first:match("(%d+) of a max"))
      if count then return count, {}, "COMMAND COMPUTER" end
    end
  end

  return nil, {}, "BRAK CZUJNIKA"
end

local function getWorld()
  local env = findEnvironmentDetector()
  local data = {
    sensor = env ~= nil,
    biome = "N/A",
    dimension = "N/A",
    weather = "N/A",
    time = "N/A",
    moon = "N/A",
    daylight = "N/A",
    blocklight = "N/A",
    radiationRaw = nil,
    radiation = "N/A"
  }

  if not env then return data end

  data.biome = shortName(safeCall(env, "getBiome"))
  data.dimension = shortName(safeCall(env, "getDimension"))

  local thunder = safeCall(env, "isThunder")
  local raining = safeCall(env, "isRaining")
  local sunny = safeCall(env, "isSunny")
  if thunder == true then data.weather = "BURZA"
  elseif raining == true then data.weather = "DESZCZ"
  elseif sunny == true then data.weather = "CZYSTO"
  else data.weather = "POCHMURNO" end

  local worldTime = safeCall(env, "getTime")
  if type(worldTime) == "number" then
    local hours = math.floor((worldTime / 1000 + 6) % 24)
    local mins = math.floor(((worldTime % 1000) / 1000) * 60)
    data.time = string.format("%02d:%02d", hours, mins)
  end

  local moon = safeCall(env, "getMoonName")
  if moon then data.moon = tostring(moon) end

  local daylight = safeCall(env, "getDayLightLevel")
  if daylight ~= nil then data.daylight = tostring(daylight) .. "/15" end

  local blocklight = safeCall(env, "getBlockLightLevel")
  if blocklight ~= nil then data.blocklight = tostring(blocklight) .. "/15" end

  local radiation = safeCall(env, "getRadiation")
  if type(radiation) == "table" and radiation.radiation then
    data.radiation = tostring(radiation.radiation) .. (radiation.unit and (" " .. tostring(radiation.unit)) or "")
  end

  local raw = safeCall(env, "getRadiationRaw")
  if type(raw) == "number" then
    data.radiationRaw = raw
    if data.radiation == "N/A" then data.radiation = string.format("%.3g Sv/h", raw) end
  end

  return data
end

local function readOptionalFiles()
  if fs.exists("/afterfall_event.txt") then
    local h = fs.open("/afterfall_event.txt", "r")
    if h then
      local title = h.readLine() or "EVENT"
      local body = h.readAll() or ""
      h.close()
      if body ~= "" then
        activeEvent = {title=title, text=body:gsub("[\r\n]+", " "), source="PLIK LOKALNY"}
      end
    end
  end

  if fs.exists("/afterfall_alert.txt") then
    local h = fs.open("/afterfall_alert.txt", "r")
    if h then
      local v = (h.readAll() or ""):upper():gsub("%s+", "")
      h.close()
      if v == "NORMALNY" or v == "UWAGA" or v == "ALARM" or v == "KRYTYCZNY" then
        manualAlert = v
      end
    end
  end
end

local function getAlert(world)
  if manualAlert then return manualAlert end
  if world.weather == "BURZA" then return "UWAGA" end
  return "NORMALNY"
end

local function alertColor(level)
  if level == "KRYTYCZNY" then return colors.red
  elseif level == "ALARM" then return colors.red
  elseif level == "UWAGA" then return colors.yellow
  else return colors.lime end
end

local function addRadioMessage(level, title, text, source)
  local stamp = textutils.formatTime(os.time(), true)
  table.insert(radioFeed, 1, {
    time = stamp,
    level = tostring(level or "INFO"):upper(),
    title = tostring(title or source or "RADIO"),
    text = tostring(text or "")
  })
  while #radioFeed > 20 do table.remove(radioFeed) end
  radioIndex = 1
end

local function addAlert(text)
  table.insert(alertHistory, 1, tostring(text))
  while #alertHistory > 12 do table.remove(alertHistory) end
end

local function openRednet()
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "modem" and not rednet.isOpen(name) then
      pcall(rednet.open, name)
    end
  end
end

local function handleNetwork(sender, message, protocol)
  if protocol == "afterfall.radio" then
    if type(message) == "table" then
      addRadioMessage(message.level or "INFO", message.title or ("RADIO #" .. sender), message.text or message.message or "", "REDNET")
    else
      addRadioMessage("INFO", "RADIO #" .. sender, tostring(message), "REDNET")
    end
    addAlert("RADIO // Odebrano nowy komunikat.")

  elseif protocol == "afterfall.event" then
    if type(message) == "table" then
      activeEvent = {
        title = tostring(message.title or "AKTYWNY EVENT"),
        text = tostring(message.text or message.message or "Brak opisu."),
        source = "REDNET #" .. sender
      }
    else
      activeEvent = {title="AKTYWNY EVENT", text=tostring(message), source="REDNET #" .. sender}
    end
    addAlert("EVENT // Zarejestrowano wydarzenie globalne.")

  elseif protocol == "afterfall.alert" then
    local value
    if type(message) == "table" then value = message.level else value = message end
    value = tostring(value or ""):upper()
    if value == "NORMALNY" or value == "UWAGA" or value == "ALARM" or value == "KRYTYCZNY" then
      manualAlert = value
      addAlert("ALERT // Poziom zmieniony na " .. value .. ".")
    elseif value == "AUTO" then
      manualAlert = nil
      addAlert("ALERT // Przywrocono tryb automatyczny.")
    end
  end
end

local menu = {
  {"dashboard", "CENTRALA"},
  {"players", "OCALALI"},
  {"world", "SWIAT"},
  {"radio", "RADIO"},
  {"alerts", "ALERTY"},
  {"events", "EVENTY"}
}

local function drawHeader(world)
  fill(1, 1, W, colors.orange)
  center(1, " AFTERFALL // COMMAND CENTER // SEKTOR SPAWN-01 ", colors.black, colors.orange)

  local level = getAlert(world)
  writeAt(2, 2, "SIEC: ONLINE", colors.lime)
  local alertText = "STATUS: " .. level
  writeAt(math.max(2, W - #alertText - 1), 2, alertText, alertColor(level))
  line(3, 1, W, "=", colors.gray)
end

local function drawMenu()
  local menuWidth = math.min(18, math.max(14, math.floor(W * 0.2)))
  writeAt(2, 5, "MODULY", colors.orange)
  local y = 7
  for _, item in ipairs(menu) do
    addButton(2, y, menuWidth - 2, item[2], "page:" .. item[1], currentPage == item[1])
    y = y + 2
  end
  return menuWidth + 2
end

local function title(x, text, subtitle)
  writeAt(x, 5, text, colors.orange)
  if subtitle then writeAt(x, 6, subtitle, colors.gray) end
  line(7, x, W - 2, "-", colors.gray)
end

local function keyValue(x, y, key, value, color)
  writeAt(x, y, key, colors.lightGray)
  writeAt(x + 18, y, tostring(value), color or colors.white)
end

local function pageDashboard(x, world)
  title(x, "CENTRUM DOWODZENIA", "Biezacy obraz sytuacji operacyjnej")
  local count, names, source = getPlayers()
  local level = getAlert(world)
  local col2 = math.min(W - 25, x + math.max(29, math.floor((W - x) / 2)))

  writeAt(x, 9, "SEKTOR", colors.orange)
  keyValue(x, 10, "STATUS", level, alertColor(level))
  keyValue(x, 11, "OCALALI ONLINE", count or "N/A", count and colors.cyan or colors.yellow)
  keyValue(x, 12, "ODCZYT", source, colors.gray)
  keyValue(x, 13, "WYMIAR", world.dimension)
  keyValue(x, 14, "BIOM", world.biome)

  writeAt(col2, 9, "SRODOWISKO", colors.orange)
  keyValue(col2, 10, "POGODA", world.weather, world.weather == "BURZA" and colors.red or colors.white)
  keyValue(col2, 11, "CZAS", world.time)
  keyValue(col2, 12, "SWIATLO", world.daylight)
  keyValue(col2, 13, "PROMIENIOWANIE", world.radiation, colors.yellow)
  keyValue(col2, 14, "CZUJNIK", world.sensor and "ONLINE" or "N/A", world.sensor and colors.lime or colors.yellow)

  local y = 17
  line(y, x, W - 2, "-", colors.gray)
  y = y + 2
  writeAt(x, y, "OSTATNI KOMUNIKAT RADIOWY", colors.orange)
  y = y + 1
  local msg = radioFeed[1]
  writeAt(x, y, "[" .. msg.time .. "] " .. msg.level .. " // " .. msg.title, msg.level == "UWAGA" and colors.yellow or colors.cyan)
  y = textBlock(x, y + 1, W - x - 3, msg.text, colors.white, H - 6)

  local eventY = math.max(y + 1, H - 5)
  line(eventY - 1, x, W - 2, "-", colors.gray)
  writeAt(x, eventY, "EVENT: " .. activeEvent.title, activeEvent.title == "BRAK AKTYWNEGO EVENTU" and colors.gray or colors.orange)
  textBlock(x, eventY + 1, W - x - 3, activeEvent.text, colors.lightGray, H - 2)
end

local function pagePlayers(x)
  title(x, "OCALALI // REJESTR", "Lista graczy wykrytych przez siec")
  local count, names, source = getPlayers()
  keyValue(x, 9, "LICZBA", count or "N/A", count and colors.cyan or colors.yellow)
  keyValue(x, 10, "ZRODLO", source, colors.gray)
  line(12, x, W - 2, "-", colors.gray)

  if count == nil then
    writeAt(x, 14, "BRAK DANYCH Z PLAYER DETECTORA", colors.yellow)
    textBlock(x, 16, W - x - 3, "Podlacz Player Detector bezposrednio lub przez przewodowa siec modemow. Dla Minecraft 1.21.1 program szuka peryferium player_detector.", colors.lightGray)
    return
  end

  if count == 0 then
    writeAt(x, 14, "Brak ocalalych online.", colors.gray)
    return
  end

  local y = 14
  for i, name in ipairs(names) do
    local marker = string.format("%02d", i)
    writeAt(x, y, "[" .. marker .. "]", colors.orange)
    writeAt(x + 6, y, tostring(name), colors.white)
    y = y + 2
    if y > H - 2 then break end
  end
end

local function pageWorld(x, world)
  title(x, "SENSORIUM // SWIAT", "Telemetria Environment Detectora")
  keyValue(x, 9, "ENV DETECTOR", world.sensor and "ONLINE" or "NIE PODLACZONY", world.sensor and colors.lime or colors.red)
  keyValue(x, 11, "WYMIAR", world.dimension)
  keyValue(x, 12, "BIOM", world.biome)
  keyValue(x, 13, "POGODA", world.weather, world.weather == "BURZA" and colors.red or colors.white)
  keyValue(x, 14, "CZAS SWIATA", world.time)
  keyValue(x, 15, "FAZA KSIEZYCA", world.moon)
  keyValue(x, 16, "SWIATLO DNIA", world.daylight)
  keyValue(x, 17, "SWIATLO BLOKU", world.blocklight)
  keyValue(x, 18, "PROMIENIOWANIE", world.radiation, colors.yellow)

  if not world.sensor then
    line(20, x, W - 2, "-", colors.gray)
    textBlock(x, 22, W - x - 3, "Podlacz Environment Detector do tej samej sieci peryferiow. Wtedy centrala bedzie aktualizowac biom, wymiar, pogode, czas, swiatlo i promieniowanie Mekanismu.", colors.yellow)
  end
end

local function pageRadio(x)
  title(x, "RADIO // KANAL PUBLICZNY", "Archiwum i komunikaty odbierane przez Rednet")
  if #radioFeed == 0 then return end
  if radioIndex > #radioFeed then radioIndex = #radioFeed end
  local msg = radioFeed[radioIndex]

  writeAt(x, 9, "PAKIET " .. radioIndex .. " / " .. #radioFeed, colors.gray)
  writeAt(x, 11, "[" .. msg.time .. "] " .. msg.level, msg.level == "UWAGA" and colors.yellow or colors.cyan)
  writeAt(x, 13, msg.title, colors.orange)
  textBlock(x, 15, W - x - 3, msg.text, colors.white, H - 8)

  local by = H - 5
  addButton(x, by, 13, "< STARSZY", "radio:older", false)
  addButton(x + 15, by, 13, "NOWSZY >", "radio:newer", false)
  addButton(x + 30, by, 14, "NAJNOWSZY", "radio:latest", false)
end

local function pageAlerts(x, world)
  title(x, "ALERTY // BEZPIECZENSTWO", "Poziom alarmowy i dziennik zdarzen")
  local level = getAlert(world)
  fill(x, 9, math.min(28, W - x - 2), alertColor(level))
  writeAt(x + 1, 9, "POZIOM: " .. level, colors.black, alertColor(level))

  local mode = manualAlert and "STEROWANIE ZEWN." or "AUTOMATYCZNY"
  keyValue(x, 11, "TRYB", mode, manualAlert and colors.yellow or colors.lime)
  keyValue(x, 12, "POGODA", world.weather)
  keyValue(x, 13, "PROMIENIOWANIE", world.radiation, colors.yellow)
  line(15, x, W - 2, "-", colors.gray)
  writeAt(x, 16, "DZIENNIK", colors.orange)

  local y = 18
  for i = 1, math.min(#alertHistory, H - y - 1) do
    writeAt(x, y, "- " .. alertHistory[i], colors.lightGray)
    y = y + 1
  end
end

local function pageEvents(x)
  title(x, "EVENTY // OPERACJE", "Aktualne wydarzenie globalne")
  writeAt(x, 9, activeEvent.title, activeEvent.title == "BRAK AKTYWNEGO EVENTU" and colors.gray or colors.orange)
  writeAt(x, 11, "ZRODLO: " .. activeEvent.source, colors.gray)
  line(13, x, W - 2, "-", colors.gray)
  textBlock(x, 15, W - x - 3, activeEvent.text, colors.white, H - 8)

  local y = H - 6
  line(y - 1, x, W - 2, "-", colors.gray)
  writeAt(x, y, "INTEGRACJA", colors.orange)
  writeAt(x, y + 1, "Rednet protocol: afterfall.event", colors.cyan)
  writeAt(x, y + 2, "Plik lokalny: /afterfall_event.txt", colors.lightGray)
end

local function drawFooter()
  line(H - 1, 1, W, "-", colors.gray)
  writeAt(2, H, "COMMAND CENTER v1.0", colors.gray)
  local clock = textutils.formatTime(os.time(), true)
  local right = "REDNET: " .. (rednet.isOpen() and "ONLINE" or "OFFLINE") .. "  " .. clock
  writeAt(math.max(2, W - #right - 1), H, right, rednet.isOpen() and colors.lime or colors.gray)
end

local function draw()
  W, H = monitor.getSize()
  buttons = {}
  readOptionalFiles()
  local world = getWorld()

  monitor.setBackgroundColor(colors.black)
  monitor.clear()
  drawHeader(world)
  local x = drawMenu()

  if currentPage == "dashboard" then pageDashboard(x, world)
  elseif currentPage == "players" then pagePlayers(x)
  elseif currentPage == "world" then pageWorld(x, world)
  elseif currentPage == "radio" then pageRadio(x)
  elseif currentPage == "alerts" then pageAlerts(x, world)
  elseif currentPage == "events" then pageEvents(x)
  else currentPage = "dashboard"; pageDashboard(x, world) end

  drawFooter()
end

local function boot()
  monitor.setBackgroundColor(colors.black)
  monitor.clear()
  center(math.floor(H / 2) - 4, "AFTERFALL // COMMAND CENTER", colors.orange)
  center(math.floor(H / 2) - 2, "URUCHAMIANIE CENTRALI...", colors.lightGray)
  sleep(0.25)
  openRednet()
  center(math.floor(H / 2) - 1, "KANAL REDNET: " .. (rednet.isOpen() and "ONLINE" or "OFFLINE"), rednet.isOpen() and colors.lime or colors.yellow)
  sleep(0.25)
  center(math.floor(H / 2), "PLAYER DETECTOR: " .. (findPlayerDetector() and "ONLINE" or "N/A"), findPlayerDetector() and colors.lime or colors.yellow)
  sleep(0.25)
  center(math.floor(H / 2) + 1, "ENV DETECTOR: " .. (findEnvironmentDetector() and "ONLINE" or "N/A"), findEnvironmentDetector() and colors.lime or colors.yellow)
  sleep(0.25)
  center(math.floor(H / 2) + 3, "SEKTOR SPAWN-01 // GOTOWY", colors.orange)
  sleep(0.7)
end

local function handleButton(id)
  local page = id:match("^page:(.+)$")
  if page then
    currentPage = page
    draw()
    return
  end

  if id == "radio:older" then
    radioIndex = math.min(#radioFeed, radioIndex + 1)
  elseif id == "radio:newer" then
    radioIndex = math.max(1, radioIndex - 1)
  elseif id == "radio:latest" then
    radioIndex = 1
  end
  draw()
end

local function handleTouch(x, y)
  for i = #buttons, 1, -1 do
    local b = buttons[i]
    if x >= b.x1 and x <= b.x2 and y >= b.y1 and y <= b.y2 then
      handleButton(b.id)
      return
    end
  end
end

boot()
draw()
refreshTimer = os.startTimer(4)

while true do
  local event, a, b, c = os.pullEvent()

  if event == "monitor_touch" then
    handleTouch(b, c)

  elseif event == "timer" and a == refreshTimer then
    draw()
    refreshTimer = os.startTimer(4)

  elseif event == "rednet_message" then
    handleNetwork(a, b, c)
    draw()

  elseif event == "playerJoin" then
    addAlert("OCALALY // " .. tostring(a) .. " dolaczyl do sieci.")
    draw()

  elseif event == "playerLeave" then
    addAlert("OCALALY // " .. tostring(a) .. " opuscil siec.")
    draw()

  elseif event == "monitor_resize" or event == "peripheral" or event == "peripheral_detach" then
    openRednet()
    draw()
  end
end
