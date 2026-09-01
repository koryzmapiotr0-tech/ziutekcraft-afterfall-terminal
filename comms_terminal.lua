-- ZiutekCraft Afterfall // R-02 Communications & Listening Station v1.0
-- Main monitor: largest connected monitor. Other monitors: status repeaters.

local SCALE=0.5
local REFRESH=0.5
local mainMonitor,mainName
local statusMonitors={}
local speaker
local radar
local detector
local phase=0
local messages={
  "SEKTOR DELTA // BRAK ODPOWIEDZI",
  "PASMO 121.5 // NASLUCH AKTYWNY",
  "R-01 // SYNCHRONIZACJA DANYCH",
  "ARCHIWUM // SYGNAL 04-17 USZKODZONY",
  "SIEC OCALALYCH // PRZEKAZNIK AKTYWNY",
  "UWAGA // NIEZNANY SYGNAL NA WSCHODZIE"
}

local function safe(obj,method,...)
  if not obj or type(obj[method])~="function" then return nil end
  local ok,a,b,c=pcall(obj[method],...)
  if ok then return a,b,c end
  return nil
end

local function discover()
  speaker=peripheral.find("speaker") or speaker
  detector=peripheral.find("player_detector") or peripheral.find("playerDetector") or detector
  radar=nil
  local monitors={}
  for _,name in ipairs(peripheral.getNames()) do
    local typ=peripheral.getType(name)
    local p=peripheral.wrap(name)
    if typ=="monitor" and p then
      pcall(p.setTextScale,SCALE)
      local ok,w,h=pcall(p.getSize)
      if ok then table.insert(monitors,{p=p,name=name,area=w*h,w=w,h=h}) end
    elseif p and type(p.getTracks)=="function" and type(p.getRange)=="function" then
      radar=p
    elseif p and type(p.getPlayersInRange)=="function" and not detector then
      detector=p
    end
  end
  table.sort(monitors,function(a,b) return a.area>b.area end)
  mainMonitor=nil;mainName=nil;statusMonitors={}
  if monitors[1] then mainMonitor=monitors[1].p;mainName=monitors[1].name end
  for i=2,#monitors do table.insert(statusMonitors,monitors[i]) end
end

local function fill(m,x,y,w,bg)
  local W,H=m.getSize()
  if y<1 or y>H or x>W then return end
  x=math.max(1,x);w=math.max(0,math.min(w,W-x+1))
  if w<=0 then return end
  m.setCursorPos(x,y);m.setBackgroundColor(bg);m.write(string.rep(" ",w))
end

local function put(m,x,y,text,fg,bg)
  local W,H=m.getSize()
  if y<1 or y>H then return end
  x=math.max(1,math.floor(x));if x>W then return end
  m.setCursorPos(x,y);m.setTextColor(fg or colors.white);m.setBackgroundColor(bg or colors.black)
  m.write(tostring(text):sub(1,W-x+1))
end

local function center(m,y,text,fg,bg)
  local W=m.getSize();text=tostring(text)
  put(m,math.max(1,math.floor((W-#text)/2)+1),y,text,fg,bg)
end

local function playerCount()
  if not detector then return 0 end
  local ok,list=pcall(detector.getPlayersInRange,64)
  return ok and type(list)=="table" and #list or 0
end

local function radarState()
  if not radar then return false,0,0 end
  local tracks=safe(radar,"getTracks") or {}
  local range=safe(radar,"getRange") or 0
  return true,type(tracks)=="table" and #tracks or 0,range
end

local function drawMain()
  if not mainMonitor then return end
  local m=mainMonitor
  local W,H=m.getSize()
  m.setBackgroundColor(colors.black);m.clear()
  fill(m,1,1,W,colors.orange)
  center(m,1," AFTERFALL // STACJA LACZNOSCI R-02 ",colors.black,colors.orange)

  local online,contacts,range=radarState()
  center(m,3,"SURVIVOR COMMUNICATION NETWORK",colors.cyan)
  center(m,4,"NASLUCH // PRZEKAZ // ARCHIWUM",colors.lightGray)

  local y=6
  put(m,3,y,"R-02 COMMS BUS",colors.white);put(m,math.max(25,W-13),y,"ONLINE",colors.lime)
  y=y+2
  put(m,3,y,"RADAR R-01 LINK",colors.white);put(m,math.max(25,W-13),y,online and "ONLINE" or "OFFLINE",online and colors.lime or colors.red)
  y=y+2
  put(m,3,y,"RADAR CONTACTS",colors.white);put(m,math.max(25,W-13),y,tostring(contacts),colors.yellow)
  y=y+2
  put(m,3,y,"RADAR RANGE",colors.white);put(m,math.max(25,W-13),y,tostring(math.floor(tonumber(range) or 0)),colors.yellow)
  y=y+2
  put(m,3,y,"PERSONNEL IN RANGE",colors.white);put(m,math.max(25,W-13),y,tostring(playerCount()),colors.cyan)

  local boxTop=math.max(y+3,math.floor(H*0.52))
  fill(m,2,boxTop,W-2,colors.gray)
  center(m,boxTop," OSTATNIA ODEBRANA TRANSMISJA ",colors.black,colors.gray)
  local msg=messages[(phase % #messages)+1]
  center(m,boxTop+2,msg,colors.yellow)
  center(m,boxTop+4,'"...do wszystkich jednostek... utrzymac lacznosc..."',colors.lightGray)

  local waveY=H-3
  if waveY>boxTop+5 then
    local chars={".","-","=","#","=","-"}
    local line=""
    for x=1,W do line=line..chars[((x+phase)%#chars)+1] end
    put(m,1,waveY,line,colors.green)
  end
  fill(m,1,H-1,W,colors.gray)
  center(m,H-1," RELAY ACTIVE // EMERGENCY BAND MONITORED ",colors.black,colors.gray)
end

local function drawStatus(entry)
  local m=entry.p
  local W,H=m.getSize()
  m.setBackgroundColor(colors.black);m.clear()
  fill(m,1,1,W,colors.orange)
  center(m,1," R-02 COMMS ",colors.black,colors.orange)
  local online,contacts=radarState()
  center(m,3,online and "RADAR LINK: ONLINE" or "RADAR LINK: OFFLINE",online and colors.lime or colors.red)
  center(m,5,"CONTACTS: "..contacts,colors.yellow)
  center(m,7,"NETWORK: ONLINE",colors.cyan)
  center(m,math.max(9,H-2),"NASLUCH AKTYWNY",colors.lightGray)
end

local function redraw()
  drawMain()
  for _,e in ipairs(statusMonitors) do drawStatus(e) end
end

discover()
redraw()
if speaker then pcall(speaker.playNote,"bell",0.5,12) end
local timer=os.startTimer(REFRESH)

while true do
  local e={os.pullEvent()}
  if e[1]=="timer" and e[2]==timer then
    phase=(phase+1)%120
    if phase%10==0 then discover() end
    redraw()
    timer=os.startTimer(REFRESH)
  elseif e[1]=="peripheral" or e[1]=="peripheral_detach" or e[1]=="monitor_resize" then
    discover();redraw()
  elseif e[1]=="monitor_touch" then
    phase=(phase+1)%#messages
    if speaker then pcall(speaker.playNote,"hat",0.4,14) end
    redraw()
  elseif e[1]=="terminate" then
    if mainMonitor then mainMonitor.setBackgroundColor(colors.black);mainMonitor.clear();center(mainMonitor,3,"R-02 // OFFLINE",colors.red) end
    return
  end
end
