-- ZiutekCraft Afterfall Terminal installer

local STARTUP_URL = "https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/startup.lua"

local function fail(msg)
  term.setTextColor(colors.red)
  print("[AFTERFALL] " .. msg)
  term.setTextColor(colors.white)
  return false
end

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.orange)
print("ZIUTEKCRAFT // AFTERFALL")
term.setTextColor(colors.white)
print("Instalacja terminala...")
print("")

if not http then
  fail("HTTP API jest wylaczone w CC:Tweaked.")
  return
end

local ok, response = pcall(http.get, STARTUP_URL)
if not ok or not response then
  fail("Nie udalo sie pobrac startup.lua z GitHuba.")
  return
end

local content = response.readAll()
response.close()

if not content or #content < 100 then
  fail("Pobrany plik jest pusty albo uszkodzony.")
  return
end

if fs.exists("startup.lua") then
  if fs.exists("startup.lua.backup") then
    fs.delete("startup.lua.backup")
  end
  fs.move("startup.lua", "startup.lua.backup")
  print("Stary startup zapisano jako startup.lua.backup")
end

local file = fs.open("startup.lua", "w")
if not file then
  fail("Nie mozna utworzyc startup.lua")
  return
end

file.write(content)
file.close()

term.setTextColor(colors.lime)
print("")
print("Afterfall Terminal zainstalowany.")
term.setTextColor(colors.lightGray)
print("Uruchamiam ponownie komputer za 2 sekundy...")
sleep(2)
os.reboot()
