-- ZiutekCraft Afterfall // installer Stacji Lacznosci R-02
local URL="https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/communications_terminal.lua"
local TARGET="startup.lua"

local function msg(t,c) term.setTextColor(c or colors.white); print(t) end
term.clear();term.setCursorPos(1,1)
msg("AFTERFALL // STACJA LACZNOSCI R-02",colors.orange)
msg("Instalacja terminala lacznosci...",colors.white)

if not http then msg("BLAD: HTTP API wylaczone",colors.red); return end
local ok,r=pcall(http.get,URL)
if not ok or not r then msg("BLAD: nie pobrano programu",colors.red); return end
local content=r.readAll();r.close()
if not content or #content<1000 then msg("BLAD: uszkodzony plik",colors.red); return end

if fs.exists(TARGET) then
  if fs.exists("startup.lua.backup") then fs.delete("startup.lua.backup") end
  fs.move(TARGET,"startup.lua.backup")
end
local f=fs.open(TARGET,"w")
f.write(content);f.close()
msg("R-02 ZAINSTALOWANE",colors.lime)
msg("Program obsluzy wszystkie podlaczone monitory.",colors.lightGray)
msg("Restart...",colors.gray)
sleep(2);os.reboot()
