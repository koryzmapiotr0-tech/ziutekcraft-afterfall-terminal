-- ZiutekCraft Afterfall // installer bramy G-01 v1.3
local URL="https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/gate_controller_v13.lua"
local TARGET="startup.lua"

local function msg(t,c) term.setTextColor(c or colors.white); print(t) end
term.clear();term.setCursorPos(1,1)
msg("AFTERFALL // BRAMA G-01 v1.3",colors.orange)
msg("Instalacja sterownika 2x monitor + Player Detector...",colors.white)
print("")
if not http then msg("BLAD: HTTP API wylaczone.",colors.red); return end
local ok,r=pcall(http.get,URL)
if not ok or not r then msg("BLAD pobierania gate_controller_v13.lua",colors.red); return end
local content=r.readAll();r.close()
if not content or #content<1000 then msg("BLAD: uszkodzony plik.",colors.red);return end
if fs.exists(TARGET) then
  if fs.exists("startup.lua.backup") then fs.delete("startup.lua.backup") end
  fs.move(TARGET,"startup.lua.backup")
end
-- usuwa stary, potencjalnie falszywy stan OPEN z wadliwej v1
if fs.exists("/afterfall_gate_state.txt") then fs.delete("/afterfall_gate_state.txt") end
local f=fs.open(TARGET,"w")
if not f then msg("BLAD zapisu startup.lua",colors.red);return end
f.write(content);f.close()
print("")
msg("STEROWNIK v1.3 ZAINSTALOWANY",colors.lime)
msg("Oba monitory: aktywne",colors.lightGray)
msg("Dotyk: FORCE OPEN + auto-close 10 s",colors.lightGray)
msg("Restart...",colors.gray)
sleep(2)
os.reboot()
