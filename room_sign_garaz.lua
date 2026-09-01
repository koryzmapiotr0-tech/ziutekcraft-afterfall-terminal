-- ZiutekCraft Afterfall // GARAZ POJAZDOW // sign 7x2
-- CC:Tweaked Advanced Monitor. Auto-reconnect, animated hazard stripe.

local SCALE = 0.5
local monitor
local W, H = 0, 0
local phase = 0

local function findLargestMonitor()
  local best, bestArea = nil, -1
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" then
      local p = peripheral.wrap(name)
      if p and p.getSize and p.setTextScale then
        pcall(p.setTextScale, SCALE)
        local ok, w, h = pcall(p.getSize)
        if ok and w and h and (w * h) > bestArea then
          best, bestArea = p, w * h
        end
      end
    end
  end
  return best
end

local function connect()
  monitor = findLargestMonitor()
  if not monitor then return false end
  pcall(monitor.setTextScale, SCALE)
  pcall(monitor.setCursorBlink, false)
  pcall(monitor.setBackgroundColor, colors.black)
  pcall(monitor.setTextColor, colors.white)
  pcall(monitor.clear)
  W, H = monitor.getSize()
  return true
end

local function fill(x, y, width, bg)
  if not monitor or y < 1 or y > H or x > W then return end
  x = math.max(1, x)
  width = math.max(0, math.min(width, W - x + 1))
  if width == 0 then return end
  monitor.setCursorPos(x, y)
  monitor.setBackgroundColor(bg)
  monitor.write(string.rep(" ", width))
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

local function line(y, ch, fg)
  put(1, y, string.rep(ch or "-", W), fg or colors.gray)
end

local function hazard(y)
  if y < 1 or y > H then return end
  for x = 1, W do
    local alt = ((x + phase) % 6) < 3
    fill(x, y, 1, alt and colors.orange or colors.black)
  end
end

local function draw()
  if not monitor then return end
  monitor.setBackgroundColor(colors.black)
  monitor.clear()

  -- top identity band
  fill(1, 1, W, colors.orange)
  center(1, " AFTERFALL // SEKTOR TRANSPORTOWY M-04 ", colors.black, colors.orange)

  line(3, "=", colors.gray)

  -- Main garage title
  local titleY = math.max(5, math.floor(H * 0.28))
  center(titleY, "G A R A Z   P O J A Z D O W", colors.orange)
  center(titleY + 2, "MILITARNYCH  //  UZYTKOWYCH", colors.white)

  line(titleY + 4, "-", colors.gray)

  -- Status/identity rows
  center(titleY + 6, "[ MILITARY FLEET ]      [ LOGISTICS / UTILITY ]", colors.lightGray)
  center(titleY + 8, "SERWIS  //  TANKOWANIE  //  MAGAZYN  //  GOTOWOSC", colors.cyan)

  local accessY = H - 5
  if accessY > titleY + 9 then
    center(accessY, "DOSTEP KONTROLOWANY // PERSONEL AUTORYZOWANY", colors.yellow)
  end

  -- Animated lower warning band
  hazard(H - 2)
  fill(1, H - 1, W, colors.gray)
  center(H - 1, " UWAGA // RUCH POJAZDOW // ZACHOWAJ DROGE PRZEJAZDU ", colors.black, colors.gray)
  hazard(H)
end

while not connect() do
  term.clear()
  term.setCursorPos(1, 1)
  term.setTextColor(colors.orange)
  print("AFTERFALL // GARAZ M-04")
  term.setTextColor(colors.white)
  print("Czekam na monitor CC:Tweaked...")
  sleep(1)
end

draw()
local timer = os.startTimer(0.5)

while true do
  local e = {os.pullEvent()}

  if e[1] == "timer" and e[2] == timer then
    phase = (phase + 1) % 6
    draw()
    timer = os.startTimer(0.5)

  elseif e[1] == "monitor_resize" or e[1] == "peripheral" or e[1] == "peripheral_detach" then
    monitor = nil
    while not connect() do sleep(0.5) end
    draw()

  elseif e[1] == "terminate" then
    if monitor then
      monitor.setBackgroundColor(colors.black)
      monitor.clear()
      center(math.max(1, math.floor(H / 2)), "GARAZ M-04 // TERMINAL OFFLINE", colors.red)
    end
    return
  end
end
