-- ZiutekCraft Afterfall // GARAZ POJAZDOW // BIG SIGN 7x2 v2.0
-- Giant block lettering for a monitor mounted high above the garage.

local SCALE = 0.5
local monitor
local W, H = 0, 0
local phase = 0

local FONT = {
  A={"01110","10001","11111","10001","10001"},
  D={"11110","10001","10001","10001","11110"},
  G={"01111","10000","10111","10001","01111"},
  J={"00111","00010","00010","10010","01100"},
  O={"01110","10001","10001","10001","01110"},
  P={"11110","10001","11110","10000","10000"},
  R={"11110","10001","11110","10100","10010"},
  W={"10001","10001","10101","10101","01010"},
  Z={"11111","00010","00100","01000","11111"}
}

local function findLargestMonitor()
  local best, bestArea = nil, -1
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" then
      local p = peripheral.wrap(name)
      if p and p.getSize and p.setTextScale then
        pcall(p.setTextScale, SCALE)
        local ok, w, h = pcall(p.getSize)
        if ok and w and h and w*h > bestArea then
          best, bestArea = p, w*h
        end
      end
    end
  end
  return best
end

local function connect()
  monitor = findLargestMonitor()
  if not monitor then return false end
  monitor.setTextScale(SCALE)
  monitor.setCursorBlink(false)
  monitor.setBackgroundColor(colors.black)
  monitor.setTextColor(colors.white)
  monitor.clear()
  W, H = monitor.getSize()
  return true
end

local function fill(x,y,w,bg)
  if not monitor or y<1 or y>H or x>W then return end
  x=math.max(1,math.floor(x))
  w=math.max(0,math.min(w,W-x+1))
  if w<1 then return end
  monitor.setCursorPos(x,y)
  monitor.setBackgroundColor(bg)
  monitor.write(string.rep(" ",w))
end

local function put(x,y,text,fg,bg)
  if not monitor or y<1 or y>H then return end
  x=math.max(1,math.floor(x))
  if x>W then return end
  monitor.setCursorPos(x,y)
  monitor.setTextColor(fg or colors.white)
  monitor.setBackgroundColor(bg or colors.black)
  monitor.write(tostring(text):sub(1,W-x+1))
end

local function center(y,text,fg,bg)
  text=tostring(text)
  put(math.max(1,math.floor((W-#text)/2)+1),y,text,fg,bg)
end

local function wordWidth(text, sx)
  local n=#text
  return n>0 and (n*5*sx + (n-1)*sx) or 0
end

local function drawBigWord(text, y, sx, color)
  text=text:upper()
  local total=wordWidth(text,sx)
  local x0=math.max(1,math.floor((W-total)/2)+1)
  for row=1,5 do
    local x=x0
    for i=1,#text do
      local ch=text:sub(i,i)
      local glyph=FONT[ch]
      if glyph then
        local line=glyph[row]
        for col=1,5 do
          local on=line:sub(col,col)=="1"
          fill(x+(col-1)*sx,y+row-1,sx,on and color or colors.black)
        end
      end
      x=x+6*sx
    end
  end
end

local function hazard(y)
  if y<1 or y>H then return end
  for x=1,W do
    local on=((x+phase)%8)<4
    fill(x,y,1,on and colors.orange or colors.black)
  end
end

local function draw()
  if not monitor then return end
  monitor.setBackgroundColor(colors.black)
  monitor.clear()

  fill(1,1,W,colors.orange)
  center(1,"AFTERFALL // SEKTOR M-04",colors.black,colors.orange)

  -- GARAZ is shorter, so it gets extremely wide pixels.
  drawBigWord("GARAZ",3,3,colors.orange)

  local secondY = 9
  if H < 16 then secondY = 8 end
  drawBigWord("POJAZDOW",secondY,2,colors.white)

  local subY=secondY+6
  if subY<=H-2 then
    center(subY,"MILITARNE  //  UZYTKOWE",colors.yellow)
  end

  hazard(H-1)
  fill(1,H,W,colors.gray)
  center(H,"M-04 // WJAZD KONTROLOWANY",colors.black,colors.gray)
end

while not connect() do
  term.clear()
  term.setCursorPos(1,1)
  term.setTextColor(colors.orange)
  print("AFTERFALL // GARAZ M-04")
  term.setTextColor(colors.white)
  print("Czekam na monitor CC:Tweaked...")
  sleep(1)
end

draw()
local timer=os.startTimer(0.45)

while true do
  local e={os.pullEvent()}
  if e[1]=="timer" and e[2]==timer then
    phase=(phase+1)%8
    hazard(H-1)
    timer=os.startTimer(0.45)
  elseif e[1]=="monitor_resize" or e[1]=="peripheral" or e[1]=="peripheral_detach" then
    monitor=nil
    while not connect() do sleep(0.5) end
    draw()
  elseif e[1]=="terminate" then
    if monitor then
      monitor.setBackgroundColor(colors.black)
      monitor.clear()
      center(math.max(1,math.floor(H/2)),"M-04 // OFFLINE",colors.red)
    end
    return
  end
end
