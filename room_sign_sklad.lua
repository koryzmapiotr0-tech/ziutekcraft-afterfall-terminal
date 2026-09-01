-- ZiutekCraft Afterfall // Room Sign: SKLAD
-- Robust version for Advanced Monitor wall 2 wide x 1 high.
-- Waits for monitor after server/chunk restart and reconnects automatically.

local monitor = nil

local function findMonitor()
  monitor = peripheral.find("monitor")
  return monitor ~= nil
end

local function centerText(y, text, fg, bg)
  if not monitor then return end

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
  if not monitor then return end

  local ok = pcall(function()
    monitor.setTextScale(1)
    local w, h = monitor.getSize()

    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
    monitor.clear()

    -- Gorny pasek
    monitor.setBackgroundColor(colors.orange)
    monitor.setCursorPos(1, 1)
    monitor.write(string.rep(" ", w))
    centerText(1, "AFTERFALL", colors.black, colors.orange)

    -- Glowny napis
    local middle = math.ceil(h / 2)
    centerText(middle, "SKLAD", colors.orange, colors.black)

    -- Dolny pasek
    if h >= 3 then
      monitor.setBackgroundColor(colors.gray)
      monitor.setCursorPos(1, h)
      monitor.write(string.rep(" ", w))
      centerText(h, "MAGAZYN", colors.black, colors.gray)
    end
  end)

  if not ok then
    monitor = nil
  end
end

local function connectAndDraw()
  while not findMonitor() do
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.orange)
    print("AFTERFALL // SKLAD")
    term.setTextColor(colors.white)
    print("Czekam na monitor...")

    local event = os.pullEvent()
    if event ~= "peripheral" and event ~= "peripheral_detach" then
      -- Ignore unrelated events while waiting.
    end
  end

  term.clear()
  term.setCursorPos(1, 1)
  term.setTextColor(colors.lime)
  print("SKLAD // monitor polaczony")
  draw()
end

connectAndDraw()

while true do
  local event = os.pullEvent()

  if event == "monitor_resize" then
    draw()
  elseif event == "peripheral" or event == "peripheral_detach" then
    if not findMonitor() then
      connectAndDraw()
    else
      draw()
    end
  end
end
