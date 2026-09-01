-- ZiutekCraft Afterfall Command Center installer

local URL = "https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/command_center.lua"
local TARGET = "startup.lua"

local function fail(msg)
  term.setTextColor(colors.red)
  print("[AFTERFALL] " .. msg)
  term.setTextColor(colors.white)
end

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.orange)
print("AFTERFALL // COMMAND CENTER")
term.setTextColor(colors.white)
print("Instalacja drugiego ekranu...")
print("")

if not http then
  fail("HTTP API jest wylaczone w CC:Tweaked.")
  return
end

local ok, response = pcall(http.get, URL)
if not ok or not response then
  fail("Nie udalo sie pobrac command_center.lua z GitHuba.")
  return
end

local content = response.readAll()
response.close()

if not content or #content < 500 then
  fail("Pobrany plik jest pusty albo uszkodzony.")
  return
end

if fs.exists(TARGET) then
  if fs.exists("startup.lua.backup") then fs.delete("startup.lua.backup") end
  fs.move(TARGET, "startup.lua.backup")
  print("Poprzedni startup -> startup.lua.backup")
end

local file = fs.open(TARGET, "w")
if not file then
  fail("Nie mozna zapisac startup.lua")
  return
end
file.write(content)
file.close()

term.setTextColor(colors.lime)
print("")
print("Command Center zainstalowany.")
term.setTextColor(colors.lightGray)
print("Restart za 2 sekundy...")
sleep(2)
os.reboot()
