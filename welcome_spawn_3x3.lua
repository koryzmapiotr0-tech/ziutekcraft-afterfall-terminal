-- ZiutekCraft Afterfall // Spawn Welcome Terminal 3x3 v1.0
-- Jeden staly ekran. Bez stron, bez klikania.
-- Po restarcie komputera uruchamiany przez startup.lua.

local SCALE = 0.5
local monitor, monitorName
local W, H = 0, 0

local function findLargestMonitor()
    local best, bestName, bestArea = nil, nil, -1
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "monitor" then
            local p = peripheral.wrap(name)
            if p and p.setTextScale and p.getSize then
                pcall(p.setTextScale, SCALE)
                local ok, w, h = pcall(p.getSize)
                if ok and w and h and (w * h) > bestArea then
                    best, bestName, bestArea = p, name, w * h
                end
            end
        end
    end
    return best, bestName
end

local function connect()
    monitor, monitorName = findLargestMonitor()
    if not monitor then return false end
    pcall(monitor.setTextScale, SCALE)
    pcall(monitor.setCursorBlink, false)
    pcall(monitor.setBackgroundColor, colors.black)
    pcall(monitor.setTextColor, colors.white)
    local ok, w, h = pcall(monitor.getSize)
    if ok then W, H = w, h end
    return true
end

local function fill(y, bg)
    if not monitor or y < 1 or y > H then return end
    monitor.setCursorPos(1, y)
    monitor.setBackgroundColor(bg)
    monitor.write(string.rep(" ", W))
end

local function put(x, y, text, fg, bg)
    if not monitor or y < 1 or y > H then return end
    x = math.max(1, math.floor(x))
    if x > W then return end
    monitor.setCursorPos(x, y)
    monitor.setTextColor(fg or colors.white)
    monitor.setBackgroundColor(bg or colors.black)
    monitor.write(tostring(text):sub(1, W - x + 1))
end

local function center(y, text, fg, bg)
    text = tostring(text)
    put(math.max(1, math.floor((W - #text) / 2) + 1), y, text, fg, bg)
end

local function hr(y, ch, fg)
    if y < 1 or y > H then return end
    put(1, y, string.rep(ch or "-", W), fg or colors.gray)
end

local function wrap(text, width)
    local lines = {}
    local line = ""
    for word in tostring(text):gmatch("%S+") do
        if #line == 0 then
            line = word
        elseif #line + 1 + #word <= width then
            line = line .. " " .. word
        else
            table.insert(lines, line)
            line = word
        end
    end
    if #line > 0 then table.insert(lines, line) end
    return lines
end

local function paragraph(y, text, fg, prefix)
    local width = math.max(10, W - 4)
    local lines = wrap(text, width)
    for i, line in ipairs(lines) do
        if y > H then break end
        local pfx = (i == 1 and prefix) or "  "
        put(2, y, pfx .. line, fg or colors.white)
        y = y + 1
    end
    return y
end

local function draw()
    if not monitor then return end
    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    fill(1, colors.orange)
    center(1, "ZIUTEKCRAFT // AFTERFALL", colors.black, colors.orange)
    center(2, "WITAJ, OCALALY", colors.yellow)
    center(3, "STREFA OCALALYCH // SPAWN", colors.lightGray)
    hr(4, "=", colors.gray)

    local y = 5
    put(2, y, "1. ROZEJRZYJ SIE", colors.orange); y = y + 1
    y = paragraph(y,
        "Obejrzyj spawn i zapoznaj sie z terminalami, sklepami, punktem medyczznym, zbrojownia oraz budynkami bazy.",
        colors.white, "> ")

    if y <= H then hr(y, "-", colors.gray); y = y + 1 end

    if y <= H then
        put(2, y, "2. JAK WYJSC ZE SPAWNA", colors.orange); y = y + 1
        y = paragraph(y,
            "Kieruj sie do glownej bramy w murze. Podejdz do niej - system wykryje gracza i otworzy przejazd. Po wyjsciu opuszczasz strefe chroniona.",
            colors.white, "> ")
    end

    if y <= H then hr(y, "-", colors.gray); y = y + 1 end

    if y <= H then
        put(2, y, "3. PRZED WYJSCIEM: RADAR R-01", colors.orange); y = y + 1
        y = paragraph(y,
            "Sprawdz liczbe kontaktow, zasieg radaru, typ celu i jego predkosc. Jesli radar pokazuje ruch w poblizu, przygotuj sie przed opuszczeniem murow.",
            colors.white, "> ")
    end

    -- Stala stopka, o ile ekran ma wystarczajaco wysokosci.
    if H >= 3 then
        fill(H - 1, colors.gray)
        center(H - 1, "PRZETRWAJ // ODBUDUJ // ODKRYWAJ", colors.black, colors.gray)
        center(H, "AFTERFALL SURVIVOR NETWORK", colors.orange)
    end
end

while not connect() do
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.red)
    print("AFTERFALL // WELCOME TERMINAL")
    print("Brak monitora.")
    term.setTextColor(colors.white)
    print("Podlacz Advanced Monitor 3x3 do komputera.")
    sleep(1)
end

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.orange)
print("AFTERFALL // WELCOME TERMINAL 3x3")
term.setTextColor(colors.lime)
print("ONLINE: " .. tostring(monitorName))
term.setTextColor(colors.white)
print("Program dziala stale. Ctrl+T aby zatrzymac.")

draw()

while true do
    local e = {os.pullEvent()}
    if e[1] == "monitor_resize" or e[1] == "peripheral" or e[1] == "peripheral_detach" then
        connect()
        draw()
    end
end
