-- ZiutekCraft Afterfall // Room Sign: CENTRUM OCALALYCH
-- Optimized for Advanced Monitor wall 2 wide x 1 high.

local monitor = peripheral.find("monitor")
if not monitor then
  term.setTextColor(colors.red)
  print("[AFTERFALL] Nie znaleziono monitora.")
  return
end

monitor.setTextScale(1)
monitor.setCursorBlink(false)

local function center(y, text, fg, bg)
  local w = monitor.getSize()
  monitor.setBackgroundColor(bg or colors.black)
  monitor.setTextColor(fg or colors.white)
  local shown = tostring(text):sub(1, w)
  local x = math.max(1, math.floor((w - #shown) / 2) + 1)
  monitor.setCursorPos(x, y)
  monitor.write(shown)
end

local function draw()
  local w, h = monitor.getSize()
  monitor.setBackgroundColor(colors.black)
  monitor.clear()

  monitor.setBackgroundColor(colors.orange)
  monitor.setCursorPos(1, 1)
  monitor.write(string.rep(" ", w))
  center(1, "AFTERFALL", colors.black, colors.orange)

  local mainY = math.max(2, math.floor((h + 1) / 2))
  center(mainY, "CENTRUM OCALALYCH", colors.orange, colors.black)

  if h >= 3 then
    monitor.setBackgroundColor(colors.gray)
    monitor.setCursorPos(1, h)
    monitor.write(string.rep(" ", w))
    center(h, "SEKTOR GLOWNY", colors.black, colors.gray)
  end
end

draw()

while true do
  local event = os.pullEvent()
  if event == "monitor_resize" or event == "peripheral" or event == "peripheral_detach" then
    draw()
  end
end
