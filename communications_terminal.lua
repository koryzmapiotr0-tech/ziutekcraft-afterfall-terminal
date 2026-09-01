-- ZiutekCraft Afterfall // Stacja Lacznosci R-02 v1.0
-- Main monitor + auxiliary monitors, CC:Tweaked

local SCALE=0.5
local REFRESH=0.5
local phase=0

local transmissions={
  {"SEKTOR DELTA","BRAK SYGNALU","red"},
  {"SEKTOR ECHO","SLABY SYGNAL","yellow"},
  {"BUNKER NETWORK","ONLINE","lime"},
  {"RADAR R-01","ONLINE","lime"},
  {"PASMO AWARYJNE","NASLUCH","orange"},
}

local logs={
  "[R-02] Wykryto zaklocenia na kanale 4.",
  "[R-01] Radar przekazal kontakt bez identyfikacji.",
  "[ARCH] Ostatnia pelna transmisja: DZIEN 0.",
  "[SYS] Siec ocalałych pracuje w trybie izolowanym.",
  "[WARN] Nie odpowiadaj na sygnal z sektora 7.",
}

local function colorByName(n)
  return colors[n] or colors.white
end

local function monitors()
  local out={}
  for _,name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name)=="monitor" then
      local p=peripheral.wrap(name)
      if p and p.getSize then
        pcall(p.setTextScale,SCALE)
        local ok,w,h=pcall(p.getSize)
        if ok then table.insert(out,{p=p,name=name,w=w,h=h,area=w*h}) end
      end
    end
  end
  table.sort(out,function(a,b) return a.area>b.area end)
  return out
end

local function put(m,x,y,t,fg,bg)
  if y<1 or y>m.h or x>m.w then return end
  m.p.setCursorPos(math.max(1,x),y)
  m.p.setTextColor(fg or colors.white)
  m.p.setBackgroundColor(bg or colors.black)
  m.p.write(tostring(t):sub(1,m.w-math.max(1,x)+1))
end

local function center(m,y,t,fg,bg)
  t=tostring(t)
  put(m,math.max(1,math.floor((m.w-#t)/2)+1),y,t,fg,bg)
end

local function fill(m,y,bg)
  if y<1 or y>m.h then return end
  m.p.setCursorPos(1,y);m.p.setBackgroundColor(bg);m.p.write(string.rep(" ",m.w))
end

local function drawMain(m)
  m.p.setBackgroundColor(colors.black);m.p.clear()
  fill(m,1,colors.orange)
  center(m,1," AFTERFALL // STACJA LACZNOSCI R-02 ",colors.black,colors.orange)
  center(m,3,"SURVIVOR COMMUNICATION NETWORK",colors.cyan)
  put(m,2,5,"KANAL / WEZEL",colors.gray)
  put(m,math.max(22,math.floor(m.w*0.55)),5,"STATUS",colors.gray)
  local y=7
  for _,r in ipairs(transmissions) do
    put(m,2,y,r[1],colors.white)
    put(m,math.max(22,math.floor(m.w*0.55)),y,r[2],colorByName(r[3]))
    y=y+2
  end
  local mid=math.floor(m.h*0.55)
  if mid>y then y=mid end
  center(m,y,"--- OSTATNIE TRANSMISJE ---",colors.gray)
  y=y+2
  for i=1,math.min(#logs,math.max(1,m.h-y-4)) do
    put(m,2,y,logs[((i+phase-2)%#logs)+1],colors.lightGray)
    y=y+1
  end
  fill(m,m.h-2,colors.gray)
  center(m,m.h-2," R-02 // NASLUCH AKTYWNY // PRIORYTET WOJSKOWY ",colors.black,colors.gray)
  local pulse=(phase%2==0) and colors.lime or colors.green
  center(m,m.h,"LINK: ONLINE   //   ENCRYPTION: ACTIVE",pulse)
end

local function drawAux(m,index)
  m.p.setBackgroundColor(colors.black);m.p.clear()
  fill(m,1,index%2==0 and colors.gray or colors.orange)
  center(m,1,index%2==0 and "R-02 // RELAY" or "R-02 // SIGNAL",colors.black,index%2==0 and colors.gray or colors.orange)
  local cy=math.max(3,math.floor(m.h/2)-1)
  if index%2==0 then
    center(m,cy,"BUNKER NET",colors.lightGray)
    center(m,cy+2,"ONLINE",colors.lime)
    center(m,cy+4,"RADAR R-01 LINK",colors.cyan)
  else
    center(m,cy,"EMERGENCY BAND",colors.lightGray)
    center(m,cy+2,(phase%2==0) and "LISTENING..." or "SCANNING...",colors.orange)
    center(m,cy+4,"SECTOR 7: NO REPLY",colors.red)
  end
end

while true do
  local ms=monitors()
  if #ms>0 then
    drawMain(ms[1])
    for i=2,#ms do drawAux(ms[i],i) end
  end
  local t=os.startTimer(REFRESH)
  while true do
    local e={os.pullEvent()}
    if e[1]=="timer" and e[2]==t then break end
    if e[1]=="terminate" then return end
  end
  phase=(phase+1)%1000
end
