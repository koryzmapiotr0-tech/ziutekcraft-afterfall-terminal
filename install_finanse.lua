-- Installer: Afterfall TERMINAL FINANSOWY 2x1

local URL = "https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/room_sign_finanse.lua"

term.clear()
term.setCursorPos(1,1)
print("AFTERFALL // TERMINAL FINANSOWY")
print("Pobieranie programu...")

if not http then
  print("BLAD: HTTP jest wylaczone.")
  return
end

local response = http.get(URL)
if not response then
  print("BLAD: Nie udalo sie pobrac programu.")
  return
end

local data = response.readAll()
response.close()

if fs.exists("startup.lua") then
  if fs.exists("startup.lua.backup") then fs.delete("startup.lua.backup") end
  fs.move("startup.lua", "startup.lua.backup")
end

local f = fs.open("startup.lua", "w")
f.write(data)
f.close()

print("Gotowe. Restart...")
sleep(1)
os.reboot()
