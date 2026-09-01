-- ZiutekCraft Afterfall // Radar Operations Terminal installer v1.1
local URL="https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/radar_terminal.lua"
local TARGET="startup.lua"

local function msg(t,c)
 term.setTextColor(c or colors.white)
 print(t)
end

local function replaceOnce(text, old, new)
 local a,b=string.find(text,old,1,true)
 if not a then return text,false end
 return text:sub(1,a-1)..new..text:sub(b+1),true
end

term.clear();term.setCursorPos(1,1)
msg("AFTERFALL // RADAR OPERATIONS R-01",colors.orange)
msg("Instalacja terminala 7x4 // REFRESH FIX v1.1",colors.white)
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

-- v1.1 refresh patch:
-- The physical Create: Radars rotation may remain constant when the bearing is idle.
-- Keep real rotation in telemetry, but animate the PPI sweep independently.
local changed=0
local c
content,c=replaceOnce(content,"local SCALE, REFRESH = 0.5, 0.20","local SCALE, REFRESH = 0.5, 0.10")
if c then changed=changed+1 end
content,c=replaceOnce(content,"local fallbackAngle=0\nlocal lastCount=0","local fallbackAngle=0\nlocal sweepAngle=0\nlocal lastCount=0")
if c then changed=changed+1 end
content,c=replaceOnce(content,"local a=math.rad(s.rot); local lim=math.min(rx,ry*2)","local a=math.rad(sweepAngle); local lim=math.min(rx,ry*2)")
if c then changed=changed+1 end
content,c=replaceOnce(content,"fallbackAngle=(fallbackAngle+4)%360;radar,radarName=findRadar()","fallbackAngle=(fallbackAngle+4)%360;sweepAngle=(sweepAngle+7)%360;radar,radarName=findRadar()")
if c then changed=changed+1 end

if changed<4 then
 msg("UWAGA: zastosowano tylko "..changed.."/4 poprawek animacji.",colors.yellow)
 msg("Program nadal zostanie zainstalowany.",colors.yellow)
else
 msg("Refresh patch: OK // 10 FPS PPI",colors.lime)
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
msg("PPI: animowany sweep niezalezny od bearingu",colors.lightGray)
msg("Telemetria: nadal pokazuje prawdziwy kat radaru",colors.lightGray)
msg("Radar: auto-detekcja Create: Radars",colors.lightGray)
msg("Speaker: opcjonalny",colors.lightGray)
msg("Restart za 2 sekundy...",colors.gray)
sleep(2)
os.reboot()
