-- ZiutekCraft Afterfall // Radar Operations Terminal v1.0
-- 7x4 Advanced Monitor, CC:Tweaked + Create: Radars integration.

local SCALE, REFRESH = 0.5, 0.20
local mon, speaker, radar, radarName
local W,H=0,0
local page="live"
local buttons={}
local selected=1
local fallbackAngle=0
local lastCount=0

local lore={
 {"PRZED UPADEKIEM","SYSTEM WCZESNEGO OSTRZEGANIA R-01","Radar R-01 byl elementem sieci dozoru powietrznego i logistycznego. Monitorowal ruch nad kompleksem, korytarze transportowe oraz niezidentyfikowane obiekty w poblizu infrastruktury krytycznej."},
 {"DZIEN 0","ZERWANIE SIECI","W chwili katastrofy lacznosc z zewnetrznymi wezlami zanikla. System przeszedl w tryb autonomiczny. Ostatnie logi wskazuja na gwaltowny wzrost liczby kontaktow i utrate identyfikacji wiekszosci z nich."},
 {"DZIEN 3","PROTOKOL CISZY","Operatorzy wygasili aktywne nadajniki kompleksu. Radar pozostawiono w gotowosci, lecz bez stalego obrotu, aby ograniczyc pobor energii i emisje sygnatury instalacji."},
 {"OBECNIE","REAKTYWACJA","Po odzyskaniu zasilania R-01 zostal ponownie uruchomiony. Jego zadaniem jest wykrywanie ruchu wokol Centrum Ocalalych i przekazywanie danych do lokalnej sieci dowodzenia."}
}

local archive={
 "[22:14:08] R-01 // kontakt 041 utracony - NE",
 "[22:14:13] R-01 // 7 nowych ech niskiego pulapu",
 "[22:14:21] C2   // brak odpowiedzi z sektora DELTA",
 "[22:14:39] R-01 // klasyfikacja automatyczna OFFLINE",
 "[22:15:02] C2   // PROTOKOL CISZY zatwierdzony",
 "[22:15:07] R-01 // ograniczenie mocy nadajnika",
 "[22:15:12] R-01 // zapis lokalny kontynuowany...",
 "[--:--:--] ARCHIWUM USZKODZONE"
}

local function methods(name)
 local ok,m=pcall(peripheral.getMethods,name)
 return ok and m or {}
end
local function has(name,want)
 for _,m in ipairs(methods(name)) do if m==want then return true end end
 return false
end
local function findMonitor()
 local best,area=nil,-1
 for _,n in ipairs(peripheral.getNames()) do
  if peripheral.getType(n)=="monitor" then
   local p=peripheral.wrap(n)
   if p and p.getSize and p.setTextScale then
    local ok,w,h=pcall(p.getSize)
    if ok and w*h>area then best,area=p,w*h end
   end
  end
 end
 return best
end
local function findRadar()
 for _,n in ipairs(peripheral.getNames()) do
  if has(n,"getTracks") and has(n,"getRange") and has(n,"getRotation") then return peripheral.wrap(n),n end
 end
end
local function findSpeaker()
 for _,n in ipairs(peripheral.getNames()) do if peripheral.getType(n)=="speaker" then return peripheral.wrap(n) end end
end
local function connect()
 mon=findMonitor()
 if mon then
  mon.setTextScale(SCALE); mon.setCursorBlink(false); mon.setBackgroundColor(colors.black); mon.clear(); W,H=mon.getSize()
 end
 speaker=findSpeaker()
 radar,radarName=findRadar()
 return mon~=nil
end
local function safe(o,m,...)
 if not o or type(o[m])~="function" then return nil end
 local r=table.pack(pcall(o[m],...)); if not r[1] then return nil end
 return table.unpack(r,2,r.n)
end
local function beep(note,inst)
 if speaker then pcall(speaker.playNote,inst or "bit",0.55,note or 12) end
end
local function put(x,y,t,fg,bg)
 if y<1 or y>H then return end; x=math.max(1,math.floor(x)); if x>W then return end
 mon.setCursorPos(x,y); mon.setTextColor(fg or colors.white); mon.setBackgroundColor(bg or colors.black); mon.write(tostring(t or ""):sub(1,W-x+1))
