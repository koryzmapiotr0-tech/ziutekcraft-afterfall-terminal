-- ZiutekCraft Afterfall // Room Sign: SKLAD
-- Safe version for Advanced Monitor wall 2 wide x 1 high.

local monitor = peripheral.find("monitor")

if monitor == nil then
  print("Nie znaleziono monitora")
  return
end

monitor.setTextScale(1)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)
monitor.clear()

local function centerText(y, text, fg, bg)
  local w, h = monitor.getSize()

  if y < 1 then y = 1 end
  if y > h then y = h end

  monitor.setBackgroundColor(bg)
  monitor.setTextColor(fg)

  local x = math.floor((w - string.len(text)) / 2) + 1
  if x < 1 then x = 1 end

  monitor.setCursorPos(x, y)

  local maxLen = w - x + 1
  if maxLen > 0 then
    monitor.write(string.sub(text, 1, maxLen))
  end
end

local function draw()
  local w, h = monitor.getSize()

  monitor.setBackgroundColor(colors.black)
  monitor.clear()

  -- Gorny pasek
  monitor.setBackgroundColor(colors.orange)
  monitor.setCursorPos(1, 1)
  monitor.write(string.rep(" ", w))
  centerText(1, "AFTERFALL", colors.black, colors.orange)

  -- Glowny napis
  local middle = math.ceil(h / 2)
  centerText(middle, "SKLAD", colors.orange, colors.black)

  -- Dolny pasek tylko jesli ekran ma co najmniej 3 linie tekstu
  if h >= 3 then
    monitor.setBackgroundColor(colors.gray)
    monitor.setCursorPos(1, h)
    monitor.write(string.rep(" ", w))
    centerText(h, "MAGAZYN", colors.black, colors.gray)
  end
end

draw()

while true do
  local event = os.pullEvent()
  if event == "monitor_resize" then
    draw()
  end
end
