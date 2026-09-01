-- ZiutekCraft Afterfall // installer automatycznej bramy G-01
local URL = "https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/gate_controller.lua"
local TARGET = "startup.lua"

local function msg(text, color)
  term.setTextColor(color or colors.white)
  print(text)
end

term.clear(); term.setCursorPos(1,1)
msg("AFTERFALL // BRAMA GLOWNA G-01", colors.orange)
msg("Instalacja automatyki Player Detector + Create...", colors.white)
print("")

if not http then
  msg("BLAD: HTTP API jest wylaczone w CC:Tweaked.", colors.red)
  return
end

local ok, r = pcall(http.get, URL)
if not ok or not r then
  msg("BLAD: nie udalo sie pobrac gate_controller.lua", colors.red)
  return
end

local content = r.readAll(); r.close()
if not content or #content < 1000 then
  msg("BLAD: pobrany program jest pusty/uszkodzony.", colors.red)
  return
end

if fs.exists(TARGET) then
  if fs.exists("startup.lua.backup") then fs.delete("startup.lua.backup") end
  fs.move(TARGET, "startup.lua.backup")
  msg("Poprzedni startup -> startup.lua.backup", colors.gray)
end

local f = fs.open(TARGET, "w")
if not f then
  msg("BLAD: nie mozna zapisac startup.lua", colors.red)
  return
end
f.write(content); f.close()

print("")
msg("STEROWNIK BRAMY ZAINSTALOWANY", colors.lime)
msg("Ruch bramy: 7 blokow", colors.lightGray)
msg("Detekcja: Player Detector", colors.lightGray)
msg("Napęd: Sequenced Gearshift + Rope Pulley", colors.lightGray)
msg("Restart za 2 sekundy...", colors.gray)
sleep(2)
os.reboot()