end
local function fill(x,y,w,bg)
 if y<1 or y>H then return end; w=math.min(w,W-x+1); if w<1 then return end
 mon.setCursorPos(x,y); mon.setBackgroundColor(bg); mon.write(string.rep(" ",w))
end
local function center(y,t,fg,bg,x1,x2)
 x1,x2=x1 or 1,x2 or W; put(x1+math.floor((x2-x1+1-#t)/2),y,t,fg,bg)
end
local function line(y,x1,x2,ch,fg) put(x1,y,string.rep(ch or "-",math.max(0,x2-x1+1)),fg or colors.gray) end
local function wrap(t,w)
 local o,c={},""; for word in tostring(t):gmatch("%S+") do
  if c=="" then c=word elseif #c+#word+1<=w then c=c.." "..word else o[#o+1]=c;c=word end
 end; if c~="" then o[#o+1]=c end; return o
end
local function para(x,y,w,t,fg,maxY)
 for _,s in ipairs(wrap(t,w)) do if y>(maxY or H) then break end; put(x,y,s,fg or colors.lightGray); y=y+1 end
end
local function button(x,y,w,label,id,active)
 local bg=active and colors.orange or colors.gray; fill(x,y,w,bg); center(y,label,active and colors.black or colors.white,bg,x,x+w-1)
 buttons[#buttons+1]={x1=x,x2=x+w-1,y=y,id=id}
end
local function fmt(n,d) return type(n)=="number" and string.format("%."..(d or 0).."f",n) or "N/A" end

local function state()
 local s={online=radar~=nil,pos={x=0,y=0,z=0},rot=fallbackAngle,speed=0,range=0,dishes=0,tracks={}}
 if not radar then return s end
 local p=safe(radar,"getPosition"); if type(p)=="table" then s.pos=p end
 s.rot=tonumber(safe(radar,"getRotation")) or fallbackAngle
 s.speed=tonumber(safe(radar,"getRotationSpeed")) or 0
 s.range=tonumber(safe(radar,"getRange")) or 0
 s.dishes=tonumber(safe(radar,"getDishCount")) or 0
 local t=safe(radar,"getTracks"); if type(t)=="table" then s.tracks=t end
 return s
end
local function ti(tr,rp)
 local p=type(tr.position)=="table" and tr.position or {}; local v=type(tr.velocity)=="table" and tr.velocity or {}
 local dx=(tonumber(p.x) or 0)-(tonumber(rp.x) or 0); local dy=(tonumber(p.y) or 0)-(tonumber(rp.y) or 0); local dz=(tonumber(p.z) or 0)-(tonumber(rp.z) or 0)
 local dist=math.sqrt(dx*dx+dy*dy+dz*dz); local sp=math.sqrt((tonumber(v.x) or 0)^2+(tonumber(v.y) or 0)^2+(tonumber(v.z) or 0)^2)
 return dx,dy,dz,dist,sp
end
local function ccol(c)
 c=tostring(c or ""):lower(); if c:find("hostile") or c:find("missile") or c:find("projectile") then return colors.red end
 if c:find("air") or c:find("plane") or c:find("flying") then return colors.yellow end
 if c:find("vehicle") then return colors.orange end; if c:find("player") or c:find("friendly") then return colors.lime end; return colors.cyan
end
local function tname(tr)
 local t=tostring(tr.entityType or tr.category or "CONTACT"); t=t:match(":([^:]+)$") or t; return t:gsub("_"," "):upper():sub(1,20)
end

local tabs={{"live","LIVE RADAR"},{"contacts","KONTAKTY"},{"history","HISTORIA"},{"tech","TECHNIKA"},{"archive","ARCHIWUM"}}
local function nav()
 local gap=1; local bw=math.floor((W-2-gap*(#tabs-1))/#tabs); local x=2
 for _,t in ipairs(tabs) do button(x,H,bw,t[2],"page:"..t[1],page==t[1]); x=x+bw+gap end
end
local function header(s)
 fill(1,1,W,colors.orange); center(1," AFTERFALL // RADAR OPERATIONS R-01 ",colors.black,colors.orange)
 put(2,2,s.online and "LINK: ONLINE" or "LINK: OFFLINE",s.online and colors.lime or colors.red)
 local r=string.format("RANGE %s  DISH %d  TRACK %d",s.online and fmt(s.range,0) or "--",s.dishes,#s.tracks); put(math.max(2,W-#r-1),2,r,s.online and colors.cyan or colors.gray); line(3,1,W,"=",colors.gray)
end

local function live(s)
 local rw=math.max(30,math.floor(W*0.31)); local x1,x2=2,W-rw-2; local y1,y2=5,H-3
 local cx,cy=math.floor((x1+x2)/2),math.floor((y1+y2)/2); local rx,ry=math.max(8,math.floor((x2-x1)/2)-1),math.max(5,math.floor((y2-y1)/2)-1)
 put(2,4,"TACTICAL PPI // TOP VIEW",colors.orange)
 for deg=0,355,6 do local a=math.rad(deg); for _,f in ipairs({1,.66,.33}) do local x=cx+math.floor(math.sin(a)*rx*f+.5); local y=cy-math.floor(math.cos(a)*ry*f+.5); put(x,y,".",colors.gray) end end
 for x=x1,x2,2 do put(x,cy,"-",colors.gray) end; for y=y1,y2,2 do put(cx,y,"|",colors.gray) end; put(cx,cy,"+",colors.lime); put(cx-1,y1,"N",colors.white)
 local a=math.rad(s.rot); local lim=math.min(rx,ry*2); for i=2,lim do local f=i/lim; put(cx+math.floor(math.sin(a)*rx*f+.5),cy-math.floor(math.cos(a)*ry*f+.5),"*",colors.green) end
 local rr=s.range>0 and s.range or 256
 for i,tr in ipairs(s.tracks) do local dx,_,dz,dist=ti(tr,s.pos); if dist<=rr*1.1 then local x=cx+math.floor(dx/rr*rx+.5); local y=cy+math.floor(dz/rr*ry+.5); if x>=x1 and x<=x2 and y>=y1 and y<=y2 then put(x,y,i==selected and "X" or "o",ccol(tr.category)) end end end
 local sx=x2+3; put(sx,4,"OPERATOR DATA",colors.orange); line(5,sx,W-2,"-",colors.gray)
 local kv={{"STATUS",s.online and "ACTIVE" or "NO LINK",s.online and colors.lime or colors.red},{"ROTATION",fmt(s.rot,1).." deg"},{"ANG SPEED",fmt(s.speed,2)},{"RANGE",fmt(s.range,0).." blk",colors.cyan},{"DISH COUNT",s.dishes},{"CONTACTS",#s.tracks,#s.tracks>0 and colors.yellow or colors.lime}}
 for i,v in ipairs(kv) do put(sx,6+i,v[1],colors.gray); put(sx+14,6+i,tostring(v[2]),v[3] or colors.white) end
 line(14,sx,W-2,"-",colors.gray); put(sx,15,"SELECTED CONTACT",colors.orange)
 local tr=s.tracks[selected]
 if tr then local _,dy,_,dist,sp=ti(tr,s.pos); put(sx,17,"ID",colors.gray);put(sx+11,17,tostring(tr.id or selected));put(sx,18,"TYPE",colors.gray);put(sx+11,18,tname(tr),ccol(tr.category));put(sx,19,"RANGE",colors.gray);put(sx+11,19,fmt(dist,1).." blk");put(sx,20,"SPEED",colors.gray);put(sx+11,20,fmt(sp,2).." b/t");put(sx,21,"ALT dY",colors.gray);put(sx+11,21,fmt(dy,1));put(sx,22,"CAT",colors.gray);put(sx+11,22,tostring(tr.category or "N/A"):sub(1,18),ccol(tr.category));button(sx,H-2,10,"< PREV","prev");button(W-12,H-2,10,"NEXT >","next")
 else para(sx,17,W-sx-2,"Brak kontaktow. Radar kontynuuje skanowanie sektora.",colors.lightGray,H-3) end
end

local function contacts(s)
 put(2,5,"TRACK DATABASE // LIVE CONTACTS",colors.orange);line(6,2,W-2,"-",colors.gray)
 local c={2,10,34,49,63}; for i,v in ipairs({"ID","TYP","RANGE","SPEED","KATEGORIA"}) do put(c[i],8,v,colors.gray) end;line(9,2,W-2,"-",colors.gray)
 if #s.tracks==0 then center(13,"BRAK AKTYWNYCH KONTAKTOW",colors.lime);center(15,s.online and "Radar pracuje - oczekiwanie na echo." or "Podlacz Radar Bearing przez modem przewodowy.",colors.gray);return end
 local y=10; for i,tr in ipairs(s.tracks) do if y>H-3 then break end; local _,_,_,d,sp=ti(tr,s.pos);put(c[1],y,string.format("%02d",i),i==selected and colors.orange or colors.white);put(c[2],y,tname(tr),ccol(tr.category));put(c[3],y,fmt(d,1));put(c[4],y,fmt(sp,2));put(c[5],y,tostring(tr.category or "N/A"):sub(1,W-c[5]-1),ccol(tr.category));buttons[#buttons+1]={x1=2,x2=W-2,y=y,id="track:"..i};y=y+1 end
end

local function history()
 put(2,5,"ARCHIWUM R-01 // HISTORIA INSTALACJI",colors.orange);line(6,2,W-2,"-",colors.gray)
 local cw=math.floor((W-7)/2); for i,e in ipairs(lore) do local x=i%2==1 and 2 or cw+5; local y=i<=2 and 8 or math.floor(H/2)+2;put(x,y,e[1],colors.yellow);put(x,y+1,e[2],colors.white);para(x,y+3,cw,e[3],colors.lightGray,i<=2 and math.floor(H/2)-1 or H-3) end
end

local function tech(s)
 put(2,5,"CREATE: RADARS // DANE TECHNICZNE",colors.orange);line(6,2,W-2,"-",colors.gray);local mid=math.floor(W/2)
 put(2,8,"KONSTRUKCJA",colors.yellow);local rows={{"Radar Bearing","napedza obracajacy zespol"},{"Radar Receiver","rdzen odbiorczy nad bearingiem"},{"Plates / Dishes","elementy anteny i zasiegu"},{"Data Link","laczenie z siecia sterowania"},{"Monitor","wyswietlanie danych radarowych"}};for i,r in ipairs(rows) do put(2,9+i,r[1]);put(22,9+i,r[2],colors.gray) end
 local x=mid+2;put(x,8,"TELEMETRIA R-01",colors.yellow);local rows2={{"Link CC",s.online and "ONLINE" or "OFFLINE"},{"Peripheral",radarName or "N/A"},{"Range",fmt(s.range,1).." blk"},{"Dish count",s.dishes},{"Rotation",fmt(s.rot,2).." deg"},{"Angular",fmt(s.speed,3)}};for i,r in ipairs(rows2) do put(x,9+i,r[1],colors.gray);put(x+18,9+i,tostring(r[2]),i==1 and (s.online and colors.lime or colors.red) or colors.white) end
 line(18,2,W-2,"-",colors.gray);put(2,20,"COMPUTERCRAFT API",colors.orange);para(2,22,W-4,"LIVE korzysta z prawdziwych getTracks(), getPosition(), getRotation(), getRotationSpeed(), getRange() i getDishCount() wystawianych przez Radar Bearing.",colors.lightGray,H-3)
end

local function cinema()
 local f={{"R-01 // LOCAL ARCHIVE","RECOVERY MODE",colors.orange,8},{"22:14:08","CONTACT 041 LOST",colors.yellow,10},{"22:14:13","7 NEW LOW-ALTITUDE ECHOES",colors.red,6},{"22:14:21","NO RESPONSE // SECTOR DELTA",colors.red,5},{"22:14:39","IDENTIFICATION NETWORK FAILURE",colors.orange,4},{"22:15:02","SILENCE PROTOCOL AUTHORIZED",colors.white,3},{"SIGNAL LOST","ARCHIVE END",colors.red,1}}
 for _,v in ipairs(f) do mon.setBackgroundColor(colors.black);mon.clear();for y=2,H-2,3 do fill(1,y,math.max(6,math.floor((math.sin(y+os.clock()*9)+1)*W/4)),colors.gray) end;center(math.floor(H/2)-2,v[1],v[3]);center(math.floor(H/2),v[2],colors.lightGray);center(math.floor(H/2)+3,"/// RECOVERED DATA ///",colors.gray);beep(v[4]);sleep(1.15) end
 mon.clear();center(math.floor(H/2)-1,"R-01 REACTIVATED",colors.lime);center(math.floor(H/2)+1,"CENTRUM OCALALYCH // SYSTEM ONLINE",colors.orange);beep(12,"bell");sleep(.15);beep(16,"bell");sleep(1.2)
end
local function archivePage()
 put(2,5,"BLACK BOX // R-01 LOCAL ARCHIVE",colors.orange);line(6,2,W-2,"-",colors.gray);put(2,8,"OSTATNI ZACHOWANY FRAGMENT PRZED PROTOKOLEM CISZY",colors.yellow);local y=10;for _,v in ipairs(archive) do put(4,y,v,v:find("USZKODZONE") and colors.red or colors.lightGray);y=y+2;if y>H-6 then break end end;button(2,H-3,24,"ODTWORZ ARCHIWUM","cinema");put(29,H-3,"animowana rekonstrukcja + speaker",colors.gray)
end

local function draw()
 buttons={};local s=state();if #s.tracks==0 then selected=1 elseif selected>#s.tracks then selected=#s.tracks end;if #s.tracks>lastCount then beep(18) end;lastCount=#s.tracks
 mon.setBackgroundColor(colors.black);mon.clear();header(s);if page=="live" then live(s) elseif page=="contacts" then contacts(s) elseif page=="history" then history() elseif page=="tech" then tech(s) else archivePage() end;nav()
end
local function boot()
 mon.clear();local y=math.floor(H/2);center(y-4,"ZIUTEKCRAFT // AFTERFALL",colors.orange);center(y-2,"RADAR OPERATIONS TERMINAL R-01",colors.white);line(y,math.floor(W*.2),math.floor(W*.8),"=",colors.gray);center(y+2,"PRZYWRACANIE ARCHIWALNEGO SYSTEMU...",colors.gray);beep(8);sleep(.3);center(y+4,"RADAR BUS ............ CHECK",colors.lightGray);sleep(.2);center(y+5,"TRACK DATABASE ....... CHECK",colors.lightGray);sleep(.2);center(y+6,"SURVIVOR NETWORK ..... ONLINE",colors.lime);beep(14,"bell");sleep(.6)
end
local function click(x,y)
 for _,b in ipairs(buttons) do if x>=b.x1 and x<=b.x2 and y==b.y then beep(12,"hat");if b.id:sub(1,5)=="page:" then page=b.id:sub(6) elseif b.id=="prev" then selected=math.max(1,selected-1) elseif b.id=="next" then selected=math.min(math.max(1,#state().tracks),selected+1) elseif b.id:sub(1,6)=="track:" then selected=tonumber(b.id:sub(7)) or 1;page="live" elseif b.id=="cinema" then cinema() end;draw();return end end
end

while not connect() do term.clear();term.setCursorPos(1,1);term.setTextColor(colors.orange);print("AFTERFALL // RADAR TERMINAL");print("Czekam na monitor CC:Tweaked...");sleep(1) end
boot();draw();local timer=os.startTimer(REFRESH)
while true do
 local e={os.pullEvent()}
 if e[1]=="timer" and e[2]==timer then fallbackAngle=(fallbackAngle+4)%360;radar,radarName=findRadar();speaker=findSpeaker() or speaker;draw();timer=os.startTimer(REFRESH)
 elseif e[1]=="monitor_touch" then click(e[3],e[4])
 elseif e[1]=="peripheral" or e[1]=="peripheral_detach" or e[1]=="monitor_resize" then mon=nil;while not connect() do sleep(.5) end;draw()
 elseif e[1]=="terminate" then mon.clear();center(math.floor(H/2),"R-01 TERMINAL OFFLINE",colors.red);return end
end
