-- ZiutekCraft Afterfall // installer Welcome Terminal 3x3 v1.0
local URL = "https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/welcome_spawn_3x3.lua"
local TARGET = "startup.lua"

local function msg(text, color)
    term.setTextColor(color or colors.white)
    print(text)
end

term.clear()
term.setCursorPos(1,1)
msg("AFTERFALL // WELCOME TERMINAL 3x3", colors.orange)
msg("Instalacja stalego ekranu powitalnego...", colors.white)
print("")

if not http then
    msg("BLAD: HTTP API jest wylaczone w CC:Tweaked.", colors.red)
    return
end

local ok, r = pcall(http.get, URL)
if not ok or not r then
    msg("BLAD: nie udalo sie pobrac programu.", colors.red)
    return
end

local content = r.readAll()
r.close()
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
f.write(content)
f.close()

print("")
msg("WELCOME TERMINAL ZAINSTALOWANY", colors.lime)
msg("Monitor: Advanced Monitor 3x3", colors.lightGray)
msg("Widok: jeden staly ekran", colors.lightGray)
msg("Autostart po restarcie: TAK", colors.lightGray)
msg("Restart za 2 sekundy...", colors.gray)
sleep(2)
os.reboot()
