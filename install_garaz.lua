-- ZiutekCraft Afterfall // installer GARAZ M-04 7x2

local URL = "https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/room_sign_garaz.lua"
local TARGET = "startup.lua"

local function msg(text, color)
  term.setTextColor(color or colors.white)
  print(text)
end

term.clear()
term.setCursorPos(1, 1)
msg("AFTERFALL // GARAZ POJAZDOW M-04", colors.orange)
msg("Instalacja tablicy 7x2...", colors.white)
print("")

if not http then
  msg("BLAD: HTTP API jest wylaczone w CC:Tweaked.", colors.red)
  return
end

local ok, r = pcall(http.get, URL)
if not ok or not r then
  msg("BLAD: Nie udalo sie pobrac room_sign_garaz.lua", colors.red)
  return
end

local content = r.readAll()
r.close()

if not content or #content < 500 then
  msg("BLAD: Pobrany program jest pusty lub uszkodzony.", colors.red)
  return
end

if fs.exists(TARGET) then
  if fs.exists("startup.lua.backup") then fs.delete("startup.lua.backup") end
  fs.move(TARGET, "startup.lua.backup")
  msg("Poprzedni startup -> startup.lua.backup", colors.gray)
end

local f = fs.open(TARGET, "w")
if not f then
  msg("BLAD: Nie mozna zapisac startup.lua", colors.red)
  return
end
f.write(content)
f.close()

print("")
msg("GARAZ M-04 // TABLICA ZAINSTALOWANA", colors.lime)
msg("Monitor: 7 szerokosci x 2 wysokosci", colors.lightGray)
msg("Restart za 2 sekundy...", colors.gray)
sleep(2)
os.reboot()
