-- ZiutekCraft Afterfall // installer Brama G-01 MANUAL v1.6
local URL="https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/gate_controller_manual_v16.lua"
local TARGET="startup.lua"

local function msg(t,c)
  term.setTextColor(c or colors.white)
  print(t)
end

term.clear();term.setCursorPos(1,1)
msg("AFTERFALL // BRAMA G-01 MANUAL v1.6",colors.orange)
msg("2+ monitory // OTWORZ + ZAMKNIJ // auto-close 10 s",colors.white)
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

if fs.exists("/afterfall_gate_state.txt") then fs.delete("/afterfall_gate_state.txt") end

local f=fs.open(TARGET,"w")
if not f then
  msg("BLAD: nie mozna zapisac startup.lua",colors.red)
  return
end
f.write(content);f.close()

print("")
msg("STEROWNIK MANUAL v1.6 ZAINSTALOWANY",colors.lime)
msg("Zielony: OTWORZ",colors.lightGray)
msg("Czerwony: ZAMKNIJ",colors.lightGray)
msg("Po otwarciu: auto-zamkniecie za 10 s",colors.lightGray)
msg("Failsafe: wymusi zamkniecie przy bledzie Create",colors.lightGray)
msg("Player Detector NIE jest uzywany",colors.lightGray)
msg("Restart...",colors.gray)
sleep(1)
os.reboot()
