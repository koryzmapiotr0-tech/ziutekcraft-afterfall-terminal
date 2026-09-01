-- ZiutekCraft Afterfall // Room Sign: SKLAD
-- Install as startup.lua on a dedicated Advanced Computer.

local monitor = peripheral.find("monitor")
if not monitor then
  term.setTextColor(colors.red)
  print("[AFTERFALL] Nie znaleziono monitora.")
  print("Podlacz monitor do komputera i uruchom ponownie.")
  return
end

monitor.setTextScale(1)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)
monitor.clear()
monitor.setCursorBlink(false)

local function center(y, text, fg, bg)
  local w = monitor.getSize()
  monitor.setBackgroundColor(bg or colors.black)
  monitor.setTextColor(fg or colors.white)
  monitor.setCursorPos(math.max(1, math.floor((w - #text) / 2) + 1), y)
  monitor.write(text)
end

local function draw()
  local w, h = monitor.getSize()
  monitor.setBackgroundColor(colors.black)
  monitor.clear()

  monitor.setBackgroundColor(colors.orange)
  monitor.setTextColor(colors.black)
  monitor.setCursorPos(1, 1)
  monitor.write(string.rep(" ", w))
  center(1, " AFTERFALL // SEKTOR LOGISTYCZNY ", colors.black, colors.orange)

  center(math.max(3, math.floor(h / 2) - 1), "SKLAD", colors.orange)
  center(math.max(4, math.floor(h / 2) + 1), "POMIESZCZENIE MAGAZYNOWE", colors.lightGray)

  if h >= 7 then
    center(h - 2, "DOSTEP: PERSONEL OCALALYCH", colors.gray)
  end

  monitor.setBackgroundColor(colors.gray)
  monitor.setTextColor(colors.black)
  monitor.setCursorPos(1, h)
  monitor.write(string.rep(" ", w))
  center(h, " ZIUTEKCRAFT // AFTERFALL ", colors.black, colors.gray)
end

draw()

while true do
  local event = os.pullEvent()
  if event == "monitor_resize" or event == "peripheral" or event == "peripheral_detach" then
    draw()
  end
end
