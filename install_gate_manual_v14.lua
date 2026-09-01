-- ZiutekCraft Afterfall // installer Brama G-01 MANUAL v1.4
local URL="https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/gate_controller_manual_v14.lua"
local TARGET="startup.lua"

local function msg(t,c)
  term.setTextColor(c or colors.white)
  print(t)
end

term.clear();term.setCursorPos(1,1)
msg("AFTERFALL // BRAMA G-01 MANUAL v1.4",colors.orange)
msg("Bez Player Detectora // 2+ monitory // auto-close 10 s",colors.white)
print("")

if not http then
  msg("BLAD: HTTP API jest wylaczone.",colors.red)
  return
end

local ok,r=pcall(http.get,URL)
if not ok or not r then
  msg("BLAD: nie udalo sie pobrac sterownika.",colors.red)
  return
end

local content=r.readAll();r.close()
if not content or #content<1000 then
  msg("BLAD: pobrany plik jest pusty/uszkodzony.",colors.red)
  return
end

if fs.exists(TARGET) then
  if fs.exists("startup.lua.backup") then fs.delete("startup.lua.backup") end
  fs.move(TARGET,"startup.lua.backup")
  msg("Stary startup -> startup.lua.backup",colors.gray)
end

-- Kasujemy stary zapamietany stan po wersjach z Player Detectorem.
if fs.exists("/afterfall_gate_state.txt") then
  fs.delete("/afterfall_gate_state.txt")
  msg("Stary stan bramy usuniety.",colors.gray)
end

local f=fs.open(TARGET,"w")
if not f then
  msg("BLAD: nie mozna zapisac startup.lua",colors.red)
  return
end
f.write(content);f.close()

print("")
msg("STEROWNIK MANUAL v1.4 ZAINSTALOWANY",colors.lime)
msg("Dotyk ekranu = otwarcie",colors.lightGray)
msg("Po pelnym otwarciu: zamkniecie za 10 s",colors.lightGray)
msg("Player Detector NIE jest uzywany",colors.lightGray)
msg("Restart...",colors.gray)
sleep(1)
os.reboot()
