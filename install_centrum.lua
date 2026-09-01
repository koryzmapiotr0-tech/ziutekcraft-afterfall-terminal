-- Installer: AFTERFALL // CENTRUM OCALALYCH
local URL = "https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/room_sign_centrum.lua"

term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.orange)
print("AFTERFALL // CENTRUM OCALALYCH")
term.setTextColor(colors.white)
print("Pobieranie programu...")

local response = http.get(URL)
if not response then
  term.setTextColor(colors.red)
  print("Blad pobierania programu.")
  return
end

local content = response.readAll()
response.close()

if fs.exists("startup.lua") then fs.delete("startup.lua") end
local file = fs.open("startup.lua", "w")
file.write(content)
file.close()

term.setTextColor(colors.lime)
print("Gotowe. Restart...")
sleep(1)
os.reboot()
