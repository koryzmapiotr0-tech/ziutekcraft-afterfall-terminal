-- ZiutekCraft Afterfall // Generic Room Sign 2x1
-- Reads /afterfall_sign.cfg written by install_sign.lua

local monitor = peripheral.find("monitor")
if not monitor then
  term.setTextColor(colors.red)
  print("[AFTERFALL] Nie znaleziono monitora.")
  return
end

monitor.setTextScale(1)
monitor.setCursorBlink(false)

local function readCfg()
  local cfg = {top="AFTERFALL", main="SEKTOR", bottom="SYSTEM"}
  if fs.exists("/afterfall_sign.cfg") then
    local h = fs.open("/afterfall_sign.cfg", "r")
    if h then
      cfg.top = h.readLine() or cfg.top
      cfg.main = h.readLine() or cfg.main
      cfg.bottom = h.readLine() or cfg.bottom
      h.close()
    end
  end
  return cfg
end

local function center(y, text, fg, bg)
  local w = select(1, monitor.getSize())
  text = tostring(text or "")
  monitor.setBackgroundColor(bg or colors.black)
  monitor.setTextColor(fg or colors.white)
  local shown = text:sub(1, w)
  local x = math.max(1, math.floor((w - #shown) / 2) + 1)
  monitor.setCursorPos(x, y)
  monitor.write(shown)
end

local function draw()
  local w, h = monitor.getSize()
  local cfg = readCfg()

  monitor.setBackgroundColor(colors.black)
  monitor.clear()

  monitor.setBackgroundColor(colors.orange)
  monitor.setCursorPos(1, 1)
  monitor.write(string.rep(" ", w))
  center(1, cfg.top, colors.black, colors.orange)

  local mainY = math.max(2, math.floor((h + 1) / 2))
  center(mainY, cfg.main, colors.orange, colors.black)

  if h >= 3 then
    monitor.setBackgroundColor(colors.gray)
    monitor.setCursorPos(1, h)
    monitor.write(string.rep(" ", w))
    center(h, cfg.bottom, colors.black, colors.gray)
  end
end

draw()
while true do
  local event = os.pullEvent()
  if event == "monitor_resize" or event == "peripheral" or event == "peripheral_detach" then
    draw()
  end
end
