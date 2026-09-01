-- ZiutekCraft Afterfall // installer R-02 Communications Terminal
local URL="https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/comms_terminal.lua"
local TARGET="startup.lua"
term.clear();term.setCursorPos(1,1);term.setTextColor(colors.orange)
print("AFTERFALL // STACJA LACZNOSCI R-02")
term.setTextColor(colors.white);print("Instalacja terminala...")
if not http then term.setTextColor(colors.red);print("BLAD: HTTP API wylaczone");return end
local ok,r=pcall(http.get,URL)
if not ok or not r then term.setTextColor(colors.red);print("BLAD POBIERANIA");return end
local content=r.readAll();r.close()
if not content or #content<1000 then term.setTextColor(colors.red);print("BLAD: plik uszkodzony");return end
if fs.exists(TARGET) then
  if fs.exists("startup.lua.backup") then fs.delete("startup.lua.backup") end
  fs.move(TARGET,"startup.lua.backup")
end
local f=fs.open(TARGET,"w");f.write(content);f.close()
term.setTextColor(colors.lime);print("R-02 ZAINSTALOWANE")
term.setTextColor(colors.lightGray);print("Najwiekszy monitor = MAIN")
print("Pozostale monitory = STATUS")
print("Restart...")
sleep(2);os.reboot()
