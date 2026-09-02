-- ZiutekCraft Afterfall // installer: AEGIS-9

local URL = "https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/aegis-9.lua"

term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.orange)
print("AFTERFALL // AEGIS-9")
term.setTextColor(colors.white)
print("Instalacja terminala 4x3...")

local response = http.get(URL)
if not response then
  term.setTextColor(colors.red)
  print("Nie udalo sie pobrac programu.")
  return
end

local content = response.readAll()
response.close()

if fs.exists("startup.lua") then
  if fs.exists("startup.lua.backup") then fs.delete("startup.lua.backup") end
  fs.move("startup.lua", "startup.lua.backup")
end

local file = fs.open("startup.lua", "w")
file.write(content)
file.close()

term.setTextColor(colors.lime)
print("Gotowe. Restart...")
sleep(1)
os.reboot()
