-- ZiutekCraft Afterfall Terminal v2.0
-- Public spawn kiosk for a 5x3 Advanced Monitor wall
-- Minecraft 1.21.1 / CC:Tweaked / Advanced Peripherals compatible

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
local currentPage = "start"
local buttons = {}
local archiveIndex = 1
local refreshTimer = nil

-- 1.21.1 uses snake_case names. Old names are kept as fallback.
local function findPlayerDetector()
  return peripheral.find("player_detector") or peripheral.find("playerDetector")
end

local function findEnvironmentDetector()
  return peripheral.find("environment_detector") or peripheral.find("environmentDetector")
end

local function safeCall(obj, method, ...)
  if not obj then return nil end
  local fn = obj[method]
  if type(fn) ~= "function" then return nil end
  local result = table.pack(pcall(fn, ...))
  if not result[1] then return nil end
  return table.unpack(result, 2, result.n)
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
  width = math.min(width, W - x + 1)
  monitor.setBackgroundColor(bg or colors.black)
  monitor.setCursorPos(x, y)
  monitor.write(string.rep(" ", width))
end

local function center(y, text, fg, bg, x1, x2)
  x1 = x1 or 1
  x2 = x2 or W
  local width = x2 - x1 + 1
  local x = x1 + math.floor((width - #text) / 2)
  writeAt(x, y, text, fg, bg)
end

local function line(y, x1, x2, ch, fg)
  x1 = x1 or 1
  x2 = x2 or W
  writeAt(x1, y, string.rep(ch or "-", math.max(0, x2 - x1 + 1)), fg or colors.gray)
end

local function trimNamespace(value)
  if value == nil then return "N/A" end
  local s = tostring(value)
  local short = s:match("^[^:]+:(.+)$")
  return short or s
end

local function wrap(text, width)
  local out = {}
  text = tostring(text or "")
  if text == "" then return {""} end

  local lineText = ""
  for word in text:gmatch("%S+") do
    if #lineText == 0 then
      lineText = word
    elseif #lineText + 1 + #word <= width then
      lineText = lineText .. " " .. word
    else
      out[#out + 1] = lineText
      lineText = word
    end
  end
  if #lineText > 0 then out[#out + 1] = lineText end
  return out
end

local function textBlock(x, y, width, text, fg, maxY)
  maxY = maxY or H - 2
  local lines = wrap(text, width)
  for _, value in ipairs(lines) do
    if y > maxY then break end
    writeAt(x, y, value, fg or colors.lightGray)
    y = y + 1
  end
  return y
end

local function addButton(x, y, width, label, id, active, fg)
  if y < 1 or y > H then return end
  width = math.max(width, #label + 2)
  width = math.min(width, W - x + 1)
  local bg = active and colors.orange or colors.gray
  local textColor = active and colors.black or (fg or colors.white)
  fill(x, y, width, bg)
  local shown = " " .. label .. " "
  if #shown > width then shown = shown:sub(1, width) end
  local tx = x + math.max(0, math.floor((width - #shown) / 2))
  writeAt(tx, y, shown, textColor, bg)
  buttons[#buttons + 1] = {x1=x, x2=x + width - 1, y1=y, y2=y, id=id}
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

  -- Fallback for Command Computer.
  if commands and type(commands.exec) == "function" then
    local ok, output = commands.exec("list")
    if ok and type(output) == "table" and output[1] then
      local first = tostring(output[1])
      local count = tonumber(first:match("There are (%d+)") or first:match("Jest (%d+)") or first:match("(%d+) of a max"))
      local after = first:match(":%s*(.*)$")
      local names = {}
      if after and after ~= "" then
        for name in after:gmatch("[^,%s]+") do names[#names + 1] = name end
      end
      if count then return count, names, "COMMAND COMPUTER" end
    end
  end

  return nil, {}, "BRAK CZUJNIKA"
end

local function getWorldData()
  local env = findEnvironmentDetector()
  local data = {
    connected = env ~= nil,
    biome = "N/A",
    dimension = "N/A",
    weather = "N/A",
    time = "N/A",
    moon = "N/A",
    daylight = "N/A",
    radiation = "N/A",
    dimensions = "N/A"
  }

  if not env then return data end

  data.biome = trimNamespace(safeCall(env, "getBiome"))
  data.dimension = trimNamespace(safeCall(env, "getDimension"))

  local raining = safeCall(env, "isRaining")
  local thunder = safeCall(env, "isThunder")
  local sunny = safeCall(env, "isSunny")
  if thunder == true then
    data.weather = "BURZA"
  elseif raining == true then
    data.weather = "DESZCZ"
  elseif sunny == true then
    data.weather = "CZYSTO"
  end

  local worldTime = safeCall(env, "getTime")
  if type(worldTime) == "number" then
    local hours = math.floor((worldTime / 1000 + 6) % 24)
    local mins = math.floor(((worldTime % 1000) / 1000) * 60)
    data.time = string.format("%02d:%02d", hours, mins)
  end

  local moonId, moonName = safeCall(env, "getMoon")
  if moonName then data.moon = tostring(moonName) elseif moonId then data.moon = tostring(moonId) end

  local light = safeCall(env, "getDayLightLevel")
  if light ~= nil then data.daylight = tostring(light) .. "/15" end

  local radiation = safeCall(env, "getRadiation")
  if type(radiation) == "table" then
    local r = radiation.radiation or radiation.value
    local unit = radiation.unit or ""
    if r then data.radiation = tostring(r) .. (unit ~= "" and (" " .. unit) or "") end
  else
    local raw = safeCall(env, "getRadiationRaw")
    if type(raw) == "number" then data.radiation = string.format("%.3g Sv/h", raw) end
  end

  local dims = safeCall(env, "listDimensions")
  if type(dims) == "table" then data.dimensions = tostring(#dims) end

  return data
end

local archive = {
  {
    title = "ARCHIWUM 01 // PRZEBUDZENIE",
    text = "System bunkra odzyskal zasilanie. Siec zewnetrzna milczy. Pierwszym zadaniem ocalalych jest zabezpieczenie schronienia, zywnosci i stalego zrodla energii."
  },
  {
    title = "ARCHIWUM 02 // UTRACONA WIEDZA",
    text = "Wiekszosc technologii przetrwala tylko we fragmentach dokumentacji. Odtwarzaj kolejne galezie przez questy. Kazda odblokowana technologia przywraca czesc dawnego swiata."
  },
  {
    title = "ARCHIWUM 03 // STREFA ZEWNETRZNA",
    text = "Ruiny i jaskinie zawieraja zasoby, artefakty oraz zagrozenia. Ekspedycja bez zapasu jedzenia, swiatla i drogi powrotnej moze zakonczyc sie utrata calego wyposazenia."
  },
  {
    title = "ARCHIWUM 04 // ODBUDOWA",
    text = "Create uruchamia pierwsze linie produkcyjne. Mekanism przywraca przemysl i przetwarzanie. Energia staje sie podstawa dalszej ekspansji ocalalych."
  },
  {
    title = "ARCHIWUM 05 // OSTRZEZENIE",
    text = "Nie wszystkie systemy sprzed katastrofy sa martwe. Czesc struktur nadal wykonuje swoje stare rozkazy. Nie zakladaj, ze opuszczony obiekt jest bezpieczny."
  }
}

local menu = {
  {"start", "START"},
  {"begin", "JAK ZACZAC"},
  {"story", "HISTORIA"},
  {"quests", "QUESTY"},
  {"economy", "EKONOMIA"},
  {"tech", "TECHNOLOGIA"},
  {"world", "STATUS SWIATA"},
  {"help", "POMOC"},
  {"archive", "ARCHIWUM"}
}

local function drawHeader()
  fill(1, 1, W, colors.orange)
  center(1, " ZIUTEKCRAFT // AFTERFALL // TERMINAL OCALALYCH ", colors.black, colors.orange)

  local count, _, source = getPlayers()
  local status = "SIEC: ONLINE"
  local players = count and ("OCALALI: " .. count) or "OCALALI: N/A"
  local right = players .. "   " .. source
  writeAt(2, 2, status, colors.lime)
  writeAt(math.max(2, W - #right - 1), 2, right, count and colors.cyan or colors.yellow)
  line(3, 1, W, "=", colors.gray)
end

local function drawMenu()
  local menuWidth = math.min(19, math.max(15, math.floor(W * 0.22)))
  writeAt(2, 5, "MENU TERMINALA", colors.orange)
  local y = 7
  for _, item in ipairs(menu) do
    addButton(2, y, menuWidth - 2, item[2], "page:" .. item[1], currentPage == item[1])
    y = y + 2
  end
  return menuWidth + 2
end

local function title(contentX, text, subtitle)
  writeAt(contentX, 5, text, colors.orange)
  if subtitle then writeAt(contentX, 6, subtitle, colors.gray) end
  line(7, contentX, W - 2, "-", colors.gray)
end

local function keyValue(x, y, key, value, valueColor)
  writeAt(x, y, key, colors.lightGray)
  writeAt(x + 17, y, tostring(value), valueColor or colors.white)
end

local function pageStart(x)
  title(x, "CENTRUM INFORMACYJNE", "Dotknij przycisku po lewej stronie, aby otworzyc modul.")

  local count, names, source = getPlayers()
  local world = getWorldData()
  local col2 = math.min(W - 20, x + math.max(28, math.floor((W - x) / 2)))

  writeAt(x, 9, "STATUS OCALALYCH", colors.orange)
  keyValue(x, 10, "ONLINE", count or "N/A", count and colors.cyan or colors.yellow)
  keyValue(x, 11, "ZRODLO", source, colors.gray)

  if count and count > 0 then
    local list = table.concat(names, ", ")
    if list == "" then list = "Dane nazw niedostepne" end
    writeAt(x, 13, "AKTYWNI:", colors.lightGray)
    textBlock(x, 14, math.max(18, col2 - x - 3), list, colors.white, 17)
  else
    writeAt(x, 13, "Brak odczytu graczy.", colors.yellow)
    writeAt(x, 14, "Podlacz Player Detector do sieci.", colors.gray)
  end

  writeAt(col2, 9, "STATUS STREFY", colors.orange)
  keyValue(col2, 10, "WYMIAR", world.dimension, colors.white)
  keyValue(col2, 11, "BIOM", world.biome, colors.white)
  keyValue(col2, 12, "POGODA", world.weather, world.weather == "BURZA" and colors.red or colors.white)
  keyValue(col2, 13, "CZAS", world.time, colors.white)
  keyValue(col2, 14, "PROMIENIOWANIE", world.radiation, colors.yellow)

  local y = math.max(19, H - 7)
  line(y - 1, x, W - 2, "-", colors.gray)
  writeAt(x, y, "PRIORYTET OPERACYJNY", colors.orange)
  writeAt(x, y + 1, "1. Otworz QUESTY i sprawdz pierwszy etap odbudowy.", colors.white)
  writeAt(x, y + 2, "2. Zabezpiecz baze i przygotuj punkt powrotu.", colors.lightGray)
  writeAt(x, y + 3, "3. Rozwijaj technologie etapami zamiast omijac progresje.", colors.lightGray)
end

local function pageBegin(x)
  title(x, "JAK ZACZAC", "Procedura dla nowego ocalalego")
  local steps = {
    {"01", "OTWORZ QUESTY", "FTB Quests jest glowna sciezka progresji i prowadzi przez kolejne technologie."},
    {"02", "ZABEZPIECZ SCHRONIENIE", "Ustaw punkt powrotu, zbierz jedzenie, swiatlo i podstawowe narzedzia."},
    {"03", "URUCHOM PRODUKCJE", "Create pozwala zbudowac pierwsza sensowna automatyzacje i infrastrukture."},
    {"04", "ODZYSKAJ ENERGIE", "Przejdz do stabilnej produkcji energii i dopiero potem rozwijaj ciezszy przemysl."},
    {"05", "EKSPLORUJ", "Ruiny, jaskinie i inne wymiary sa czescia progresji. Przygotuj droge powrotna."},
    {"06", "CZYTAJ ARCHIWA", "Questy i terminal zawieraja elementy fabuly wyjasniajace swiat Afterfall."}
  }
  local y = 9
  for _, step in ipairs(steps) do
    writeAt(x, y, "[" .. step[1] .. "] " .. step[2], colors.orange)
    y = textBlock(x + 2, y + 1, W - x - 4, step[3], colors.lightGray, H - 2) + 1
    if y > H - 3 then break end
  end
end

local function pageStory(x)
  title(x, "HISTORIA AFTERFALL", "Fragment publicznego archiwum")
  local y = 9
  y = textBlock(x, y, W - x - 3, "Dawny swiat nie upadl w jednej chwili. Sieci energetyczne, przemysl i systemy automatyczne znikaly sektor po sektorze, az pozostaly tylko odizolowane bunkry i fragmenty infrastruktury.", colors.lightGray) + 1
  y = textBlock(x, y, W - x - 3, "Ocalali nie zaczynaja od zera. Zaczynaja od szczatkow wiedzy. Schematy, maszyny i archiwa istnieja, ale trzeba je ponownie zrozumiec i uruchomic.", colors.lightGray) + 1
  y = textBlock(x, y, W - x - 3, "Twoim celem nie jest tylko przezyc. Masz odbudowac lancuch technologiczny: od prostych mechanizmow, przez przemysl, az po technologie zdolne ponownie polaczyc rozbite sektory swiata.", colors.white) + 2
  writeAt(x, y, "ARCHIWUM OSTRZEGA:", colors.red)
  textBlock(x, y + 1, W - x - 3, "Nie kazda maszyna, ktora przetrwala katastrofe, stoi po stronie ocalalych.", colors.yellow)
end

local function pageQuests(x)
  title(x, "QUESTY // PROGRESJA", "Glowny przewodnik po odbudowie")
  local entries = {
    {"ETAP 1", "Przetrwanie, narzedzia, schronienie i podstawowe zasoby."},
    {"ETAP 2", "Create: mechanizacja, transport i pierwsza automatyzacja."},
    {"ETAP 3", "Energia: stabilne zasilanie dla kolejnych systemow."},
    {"ETAP 4", "Mekanism i przemysl: wydajniejsze przetwarzanie surowcow."},
    {"ETAP 5", "Eksploracja, inne wymiary, rzadkie materialy i artefakty."},
    {"ETAP 6", "Zaawansowane technologie i odbudowa infrastruktury Afterfall."}
  }
  local y = 9
  for _, e in ipairs(entries) do
    writeAt(x, y, e[1], colors.orange)
    y = textBlock(x + 10, y, W - x - 12, e[2], colors.lightGray, H - 3) + 2
    if y > H - 4 then break end
  end
  if y <= H - 2 then writeAt(x, y, "Komenda: /ftbquests", colors.cyan) end
end

local function pageEconomy(x)
  title(x, "EKONOMIA OCALALYCH", "Zasoby maja wartosc, bo odbudowa kosztuje")
  local y = 9
  local blocks = {
    {"HANDEL", "Sprzedawaj nadwyzki i kupuj to, czego nie warto produkowac recznie."},
    {"SPECJALIZACJA", "Automatyzacja daje przewage. Fabryka jednego gracza moze zaopatrywac cala osade."},
    {"RZADKIE ZASOBY", "Materialy z trudnych stref i innych wymiarow powinny byc traktowane jako zasob strategiczny."},
    {"LOGISTYKA", "Magazynowanie i transport sa czescia ekonomii. Chaos w skrzyniach szybko staje sie realnym kosztem."}
  }
  for _, b in ipairs(blocks) do
    writeAt(x, y, b[1], colors.orange)
    y = textBlock(x, y + 1, W - x - 3, b[2], colors.lightGray, H - 3) + 2
  end
end

local function pageTech(x)
  title(x, "DRZEWO TECHNOLOGII", "Odzyskiwanie wiedzy krok po kroku")
  local stages = {
    "[I]   SURVIVAL        -> narzedzia, jedzenie, bezpieczna baza",
    "[II]  CREATE          -> mechanizacja i automatyzacja",
    "[III] ENERGIA         -> Powah / generacja / sieci zasilania",
    "[IV]  MEKANISM        -> przemysl i zaawansowane przetwarzanie",
    "[V]   PNEUMATYKA      -> systemy cisnieniowe i automatyka",
    "[VI]  KOSMOS / WYMIARY-> ekspedycje po unikalne zasoby",
    "[VII] ENDGAME         -> odbudowa infrastruktury wysokiego poziomu"
  }
  local y = 9
  for _, s in ipairs(stages) do
    writeAt(x, y, s, colors.lightGray)
    y = y + 2
  end
  line(y, x, W - 2, "-", colors.gray)
  y = y + 2
  textBlock(x, y, W - x - 3, "Terminal jest kioskiem informacyjnym. Nie steruje baza, AE2 ani maszynami graczy - pokazuje droge progresji i dane wspolne dla spawnu.", colors.yellow)
end

local function pageWorld(x)
  title(x, "STATUS SWIATA", "Dane na zywo z Environment Detectora")
  local world = getWorldData()
  local count, names, source = getPlayers()

  local y = 9
  keyValue(x, y, "CZUJNIK SWIATA", world.connected and "ONLINE" or "NIE PODLACZONY", world.connected and colors.lime or colors.red); y = y + 2
  keyValue(x, y, "WYMIAR", world.dimension); y = y + 1
  keyValue(x, y, "BIOM", world.biome); y = y + 1
  keyValue(x, y, "POGODA", world.weather); y = y + 1
  keyValue(x, y, "CZAS SWIATA", world.time); y = y + 1
  keyValue(x, y, "FAZA KSIEZYCA", world.moon); y = y + 1
  keyValue(x, y, "SWIATLO DNIA", world.daylight); y = y + 1
  keyValue(x, y, "PROMIENIOWANIE", world.radiation, colors.yellow); y = y + 1
  keyValue(x, y, "WYMIARY W REJESTRZE", world.dimensions); y = y + 2
  keyValue(x, y, "OCALALI ONLINE", count or "N/A", count and colors.cyan or colors.yellow); y = y + 1
  keyValue(x, y, "ODCZYT GRACZY", source, colors.gray); y = y + 2

  if count and #names > 0 then
    writeAt(x, y, "LISTA OCALALYCH", colors.orange)
    textBlock(x, y + 1, W - x - 3, table.concat(names, ", "), colors.white)
  elseif not count then
    textBlock(x, y, W - x - 3, "Aby miec liczbe graczy na zywo podlacz Player Detector do komputera lub przewodowej sieci modemow.", colors.yellow)
  end
end

local function pageHelp(x)
  title(x, "POMOC // KOMENDY", "Podstawowe narzedzia ocalalego")
  local cmds = {
    {"/ftbquests", "otwiera dziennik questow"},
    {"/sethome", "ustawia punkt powrotu"},
    {"/home", "wraca do ustawionego domu"},
    {"/spawn", "wraca do strefy startowej"}
  }
  local y = 9
  for _, c in ipairs(cmds) do
    writeAt(x, y, c[1], colors.cyan)
    writeAt(x + 15, y, c[2], colors.lightGray)
    y = y + 2
  end
  y = y + 1
  writeAt(x, y, "TERMINAL", colors.orange); y = y + 2
  textBlock(x, y, W - x - 3, "Klikaj przyciski MENU bez otwierania GUI komputera. Advanced Monitor przekazuje dotkniecia bezposrednio do programu.", colors.lightGray)
end

local function pageArchive(x)
  local item = archive[archiveIndex]
  title(x, item.title, "Plik " .. archiveIndex .. " / " .. #archive)
  local y = 10
  y = textBlock(x, y, W - x - 3, item.text, colors.white, H - 8)

  local buttonY = math.max(y + 2, H - 5)
  addButton(x, buttonY, 12, "< POPRZEDNI", "archive:prev", false)
  addButton(x + 14, buttonY, 12, "NASTEPNY >", "archive:next", false)
end

local function drawPage(x)
  if currentPage == "start" then pageStart(x)
  elseif currentPage == "begin" then pageBegin(x)
  elseif currentPage == "story" then pageStory(x)
  elseif currentPage == "quests" then pageQuests(x)
  elseif currentPage == "economy" then pageEconomy(x)
  elseif currentPage == "tech" then pageTech(x)
  elseif currentPage == "world" then pageWorld(x)
  elseif currentPage == "help" then pageHelp(x)
  elseif currentPage == "archive" then pageArchive(x)
  else currentPage = "start"; pageStart(x) end
end

local function drawFooter()
  line(H - 1, 1, W, "-", colors.gray)
  writeAt(2, H, "AFTERFALL TERMINAL v2.0", colors.gray)
  local clock = textutils.formatTime(os.time(), true)
  local hint = "DOTKNIJ MENU   " .. clock
  writeAt(math.max(2, W - #hint - 1), H, hint, colors.gray)
end

local function draw()
  W, H = monitor.getSize()
  buttons = {}
  monitor.setBackgroundColor(colors.black)
  monitor.clear()
  drawHeader()
  local contentX = drawMenu()
  drawPage(contentX)
  drawFooter()
end

local function boot()
  monitor.setBackgroundColor(colors.black)
  monitor.clear()
  center(math.max(2, math.floor(H / 2) - 3), "ZIUTEKCRAFT // AFTERFALL", colors.orange)
  center(math.floor(H / 2) - 1, "URUCHAMIANIE SIECI AWARYJNEJ...", colors.lightGray)
  sleep(0.3)
  center(math.floor(H / 2), "LADOWANIE MODULOW TERMINALA...", colors.lightGray)
  sleep(0.3)
  center(math.floor(H / 2) + 1, "INTERFEJS DOTYKOWY: ONLINE", colors.lime)
  sleep(0.3)

  local pd = findPlayerDetector()
  local ed = findEnvironmentDetector()
  center(math.floor(H / 2) + 3, "PLAYER DETECTOR: " .. (pd and "ONLINE" or "N/A"), pd and colors.lime or colors.yellow)
  center(math.floor(H / 2) + 4, "ENV DETECTOR: " .. (ed and "ONLINE" or "N/A"), ed and colors.lime or colors.yellow)
  sleep(0.8)
end

local function handleButton(id)
  local page = id:match("^page:(.+)$")
  if page then
    currentPage = page
    draw()
    return
  end

  if id == "archive:prev" then
    archiveIndex = archiveIndex - 1
    if archiveIndex < 1 then archiveIndex = #archive end
    draw()
  elseif id == "archive:next" then
    archiveIndex = archiveIndex + 1
    if archiveIndex > #archive then archiveIndex = 1 end
    draw()
  end
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
refreshTimer = os.startTimer(5)

while true do
  local event, a, b, c = os.pullEvent()

  if event == "monitor_touch" then
    handleTouch(b, c)

  elseif event == "timer" and a == refreshTimer then
    draw()
    refreshTimer = os.startTimer(5)

  elseif event == "monitor_resize" then
    draw()

  elseif event == "peripheral" or event == "peripheral_detach" then
    draw()
  end
end
