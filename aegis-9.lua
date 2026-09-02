-- AFTERFALL // AEGIS-9
-- Statyczny terminal informacyjny
-- Monitor: 4 szerokosci x 3 wysokosci
-- CC:Tweaked

local mon = peripheral.find("monitor")
if not mon then
  error("Brak monitora. Podlacz monitor do komputera.")
end

mon.setTextScale(0.5)
mon.setCursorBlink(false)

local W, H = mon.getSize()

local BG     = colors.black
local PANEL  = colors.gray
local TITLE  = colors.orange
local RED    = colors.red
local TEXT   = colors.white
local DIM    = colors.lightGray
local WARN   = colors.yellow
local OK     = colors.lime

local function fillLine(y, bg)
  mon.setBackgroundColor(bg or BG)
  mon.setCursorPos(1, y)
  mon.write(string.rep(" ", W))
end

local function center(y, text, fg, bg)
  text = tostring(text or "")
  if #text > W then text = text:sub(1, W) end
  mon.setTextColor(fg or TEXT)
  mon.setBackgroundColor(bg or BG)
  local x = math.floor((W - #text) / 2) + 1
  mon.setCursorPos(math.max(1, x), y)
  mon.write(text)
end

local function writeAt(x, y, text, fg, bg)
  if y < 1 or y > H then return end
  mon.setCursorPos(x, y)
  mon.setTextColor(fg or TEXT)
  mon.setBackgroundColor(bg or BG)
  mon.write(text)
end

local function divider(y)
  if y > H then return end
  mon.setTextColor(DIM)
  mon.setBackgroundColor(BG)
  mon.setCursorPos(2, y)
  mon.write(string.rep("-", math.max(1, W - 2)))
end

mon.setBackgroundColor(BG)
mon.clear()

-- HEADER
fillLine(1, RED)
center(1, " AFTERFALL // AEGIS-9 ", colors.white, RED)

fillLine(2, PANEL)
center(2, "PROGRAM EKSPEDYCYJNY // OPERACJA HORYZONT", TITLE, PANEL)

center(3, "STATUS: MISJA ANULOWANA // JEDNOSTKA OCZEKUJE", WARN, BG)
divider(4)

-- LEWA KOLUMNA
local leftX = 3
local midX = math.floor(W / 2) + 1

writeAt(leftX, 6, "AEGIS-9", TITLE)
writeAt(leftX, 7, "Ostatni statek badawczy zbudowany", TEXT)
writeAt(leftX, 8, "przed upadkiem kompleksu.", TEXT)
writeAt(leftX, 9, "Mial zabrac zaloge, archiwa i probki", TEXT)
writeAt(leftX,10, "poza zasieg aktywnych anomalii.", TEXT)

writeAt(leftX,12, "PARAMETRY", TITLE)
writeAt(leftX,13, "- 9 silnikow glownego ciagu", TEXT)
writeAt(leftX,14, "- pancerz tytanowo-wolframowy", TEXT)
writeAt(leftX,15, "- autonomiczna nawigacja", TEXT)
writeAt(leftX,16, "- laboratorium i magazyn probek", TEXT)
writeAt(leftX,17, "- systemy dlugiego przetrwania", TEXT)

writeAt(leftX,19, "CEL MISJI", TITLE)
writeAt(leftX,20, "1. Opuscic Strefe Upadku.", TEXT)
writeAt(leftX,21, "2. Umiescic satelity pomiarowe.", TEXT)
writeAt(leftX,22, "3. Zbadac zrodlo anomalii.", TEXT)
writeAt(leftX,23, "4. Znalezc bezpieczne obszary.", TEXT)
writeAt(leftX,24, "5. Zachowac wiedze dla ocalalych.", TEXT)

-- PIONOWY PODZIAL
for y = 5, math.min(H - 4, 26) do
  writeAt(midX - 2, y, "|", DIM)
end

-- PRAWA KOLUMNA
local rightX = midX + 1

writeAt(rightX, 6, "RAPORT KONCOWY", TITLE)
writeAt(rightX, 7, "Na 19 godzin przed startem systemy", TEXT)
writeAt(rightX, 8, "nawigacyjne zaczely podawac rozne", TEXT)
writeAt(rightX, 9, "polozenia tej samej rakiety.", TEXT)

writeAt(rightX,11, "Czujniki wykryly:", TITLE)
writeAt(rightX,12, "- lokalne zmiany grawitacji", TEXT)
writeAt(rightX,13, "- skoki czasu", TEXT)
writeAt(rightX,14, "- zaklocenia sygnalu i telemetrii", TEXT)
writeAt(rightX,15, "- nieznane pola energetyczne", TEXT)

writeAt(rightX,17, "Trzy bezpilotowe proby zniknely", WARN)
writeAt(rightX,18, "po przekroczeniu gornej granicy", WARN)
writeAt(rightX,19, "anomalii. Nie odzyskano zadnej.", WARN)

writeAt(rightX,21, "DECYZJA RADY:", TITLE)
writeAt(rightX,22, "START AEGIS-9 ZOSTAL ANULOWANY.", WARN)

writeAt(rightX,24, "OSTATNIA WIADOMOSC", TITLE)
writeAt(rightX,25, "Jesli to czytasz, bunkier nadal zyje.", TEXT)
writeAt(rightX,26, "My nie znalezlismy drogi przez anomalie.", TEXT)

-- DOLNY KOMUNIKAT
local footerY = math.max(28, H - 5)
if footerY <= H then
  divider(footerY)
end

if footerY + 1 <= H then
  center(footerY + 1, "AEGIS-9 CZEKA.", TITLE, BG)
end
if footerY + 2 <= H then
  center(footerY + 2, "BYC MOZE WY ZNAJDZIECIE SPOSOB.", TEXT, BG)
end
if footerY + 3 <= H then
  center(footerY + 3, "POWODZENIA, SMIALKOWIE.", OK, BG)
end
if footerY + 4 <= H then
  center(footerY + 4, "NIECH WAM SIE UDA TAM, GDZIE NAM SIE NIE UDALO.", WARN, BG)
end

-- Program pozostaje wyswietlony bez przelaczania stron.
while true do
  os.pullEvent()
end
