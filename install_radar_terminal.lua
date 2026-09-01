-- ZiutekCraft Afterfall // Radar Operations Terminal installer
local URL="https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/radar_terminal.lua"
local TARGET="startup.lua"

local function msg(t,c)
 term.setTextColor(c or colors.white)
 print(t)
end

term.clear();term.setCursorPos(1,1)
msg("AFTERFALL // RADAR OPERATIONS R-01",colors.orange)
msg("Instalacja terminala 7x4...",colors.white)
print("")

if not http then
 msg("BLAD: HTTP API jest wylaczone w CC:Tweaked.",colors.red)
 return
end

local ok,r=pcall(http.get,URL)
if not ok or not r then
 msg("BLAD: Nie udalo sie pobrac radar_terminal.lua",colors.red)
 return
end
local content=r.readAll();r.close()
if not content or #content<1000 then
 msg("BLAD: Pobrany program jest pusty/uszkodzony.",colors.red)
 return
end

if fs.exists(TARGET) then
 if fs.exists("startup.lua.backup") then fs.delete("startup.lua.backup") end
 fs.move(TARGET,"startup.lua.backup")
 msg("Poprzedni startup -> startup.lua.backup",colors.gray)
end

local f=fs.open(TARGET,"w")
if not f then
 msg("BLAD: Nie mozna zapisac startup.lua",colors.red)
 return
end
f.write(content);f.close()

print("")
msg("RADAR TERMINAL ZAINSTALOWANY",colors.lime)
msg("Monitor: automatycznie wybiera najwiekszy",colors.lightGray)
msg("Radar: auto-detekcja Create: Radars",colors.lightGray)
msg("Speaker: opcjonalny",colors.lightGray)
msg("Restart za 2 sekundy...",colors.gray)
sleep(2)
os.reboot()
