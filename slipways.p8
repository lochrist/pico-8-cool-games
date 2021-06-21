pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- slipways 1.1.2
-- @krajzeg ✽ @gruber_music

-- engine

-------------------------------
-- helper functions
-------------------------------

-- adds an element to an index,
-- creating a new table in the
-- index if needed
function index_add(idx,prop,elem)
 idx[prop]=idx[prop] or {}
 add(idx[prop],elem)
end

-- calls a method on an object,
-- if it exists
function event(e,evt,...)
 local fn=e and e[evt]
 if type(fn)=="function" then
  return fn(e,...)
 end
 return fn
end

-- sets everything in props
-- onto the object o
function set(o,props)
 for k,v in pairs(props or {}) do
  o[k]=v
 end
 return o
end

-- shallow copy of o
function clone(o)
 return set({},o)
end

-- helper for reading flat tables
-- into richer objects
function read_def(idx,props,res_props)
 return function(def)
  for i,p in pairs(props) do
   def[p]=contains(res_props,p)
    and r[def[i]] or def[i]
  end
  idx[def.name]=def
 end
end

function bar(y1,y2,...)
 rectfill(0,y1,127,y2 or y1,...)
end

function roundfield(x1,y1,x2)
 rect(x1,y1,x2+1,y1+12,0)
 rectfill(x1+1,y1+1,x2,y1+11,5)
 spr(70,x1,y1,1,2)
 spr(71,x2-2,y1,1,2)
end

function printsh(t,x,y,c,a)
 if (a) x-=a*4*#t
 for _,d in pairs(printsh_ds) do
  print(t,x+d.x,y+d.y,band(d.c,c))
 end
end

-------------------------------
-- sequence helpers
-------------------------------

function filter(seq,pred)
 local f={}
 for e in all(seq) do
  if (pred(e)) add(f,e)
 end
 return f
end

function each(seq,mapper)
 local m={}
 for e in all(seq) do
  add(m,mapper(e) or nil)
 end
 return m
end

function contains(seq,target)
 for e in all(seq) do
  if (e==target) return true
 end
end

function concat(a,b)
 local t={}
 local append=function(e) add(t,e) end
 foreach(a,append)
 foreach(b,append)
 return t
end

-------------------------------
-- deserialization
-------------------------------

-- helper, calls a given func
-- with a table of arguments
-- if fn is nil, returns the
-- arguments themselves - handy
-- for the o(...) serialization
-- trick
function call(fn,a)
 return fn
  and fn(a[1],a[2],a[3],a[4],a[5])
  or a
end

--lets us define constant
--objects with a single
--token by using multiline
--strings
function ob(str,props)
 local result,s,n,inpar=
  {},1,1,0
 each_char(str,function(c,i)
  local sc,nxt=sub(str,s,s),i+1
  if c=="(" then
   inpar+=1
  elseif c==")" then
   inpar-=1
  elseif inpar==0 then
   if c=="=" then
    n,s=sub(str,s,i-1),nxt
   elseif c=="," and s<i then
	   result[n]=sc=='"'
	    and sub(str,s+1,i-2)
	    or sub(str,s+1,s+1)=="("
	    and call(obfn[sc],ob(
	     sub(str,s+2,i-2)..","
	    ))
	    or sc!="f"
	    and band(sub(str,s,i-1)+0,0xffff.fffe)
	   s=nxt
	   if (type(n)=="number") n+=1
   elseif sc!='"' and c==" " or c=="\n" then
    s=nxt
   end
  end
 end)
 return set(result,props)
end

-- calls fn(character,index)
-- for each character in str
function each_char(str,fn)
 local rs={}
 for i=1,#str do
  add(rs,fn(sub(str,i,i),i) or nil)
 end
 return rs
end

-------------------------------
-- unstashing from map storage
-------------------------------

alphabet="abcdefghijklmnopqrstuvwxyz0123456789 ().,=-+_/\"'?%\n"
function unstash(addr)
 local s=""
 repeat
  local i=peek(addr)
  s=s..sub(alphabet,i,i)
  addr+=1
 until i==0
 return s
end

-------------------------------
-- objects and classes
-------------------------------

-- "object" is the base class
-- for all other classes
-- new classes are declared
-- by using object:extend({...})
object={}
 function object:extend(kob)
  kob=ob(kob or "")
  kob.extends,kob.meta,object[kob.classname or ""]=
   self,{__index=kob},kob
  return setmetatable(kob,{
   __index=self,
   __call=function(self,ob)
	   ob=setmetatable(clone(ob),kob.meta)
	   local ko,init_fn=kob
	   while ko do
	    if ko.init and ko.init~=init_fn then
	     init_fn=ko.init
	     init_fn(ob)
	    end
	    ko=ko.extends
	   end
	   return ob
  	end
  })
 end

-------------------------------
-- vectors
-------------------------------

vector={}
vector.__index=vector
 -- operators: +, -, *, /
 function vector:__add(b)
  return v(self.x+b.x,self.y+b.y)
 end
 function vector:__sub(b)
  return v(self.x-b.x,self.y-b.y)
 end
 function vector:__mul(m)
  return v(self.x*m,self.y*m)
 end
 function vector:__div(d)
  return v(self.x/d,self.y/d)
 end
 function vector:__unm()
  return v(-self.x,-self.y)
 end
 -- dot product
 function vector:dot(v2)
  return self.x*v2.x+self.y*v2.y
 end
 -- normalization
 function vector:norm()
  return self/self:len()
 end
 -- rotation
 function vector:rotr()
  return v(-self.y,self.x)
 end
 -- length
 function vector:len()
  return sqrt(#self)
 end
 -- the # operator returns
 -- length squared since
 -- that's easier to calculate
 function vector:__len()
  return self:dot(self)
 end
 -- printable string
 --[[debug]]
 --[[function vector:str()
  return self.x..","..self.y
 end]]
 --[[debugend]]

-- creates a new vector with
-- the x,y coords specified
function v(x,y)
 return setmetatable({
  x=x,y=y
 },vector)
end

function mav(magnitude,angle)
 return v(cos(angle),sin(angle))*magnitude
end

-------------------------------
-- collision boxes
-------------------------------

-- makes a new collision box
-- which is just a function
-- checking for point containment
function box(xl,yt,xr,yb)
 return function(p)
  return mid(xl,xr,p.x)==p.x
   and mid(yt,yb,p.y)==p.y
 end
end

-------------------------------
-- stringifiable functions
-------------------------------

obfn={b=box,v=v,
 br=bar,psh=printsh,
 rf=roundfield,s=spr}

-------------------------------
-- palettes
-------------------------------

function init_palettes()
 local a=0x5000
 for p=0,15 do
  for c=0,15 do
   poke(a,bor(sget(p,c),c==3 and 0x80))
   a+=1
  end
 end
end

function set_palette(no)
 memcpy(0x5f00,
  0x5000+shl(flr(no),4),
  16)
end

-------------------------------
-- missing tables
-- that can only be defined
-- once ob() is ready
-------------------------------

-- for printsh
printsh_ds=ob([[
 o(x=-1,y=-1,c=0),
 o(x=0,y=-1,c=0),
 o(x=1,y=-1,c=0),
 o(x=-1,y=0,c=0),
 o(x=1,y=0,c=0),
 o(x=-1,y=1,c=0),
 o(x=0,y=1,c=0),
 o(x=1,y=1,c=0),
 o(x=0,y=0,c=15),
]])

-------------------------------
-- entity registry
-------------------------------

-- entities are indexed for
-- easy access.
-- "entities" is a table with
-- all active entities.
-- "entities_with.<property>"
-- holds all entities that
-- have that property (used by
-- various systems to find
-- entities that move, collide,
-- etc.)
-- "entities_tagged.<tag>"
-- holds all entities with a
-- given tag, and is used for
-- collisions, among other
-- things.

-- resets the entity registry
function e_reset()
 -- empty the tables
 entities,entities_with,
  entities_tagged={},{},{}
 -- add the few global things
 g_cam,g_mouse,g_ui=
  cam(),mouse(),ui()
end

-- registers a new entity,
-- making it appear in all
-- indices and update each
-- frame
function e_add(e)
 add(entities,e)
 for p in all(indexed_properties) do
  if (e[p]) index_add(entities_with,p,e)
 end
 for t in all(e.tags) do
  index_add(entities_tagged,t,e)
 end
 return e
end

-- removes an entity,
-- effectively making it
-- disappear
function e_remove(e)
 del(entities,e)
 for p in all(indexed_properties) do
  if (e[p]) del(entities_with[p],e)
 end
 for t in all(e.tags) do
  del(entities_tagged[t],e)
 end
end

-- a list of properties that
-- need an "entities_with"
-- index
indexed_properties=ob([[
 "render","render_hud",
 "is_under",
 "new_year","new_tick",
]])

-------------------------------
-- system:
--  entity updating
-------------------------------

-- updates all entities
-- according to their state
function e_update_all()
 for _,ent in pairs(entities) do
  -- call the method with the
  -- name corresponding to
  -- this entity's current
  -- state (if it exists)
  local fn=ent[ent.state]
  if fn then
   fn(ent,ent.t)
  end
  -- removed?
  if ent.done then
   e_remove(ent)
  end
  -- advance clock
  ent.t+=1
 end
end

-------------------------------
-- entities
-------------------------------

-- every entity has some
-- basic properties
-- entities have an embedded
-- state that control how
-- they display and how they
-- update each frame
-- if entity is in state "xx",
-- its method "xx" will be called
-- each frame
entity=object:extend([[
 state="idle",t=0,
]])
 entity.init=e_add
 -- called to transition to
 -- a new state - has no effect
 -- if the entity was in that
 -- state already
 function entity:become(state)
  self.state,self.t=state,0
 end

-------------------------------
-- system:
--  rendering the world
-------------------------------

layer_parallax=ob([[0.5,1,1,1,1,1,1,1,1,0,0,0,0,0,0,]])
function r_render_all(prop)
 -- collect all drawables
 -- and sort them into buckets
 -- separated by draw_order
 local drawables={}
 for _,ent in pairs(entities_with[prop]) do
  index_add(drawables,ent.draw_order,ent)
 end
 -- render the drawable
 -- entities in the right
 -- order (z-indexing)
 for o=1,15 do
  if (prop=="render" and drawables[o]) g_cam:apply(layer_parallax[o])
  for _,ent in pairs(drawables[o] or {}) do
   ent[prop](ent,ent.pos)
  end
 end
end

-------------------------------
-- mouse support
-------------------------------

mouse=entity:extend([[
 l=o(),r=o(),pos=v(0,0),
]])
 function mouse:init()
  poke(0x5f2d,1)
 end
 function mouse:idle()
  self.pos=v(stat(32),stat(33))
  mouse_update_btn(self.l,1)
  mouse_update_btn(self.r,6)
 end
 function mouse_update_btn(obj,mask)
  local on,prev_on=
   band(stat(34),mask)>0,obj.on
  obj.on,obj.pressed,obj.released=
   on,
   on and not prev_on,
   prev_on and not on
 end

-------------------------------
-- ui helpers
-------------------------------

function std_under(e,mp,rp)
 return e.hitbox(
  (e.draw_order>=10 and rp or mp)-e.pos
 )
end

-------------------------------
-- new ui
-------------------------------

ui=entity:extend([[
 ptr=58,
 draw_order=15,
 modals=o(),
 safe_box=b(10,10,118,118),
]])
 function ui:update()
  local modals=self.modals
  self.mpos=g_mouse.pos+g_cam.pos
  self:do_hover()
  if #modals==0 or contains(modals,self.main) then
   self:do_clicks_and_drags("l")
  end
  self:do_clicks_and_drags("r")
  if g_mouse.l.pressed and self.modals==modals then
   self:dismiss_modals()
  end
  self.prev_main=self.main
 end
 function ui:render_hud()
  spr(self.rheld and 9 or self.main and self.main.ptr or self.ptr,
   g_mouse.pos.x,g_mouse.pos.y)
 end
 function ui:do_hover()
  self.hovered,self.main={}
  for e in all(entities_with.is_under) do
   if event(e,"is_under",self.mpos,g_mouse.pos) then
    index_add(self.hovered,e.draw_order,e)
    -- last added entity wins
    -- technically wrong, but turns out ok
    self.main=e
   end
  end
  (self.prev_main or {}).hover=false
  (self.main or {}).hover=true
  -- gpio hooks for javascript
  poke(0x5f80,
   self.main
    and self.main.gpio_hook
    or max(peek(0x5f80)-1,0))
 end
 function ui:do_clicks_and_drags(bt)
  local b,heldp=
   g_mouse[bt],bt.."held"
  -- clicking and grabbing new stuff
  if b.pressed then
   local grab=self:bubble(bt.."down",self.mpos,g_mouse.pos)
   if grab and type(grab.result)=="table" then
    self[heldp]=grab.result
   end
  end
  -- dragging
  local held=self[heldp]
  event(held,"dragging",self.mpos,g_mouse.pos)
  -- dropping
  if b.released and held then
   local drop=self:bubble("dropping",held)
   event(held,"dropped_on",drop and drop.object)
   self[heldp]=nil
  end
 end

 function ui:bubble(evt,...)
  for order=15,0,-1 do
   for h in all(self.hovered[order]) do
    local result=event(h,evt,...)
    if result then
     return {object=h,result=result}
    end
   end
  end
 end

 function ui:dismiss_modals()
  each(self.modals,e_remove)
  self.modals={}
 end

-------------------------------
-- buttons
-------------------------------

button=entity:extend([[
 draw_order=11,
]])
 button.is_under=std_under
 function button:init()
  self.label=label(event(self,"label"))
  self.width=self.label.w+2
  self.hitbox=box(0,-1,self.width,11)
  self.comment=self.comment and label(self.comment)
  self.tooltip=self.tooltip and tooltip(self.tooltip)
 end
 function button:idle()
  if self.tgt then
   local d=self.tgt-self.pos
   self.pos+=(#d<=1 and d or d*0.4)
  end
 end
 function button:render_hud()
  if self.tooltip and self.hover then
   self.tooltip:draw(127,1)
  end
 end
 function button:render(p)
  local rgt,dn,c=
   p.x+self.width-1,p.y+9,
   self.click
  rect(p.x-1,p.y,rgt+1,dn+1,1)
  rectfill(p.x,p.y,rgt,dn,
   c and (self.hover and 12 or 13) or 5)
  rectfill(p.x,p.y,rgt,p.y,c and 6 or 5)
  -- label
  self.label:draw(p+v(1,2))
  -- comment
  local c=self.comment
  if c then
   rectfill(rgt+3,p.y+1,rgt+c.w+4,dn,c.bg or 2)
   c:draw(p+v(self.width+3,2))
  end
 end
 function button:ldown()
  snd(self.click and 60)
  event(self,"click")
  return true
 end

function menu(p,bs)
 if p.menu_label then
  bs=concat({{label={p.menu_label,c=13}}},bs)
 end
 snd(p.menu_sound or 62)
 local pos=p.menu_pos or p.pos
 local bp=pos+v(0,0)
 g_ui:dismiss_modals()
 g_ui.modals=each(bs,function(b)
  b.pos,b.tgt,b.draw_order=
   pos,bp,p.menu_draw_order
  bp+=p.menu_step
  return button(b)
 end)
 if (p.non_modal) g_ui.modals={}
end

------------------------------
-- standalone label objects
------------------------------

label=object:extend()
 function label:init()
  local w,s,fs,f,fw=0,0
  self.fs=each(self,function(f)
   f,fw,fs=self:frage(f)
   local x=w
   w+=fw+fs
   return {fn=f,d=v(x,0)}
  end)
  self.w=w-fs
 end
 function label:draw(p,a)
  if (a) p-=v(a*self.w,0)
  for f in all(self.fs) do
   f.fn(p+f.d)
  end
 end
 function label:frage(f)
  local w,plt,stp,fn=6,0
  if type(f)=="table" then
   if (f.res) f={f.res,5}
   f,w,plt,stp=f[1],f[2],f[3] or plt,f[4]
  end
  if type(f)=="string" then
   local c=self.c or 6
   return function(p)
    printsh(f,p.x+2,p.y+1,c)
   end,#f*4+3,1
  elseif f then
   fn=function(p)
    set_palette(plt)
    spr(f,p.x,p.y)
    set_palette()
	 	end
		end
		return fn or function() end,w,stp or 2
 end

obfn.ld=label.draw

-------------------------------
-- tooltips
-------------------------------

tooltip=object:extend()
 function tooltip:init()
  self.ls=each(self,function(ln)
   return label(type(ln)=="string" and {ln} or ln)
  end)
 end
 function tooltip:draw(base,a)
  -- stay out of the way
  local h=#self*8+2
  local base-=h*a
  local dn=base+h
  -- draw
  fillp(0b0000111100001111)
  bar(base,dn,0x10)
  fillp()
  for l in all(self.ls) do
   l:draw(v(64,base+2),0.5)
   base+=8
  end
 end

-------------------------------
-- ui overlay
-------------------------------

uioverlay=entity:extend([[
 draw_order=14,
 is_under=1,
]])
 function uioverlay:ldown()
  self.done=event(self,"click")
  return true
 end

-------------------------------
-- sound
-------------------------------

function snd(no)
 if (no and not sfx_off) sfx(no,3)
end

-------------------------------
-- "fair" randomness
-------------------------------

function fairrnd(bias,b)
 return function()
  local v=rnd(1-abs(b))+max(b,0)
  b+=(0.5-v)*bias
  return v
 end
end

-->8
-- stuff

------------------------------
-- helpers
------------------------------

function delta(d,c,suffix)
 if d>=0 then
  d="+"..d
 else
  c=8
 end
 return d..(suffix or ""),c
end

function on_screen(e)
 return abs(e.pos.x-g_cam.pos.x-64)<=76 and abs(e.pos.y-g_cam.pos.y-64)<=76
end

function shake(p,e)
 e.shake=max(0,e.shake-0.1)
 return p+mav(e.shake,e.t*0.2)
end

function closest(p,others)
 local min_d,min_o=32767
 for o in all(others) do
  local d=#(p-o.p)
  if p~=o.p and d<min_d then
   min_o,min_d=o,d
  end
 end
 return min_d,min_o
end

------------------------------
-- background
------------------------------

bg=entity:extend([[
 draw_order=1,
 is_under=1,
 sprs=o(0,0,0,72,73,74,75,88,89,90,91,88,91,89,91),
]])
 function bg:init()
  local vs,vh,mrnd,m=
   {},0,fairrnd(0.1,0)
  for y=0,31 do
   for x=0,31 do
    vh=mrnd()*8-4+
     (vh+(vs[x] or 1))*0.5
    vs[x]=vh
    mset(x,y,rnd()<0.004
     and 122+rnd(5)
     or bg.sprs[flr(vh+rnd(4))])
   end
  end
 end
 function bg:render()
  map(0,0,0,0,32,32)
  fillp(0b1010010110100101)
  for xy=3,262,32 do
   rectfill(xy,0,xy,262,1)
   rectfill(0,xy,262,xy)
  end
  fillp()
  rect(0,0,262,262,5)
 end
 function bg:ldown(mp)
  return (#(entities_tagged.wormhole or {})>0 and probe or wormhole)()
 end
 function bg:rdown(mp,rp)
  self.prevp=rp
  return self
 end
 function bg:dragging(mp,rp)
  g_cam.v=self.prevp-rp
  self.prevp=rp
 end

------------------------------
-- planets
------------------------------

planet=entity:extend([[
 tags=o("planet","node","prober"),
 state="unknown",
 standard=1,income_m=1,
 draw_order=6,
 hitbox=b(-7,-7,7,7),
 shake=0,
 levels=o(2,3,9,12),
 level_names=o(
  o("unhappy",c=8),
  o("content",c=3),
  o("prosperous",c=9),
  o("rich",c=12),
 ),
 non_exporting=o(12,36,24,25),
 output=o(count=0),
 menu_step=v(0,11),menu_draw_order=9,
 output_sep=o(f,3,0,-1),
]])
 planet.is_under=std_under

 function planet:init()
  self.ways={}
  if self.building then
   self:build(buildings[self.building])
  end
 end

 function planet:discover()
  -- decide what it is
  self.kind=
   planet.rboring()<0.45
    and planet_kinds.boring
    or planet.deck()
  self.menu_label=self.kind.d
  -- make it happen
  self:become(self.kind.state or "known")
  self:twitch()
 end

 function planet:ldown()
  if self.state=="known" then
   self:build_menu()
   return true
  elseif self.state=="owned" then
   return slipway({src=self})
  end
 end

 function planet:build_menu()
  menu(self,each(
   matching_buildings(self),
   function(b)
    local cost=b:cost()
    return {
     label=event(b,"label"),
     comment=cost>0 and {cost.."$",c=13},
     click=function()
      if g_economy:spend(cost) then
       self:colonize(b)
      end
     end,
     tooltip=b:tooltip()
    }
   end
  ))
 end

 function planet:info_menu()
  local bs={{
   label=
    self.name or
     planet.level_names[self.level]
  }}
  bs[1].comment=self.income
   and {delta(self.income).."$",bg=self.income>=0 and 1}
  -- needs, wants and imports
  local imports={"receives:"}
  local needed=filter(self.inputs,function(i)
   -- update imports while filtering
   -- for needs
   for j=1,i.satisfied do
    add(imports,i)
   end
   return i.satisfied==0
  end)
  -- show needs or wants
  if needed[1] then
   -- we really need something
   add(bs,{label=concat({"needs:"},needed)})
  else
   -- we just want more
   if self.level<4 and #self.inputs>0 and self.output.res~=r.w then
    add(bs,{
     label=concat({"wants more:"},
      self.lab
       and {self.inputs[#self.inputs]}
       or self.inputs
     )
    })
   end
  end
  -- showing the imports
  add(bs,imports[2] and {label=imports})
  -- exports
  if self.output.count>0 then
   local lb=contains(planet.non_exporting,self.output.res)
    and {"makes:",tostr(self.output.count),self.output}
    or {--[[prot]]"exports:"--[[protend]],#self.current_exports.."/"..self.output.count,self.output}
   add(bs,{label=lb})
  end
  for i=2,#bs do
   add(bs[i].label,{false,1})
  end
  menu(self,bs)
 end

 function planet:colonized()
  return self.standard and self.state=="owned"
 end

 function planet:colonize(building)
  local time_cost=2
  if building.replaces_with then
   -- remaking into a new type of entity
   self.done=true
   self=object[building.replaces_with]({
    p=self.p,pos=self.pos,id=self.id
   })
  elseif building.turn_into then
   -- terraforming into a different kind of planet
   self.kind=planet_kinds[building.turn_into]
  else
   -- colonizing with an industry
   self:become("owned")
 	 self:build(building)
   self.connected=true
   time_cost=with("autoassemblers",3,2)
  end
  -- advance time
  g_economy:tick(time_cost)
  -- yello!
  snd(building.snd or 55)
  self:twitch()
 end

 function planet:build(building)
  -- normal industry
  self.industry,self.menu_label=
   building
  self.inputs=each(building.i,clone)
  self.output={res=building.o,count=0}
 end

 function planet:accept(sw)
  add(self.ways,sw)
  if (sw:counterpart(self).connected) self.connected=true
  self:twitch()
 end
 function planet:twitch()
  self.shake=1.25
 end
 function planet:boring(t)
  self.done=t>60
 end

 function planet:dropping(s)
  if self.state=="owned" then
   if s.src==self then
    self:info_menu()
   else
    return true
   end
  end
 end

 function planet:consider_offer(offer)
  local t=offer.t
  -- handle adding energy inputs
  if t.res==r.e
   and not self.powered then
    for i in all(self.inputs) do
     if i.satisfied==0 and i.res~=r["?"] then
      del(self.inputs,i)
      break
     end
    end
    self.inputs,self.powered=
     concat({{res=r.e}},self.inputs),
     1
  end
  for i in all(self.inputs) do
   -- filling "?" inputs with concrete values
   if i.res==r["?"] and contains(self.replacement_resources,t.res) then
    i.res=t.res
   end
   -- filling normal needs
   if t.res==i.res and i.res~=r["?"] then
    offer:accept(t:append(self))
    return
   end
  end
 end

 function planet:exports()
  local exports=self.current_exports or {}
  local res,count=
   self.output.res,
   self.output.count
  for w in all(self.ways) do
   local offer={
    t=trade({
     route={self},via={w},
     res=res
    }),
    count=count-#exports,
    accept=function(self,a)
     if not contains(exports,a) then
      add(exports,a)
      self.count-=1
     end
    end
   }
   if (offer.count==0) break
   w:counterpart(self)
    :consider_offer(offer)
  end
  return exports
 end

 function planet:new_year()
  if self.income and self.income~=0 and on_screen(self) then
   floater({pos=self.pos,delta(self.income,10,"$")})
  end
 end

 function planet.make_label(
  is,o,ocount,oused,d
 )
  if (not o) return
  local l,iwidth,icons=
   {},#is>=3 and 1 or 0,
   o==r.w and {25,23} or {o}
  local wide=ocount*#icons>=3
  -- needs
  for i in all(is) do
   add(l,{
    i.res,
    3-iwidth,
    i.satisfied~=0 and 0 or 7
   })
  end
  -- arrow
  if #is>0 then
   add(l,{false,d+iwidth})
   add(l,(d==1 or wide) and {35,2+d} or {32,5})
  end
  -- production
  if ocount>5 then
   add(l,tostr(ocount))
   add(l,{false,-4})
   l.c=13
   ocount=1
  end
  for ico in all(icons) do
   for i=1,max(ocount,1) do
    add(l,{ico,
     6,
     (i<=ocount and i>oused) and 0 or 7,
     wide and -4 or -3
    })
   end
   add(l,planet.output_sep)
  end
  -- done!
  return label(l)
 end

 function planet:new_tick()
  self.label=planet.make_label(
   self.inputs,
   self.output.res,self.output.count,
   #self.current_exports,0
  )
 end

 function planet:render(p)
  if (not on_screen(self)) return
  -- shaking
  p=shake(p,self)
  -- flicker for disappearing planets
  if self.state=="boring" and rnd(30)<self.t-30 then
   return
  end
  -- outline
  circfill(p.x,p.y,7,0)
  -- planet sprite
  set_palette(self.plt)
  palt(3,false)
  palt(0,true)
  spr(self.kind and self.kind.s or self.s or 43,
   p.x-4,p.y-4,2,2)
  set_palette()
  -- ownership ring and flag
  if self:colonized() then
    circ(p.x,p.y,6,
     planet.levels[self.level])
    spr(self.level+1,p.x-3,p.y-6)
  end
  -- i/o label
  event(self.label,"draw",p+v(0,7),0.5)
  -- obstructing something?
  if self.obstructs then
   fillp(0b1010101010101010.1)
   circfill(p.x,p.y,
    sqrt(self.obstructs.safe_radius)*128,
    2)
   fillp()
   self.obstructs=nil
  end
 end

------------------------------
-- common functionalities
------------------------------

function buyable_dragging(self,mp,rp)
 -- update positions
 self.pos,self.p=mp,mp/128
 -- check for obstructions/cancellation
 local dist,c=closest(self.p,entities_tagged.node)
 self.obstructed=
  dist<self.safe_radius and c or
  filter(entities_tagged.slipway,function(sw)
   return segment_crosses_ball(sw.src.p,sw.dst.p,self.p,0.0032)
  end)[1] or
  not ui.safe_box(rp) and {}
 if (self.obstructed) self.obstructed.obstructs=self
end
function buyable_show(self)
 if self.state=="buying" then
  local mp,t=g_mouse.pos
  if self.obstructed then
   t=self.obstructed.str
   if (not t) spr(31,mp.x-3,mp.y-8)
  elseif self.cost then
   t=self.cost.."$"
  end
  printsh(t or "",mp.x,mp.y-8,8,0.5)
 end
end
function buyable_buy(self)
 if not self.obstructed
  and g_economy:spend(self.cost) then
   self:become(self.bought_state or "idle")
   g_economy:tick(self.time_cost or 0)
   snd(self.buy_snd or 54)
   return true
 else
  snd(57)
  self.done=true
 end
end
function float(self,t)
 self.pos.y+=sin(t*0.005)*0.06
end

------------------------------
-- info window
------------------------------

infow=entity:extend([[
 tags=o("infow"),
 draw_order=14,
 spd=5,
]])
 function infow:init()
  if (g_info) g_info.done=true
  g_info=self
 end
 function infow:render_hud()
  local t=self.t/self.spd-10
  if t>=0 and event(self,"locked") then
   self.t,t=self.spd*10,0
  end
  local trans=-t^3/9
  draw_from_template(self,trans)
  camera()
  if t>10.5 then
   self.done,g_info=true
  end
 end

function draw_from_template(tpl,trans)
 for e in all(tpl) do
  if trans then
   camera(trans,0)
   trans=-trans
  end
  call(obfn[e.fn],e)
 end
end

------------------------------
-- trades
------------------------------

trade=object:extend()
 function trade:to()
  return self.route[#self.route]
 end
 function trade:append(node,slipway)
  return trade({
   route=concat(self.route,{node}),
   via=concat(self.via,{slipway}),
   res=self.res
  })
 end
 function trade.meta.__eq(l,r)
  return l.route[1]==r.route[1]
   and l:to()==r:to()
 end

------------------------------
-- slipways
------------------------------

slipway=entity:extend([[
 tags=o("slipway"),
 state="buying",
 draw_order=2,
 time_cost=f,buy_snd=48,
 safe_radius=0.004,
 colors=o(0,0,7,7,10,10,9,9,9,9,9,9,9,9,4,4,4,2,2,1),
 flash=20,
]])
 function slipway:init()
  snd(50)
  self.ts,self.sends_to={},{}
 end

 function slipway:dragging(mp)
  self.dst=g_ui.main.dropping and g_ui.main or {pos=mp,p=mp/128}
  self.cost=
   slipway_cost(self.src,self.dst)
  self.infra=
   self.src.infra or self.dst.infra
  self.obstructed=self:check_obstacles()
  if self.obstructed then
   self.obstructed.obstructs=
    self
  end
  self.draw_order=
   self.infra and 2 or 4
 end

 -- connecting a slipway
 function slipway:dropped_on(dst)
  if not dst
   or not buyable_buy(self) then
    if (stat(19)==50) snd(-1)
    self.done=true
    return
  end
  self.flash,self.dst=1,dst
  self.src:accept(self)
  dst:accept(self)
  g_economy:tick(1)
 end

 -- validity checks
 function slipway:check_obstacles()
  local sp,dp=self.src.p,self.dst.p
  -- length
  if #(sp-dp)>with("space folding",0.5,1.08) then
   return {str="-too far-"}
  end
  -- already exists on this route?
  for w in all(self.src.ways) do
   if (w:counterpart(self.src)==self.dst) return w
  end
  -- other slipways/planets obstructing
  local obstructions=concat(
   filter(entities_tagged.node,function(n)
    return segment_crosses_ball(sp,dp,n.p,0.0032)
   end),
   filter(entities_tagged.slipway,function(sw)
    return sw.infra==self.infra and
     segments_cross(sp,dp,sw.src.p,sw.dst.p)
   end)
  )
  return obstructions[1]
 end
 -- querying for the other end
 function slipway:counterpart(planet)
  return planet==self.src and self.dst or self.src
 end
 -- rendering
 function slipway:spawn_transport(f,t)
  if rnd()<0.08 and self.sends_to[t.id] then
   local d=t.pos-f.pos
   local v=d:norm()
   add(self.ts,{
    pos=f.pos+v:rotr(),v=v,
    l=d:len()
   })
  end
 end

 function slipway:dlines(l,h,s,c)
  local src,dst=
   self.src.pos+mav(1.5,self.t/126),
   self.dst.pos+mav(1.5,self.t/176)
  for dx=l,h,s do
   for dy=l,h,s do
    line(src.x+dx,src.y+dy,
         dst.x+dx,dst.y+dy,c)
   end
  end
 end

 function slipway:render()
  if on_screen(self.src) or on_screen(self.dst) then
   local base_c=
    self.colors[self.flash]
   if (self.flash<20) self.flash+=1
   local c,bc,tc=
    (self.obstructed or self.obstructs) and 2 or self.infra and 0 or base_c,
    self.infra and base_c or 0,
    self.infra and 5 or 13
   -- the slipway itself
   self:dlines(-1,2,3,bc)
   self:dlines(0,1,1,c)
   -- transports
   for _,t in pairs(self.ts) do
    t.pos+=t.v
    t.l-=1
    if (t.l<=0) del(self.ts,t)
    local x,y=t.pos.x,t.pos.y
    rectfill(x,y,x+1,y+1,0)
    pset(x,y,tc)
   end
   self:spawn_transport(self.src,self.dst)
   self:spawn_transport(self.dst,self.src)
  end
  -- reset
  self.obstructs=nil
 end

 function slipway:render_hud()
  if (self.src~=self.dst) buyable_show(self)
 end

------------------------------
-- particle system
------------------------------

function psys_init(self)
 self.pts={}
end
function psys_spawn(self,n)
 while rnd()<n do
  add(self.pts,self:point())
  n-=1
 end
end
function psys_render(self)
 -- early exit
 if (self.draw_order<10 and not on_screen(self)) return
 local cx,cy,mxx,mxy,myx,myy,cs=
  self.pos.x,self.pos.y,
  self.mxx,self.mxy,self.myx,self.myy,
  self.colors
 -- update and draw everything
 for _,p in pairs(self.pts) do
  local pv=p.v
  p.p+=pv
  p.v.x=mxx*pv.x+myx*pv.y
  p.v.y=mxy*pv.x+myy*pv.y
  if (p.a) p.v+=p.a
  p.l-=0.14
  if p.l<=1 then
   del(self.pts,p)
  else
   pset(cx+p.p.x,cy+p.p.y,cs[flr(p.l)])
  end
 end
 -- spawn new points
 psys_spawn(self,self.generation)
end

------------------------------
-- wormhole
------------------------------

wormhole=entity:extend([[
 tags=o("wormhole","prober"),
 connected=1,
 bought_state="owned",
 cost=0,time_cost=f,
 draw_order=2,
 safe_radius=0.025,

 pspd=0.06,linger=9,
 arms=3,vrot=1,
 generation=1,
 colors=o(1,1,5,13,6),
 mxx=1.02,myx=-0.0525,
 mxy=0.0525,myy=1.02,
 displacement=2,
]])
 wormhole.dragging=buyable_dragging
 wormhole.dropped_on=buyable_buy
 wormhole.render_hud=buyable_show
 wormhole.init=psys_init
 wormhole.render=psys_render
 function wormhole:point()
  local a=(flr(rnd(self.arms))+rnd(0.5))/self.arms+self.t*0.001
  local p=mav(self.displacement+rnd(),a)
  local v=p*self.pspd
  return {
   p=p,v=self.vrot and v:rotr() or v,
   l=self.linger
  }
 end

------------------------------
-- generation
------------------------------

function make_deck(contents,reps,r)
 local deck,prev={},{}
 -- create deck table
 for e in all(contents) do
  for n=1,e.r*reps do
   add(deck,e)
  end
 end
 -- return deal function
 return function()
  -- repeating prevention
  local e
  repeat
   e=deck[flr(r()*#deck+1)]
  until not contains(prev,e)
  -- remove from deck
  del(deck,e)
  -- store at prev[1][2][3]
  -- cyclically (nasty trick)
  prev[3-#deck%3]=e
  return e
 end
end

function generate_planets(n)
 -- generate n planets
 for id=1,n do
  local p
  repeat
   p=v(
    rnd(2.75)+0.125,
    rnd(2.75)+0.125
   )
  until closest(p,entities_tagged.planet)>0.05
  planet({id="p"..id,p=p,pos=p*128})
 end
 -- initialize the planet deck
 planet.deck,planet.rboring=
  make_deck(planet_kinds,2,
   fairrnd(0.5,g_difficulty.ptype_bias)),
  fairrnd(0.8,0.5)
end

------------------------------
-- probes
------------------------------

probe=entity:extend([[
 tags=o("probe"),
 state="buying",safe_radius=0,
 bought_state="scan",
 spawn_snd=52,buy_snd=49,
 size=0,
 cost=3,time_cost=1,
 draw_order=5,
 scan_c=o(7,7,6,13,5,1,1,1,0),
 too_far=o(str="-too far-"),
]])
 probe.dragging=buyable_dragging
 probe.render_hud=buyable_show

 function probe:init()
  snd(53)
  self.srcs=filter(entities,function(p)
   return p.connected
  end)
 end

 function probe:dragging(...)
  buyable_dragging(self,...)
  local dist
  dist,self.closest=closest(self.p,self.srcs)
  if dist>with("space folding",0.19,0.27) then
   self.obstructed=probe.too_far
  end
 end

 function probe:buying(t)
  self.size=with("space folding",29,35)*
   (min(t/15,1)+sin(t/40)*0.1)
 end

 function probe:dropped_on()
  self.done=
   self.t<15 or not buyable_buy(self)
 end

 function probe:scan(t)
  local sr=self:scan_radius(t)/128+0.031
  for pt in all(entities_tagged.planet) do
   if pt.state=="unknown"
    and (pt.p-self.p):len()<sr then
     pt:discover()
   end
  end
  self.done=t>25
 end

 function probe:render(p)
  if self.state=="buying" then
   if not self.obstructed then
    circ(p.x,p.y,self.size,1)
   end
   local cp=self.closest.pos
   line(cp.x,cp.y,p.x,p.y,1)
   spr(7,p.x-4,p.y-4)
  else
   for dt=0,8,2 do
    if self.t>dt then
     local sr=self:scan_radius(self.t-dt)
     circ(p.x,p.y,sr,
      self.scan_c[flr(sr/self.size*8)])
    end
   end
  end
 end

 function probe:scan_radius(t)
  return min(sqrt(t/15),1)*self.size
 end

------------------------------
-- main game visualization
--  and control
------------------------------

month_names=ob("\"\74\65\78\",\"\70\69\66\",\"\77\65\82\",\"\65\80\82\",\"\77\65\89\",\"\74\85\78\",\"\74\85\76\",\"\65\85\71\",\"\83\69\80\",\"\79\67\84\",\"\78\79\86\",\"\68\69\67\",\"\85\78\68\",\"\68\85\79\",\"\84\69\82\",")
score_templates=ob([[
 o(26,86,0,fn="br"),
 o(51,59,1,fn="br"),
 o(76,77,1,fn="br"),
 o(24,25,1,fn="br"),
 o(33,41,1,fn="br"),
 o("",score=0,pos=v(64,21),c=5),
 o(55,"planets:   ",
  score=1,pos=v(64,34)),
 o(19,"population:",
  score=2,pos=v(64,43)),
 o(24,"technology:",
  score=3,pos=v(64,52)),
 o(o(27,5),o(f,0),f,o(25,5),"happiness",
  score=4,pos=v(64,61)),
 o("total:","",
  score=5,pos=v(64,74)),
 o(score=6,pos=v(64,82)),
]])
game=entity:extend([[
 draw_order=10,
 new_year_iw=o(
  o(42,43,1,fn="br"),
  o("",64,40,6,0.5,fn="psh"),
 ),
 warnings=o(
  o("last year!",64,48,9,0.5,fn="psh"),
  o("2 years remain",64,48,2,0.5,fn="psh"),
  f,f,
  o("5 years remain",64,48,2,0.5,fn="psh"),
 ),
 research_menu=o(
  menu_pos=v(0,11),menu_step=v(0,11),menu_draw_order=10,
 ),
 statics=o(
  o(126,127,1,fn="br"),
  o(0,1,1,fn="br"),
  o(8,118,34,fn="rf"),
  o(0,-3,26,fn="rf"),
  o(81,-3,117,fn="rf"),
 ),
 info=o(
  o(f,13,121,9,fn="psh"),
  o(f,37,121,2,fn="psh"),
  o(f,13,2,9,fn="psh"),
  o(f,29,2,2,fn="psh"),
  o(f,59,2,2,fn="psh"),
  o(f,85,2,13,fn="psh"),
  o(f,99,2,13,fn="psh"),
 ),
 score_infow=1,
]])
 function game:new_tick()
  local cf=delta(g_economy.cash_flow)
  local info={
   g_economy.cash.."$",
   cf,
   g_economy.science,
   "+"..g_economy.prod[r.k]+1,
   g_economy.happiness.."%",
   month_names[g_economy.month],
   g_economy.yr
  }
  for i,p in pairs(info) do
   game.info[i][1]=p
  end
  music_adapt()
 end
 function game:render()
  -- hud
  draw_from_template(concat(game.statics,game.info))
  -- letterbox
  if self.complete then
   self.complete+=0.2
   local h=min(self.complete,3.2)^2
   bar(0,h,0)
   bar(127-h,127)
  end
 end
 function game:new_year(yr)
  local iw,warn=
   game.new_year_iw,
   game.warnings[3426-yr]
  iw[2][1],iw[3]=
   "year "..yr,
   warn or nil
  if warn then
   local t=90
   function iw.locked()
    t-=1
    return t>0
   end
  end
  infow(iw)
 end
 function game:idle()
  -- cheats
  --[[debug]]
  if btn(4) and btn(5) then
   g_economy.cash+=5
   g_economy.science+=5
  end
  --[[debugend]]
  -- scoring
  if g_economy.game_end and not self.complete then
   uioverlay()
   button(ob([[
    draw_order=15,
    pos=v(51,100),
    label=o(" again? "),
   ]],{click=_init}))
   button(ob([[
    draw_order=15,
    pos=v(39,100),
    label=o(o(10,7)),
   ]],score_toggle))
   self.display_score,
   self.complete,
   self.draw_order=
    true,0,13
  end
  if self.display_score and g_info~=self.score_infow then
   local s=scores()
   local iw=each(score_templates,function(st)
    if st.score then
     -- individual scores
     st[3]=tostr(s[st.score])
     -- header
     if st.score==0 then
      st[1]=(g_economy.game_end or "current score").." ("..g_difficulty.name..")"
     end
     -- stars
     if st.score==6 then
      for i=1,5 do
       st[i]=i<=s[6] and 56 or 57
      end
     end
     -- turn to label draw
     return {label(st),st.pos,0.5,fn="ld"}
    else
     return st
    end
   end)
   iw.spd=3
   function iw.locked()
    return self.display_score
   end
   self.score_infow=infow(iw)
  end
 end

score_toggle={
 click=function()
  g_game.display_score = not g_game.display_score
  return true
 end
}

------------------------------
-- lab
------------------------------

lab=planet:extend([[
 tags=o("lab","planet","node","prober"),
 building=1,name=o("laboratory",c=13),
 state="buying",bought_state="owned",
 standard=f,lab=1,
 cost=15,time_cost=2,
 safe_radius=0.025,
 level=1,
 s=174,
 replacement_resources=o(28,18,20,21,22,48),
]])
 lab.dragging=buyable_dragging
 lab.owned=float
 lab.render_hud=buyable_show
 lab.dropped_on=buyable_buy

------------------------------
-- spawners
------------------------------

spawner=entity:extend([[
 hitbox=b(0,0,9,8),
 draw_order=12,
 id=0,
 pos=v(999,999),
 initial_pos=v(118,120),
]])
 spawner.is_under=std_under

 function spawner:new_tick()
  if not self.active and tech(self.entity.req) then
   self.pos,self.active=
    spawner.next_pos,true
   spawner.next_pos-=v(10,0)
  end
 end

 function spawner:ldown(mp)
  spawner.id+=1
  return self.entity({
   id="s"..spawner.id
  })
 end
 function spawner:render(p)
  if self.active then
   palt(3,false)
   spr(self.entity.s,p.x,p.y)
   if self.hover then
    buyable_show(self.entity)
    self.tooltip:draw(0,0)
   end
   palt(3,true)
  end
 end

------------------------------
-- floater
------------------------------

floater=entity:extend([[
 draw_order=9,
 l=0,v=v(0,-0.34),
]])
 function floater:init()
  self.pos=self.pos or
   g_mouse.pos+g_cam.pos-v(0,5)
 end
 function floater:idle()
  self.pos+=self.v
  self.l+=0.1
  self.done=self.l>=5
 end
 function floater:render(p)
  set_palette(self.l)
  printsh(self[1],p.x,p.y,self[2],0.5)
  set_palette()
 end

------------------------------
-- research
------------------------------

function research_menu()
 local bs,itt,ninvented=
  {},{},#g_economy.invented
 -- tech level
 local tl=g_economy.tech_level
 local prv=lv_advance[tl-1] or 0
 -- techs
 local bs=each(available_techs(true),
  function(t)
   return {
    label={t.kind,t.name,c=6},
    comment={
     {24,5},
     tostr(tech_cost(t))
    },
    tooltip=t.desc,
    click=t.affordable and function()
     g_economy:invent(t)
    end
   }
  end
 )
 if ninvented>0 then
  add(bs,{
    label={30,ninvented.." invented",c=3},
    tooltip=g_economy.invented
  })
 end
 game.research_menu.menu_label=
  --[[prot]]"level "--[[protend]]..tl.." ("..(ninvented-prv).."/"..(lv_advance[tl]-prv)..")"
 menu(game.research_menu,bs)
end

------------------------------
-- hud buttons
------------------------------

hudbtns=ob([[
 o(
  pos=v(118,0),
  label=o(o(15,7)),
 ),o(
  pos=v(0,0),
  label=o(o(37,7)),
 ),o(
  pos=v(47,0),
  label=o(o(25,7)),
 ),o(
  pos=v(0,117),
  label=o(o(8,7)),
 ),
]])
hudbtns[1].click=function()
 g_economy.month=1
 g_economy:new_year()
end
hudbtns[2].click=research_menu
hudbtns[2].new_tick=function(self)
 self.label=label({
  #available_techs()>0 and 24 or 37
 })
end
hudbtns[3].click=function()
 g_game.display_score=true
 uioverlay(score_toggle)
end

------------------------------
-- settings menu
------------------------------

settings=ob([[
 o(label=o(31,"restart     ")),
 o(label=o(42,"toggle music")),
 o(label=o(40,"toggle sfx  ")),
 o(label=o(26,"how to play?"),gpio_hook=5,),
 menu_pos=v(0,107),menu_step=v(0,-11),
 menu_draw_order=14,
]])
hudbtns[4].click=function()
 for i,fn in pairs({
  _init,
  function() music(-sgn(stat(20))) end,
  function() sfx_off=not sfx_off end,
  function() end
 }) do
  settings[i].click=fn
 end
 menu(settings,settings)
end

------------------------------
-- fancy endgame stuff
------------------------------

ascender=lab:extend([[
 tags=o("ascender","planet","node","prober"),
 req="ascension",
 building=2,lab=f,
 name=o("ascension gate",c=13),

 cost=60,
 s=166,

 pspd=0.12,linger=9,
 arms=5,vrot=1,
 generation=0.5,
 colors=o(1,13,12,12,12,13,13,5,1,1,1),
 displacement=7.5,
 mxx=0.98,myx=-0.07,
 mxy=0.07,myy=0.98,
]])
 ascender.init=psys_init
 ascender.point=wormhole.point

 function ascender:render(p)
  if self.level and self.level>=2 then
   psys_render(self)
  end
  planet.render(self,p)
 end

star=ascender:extend([[
 classname="star",
 tags=o("planet","node","prober"),
 building=3,name=o("protostar",c=13),
 state="owned",s=98,

 pspd=0.06,linger=9,
 arms=8,vrot=f,
 exp_d=v(1,0),
 displacement=2,
 generation=1,
 colors=o(1,2,4,9,10,7),
 mxx=1.02,myx=-0.0525,
 mxy=0.0525,myy=1.02,
]])
 function star:init()
  explosion(ob([[
   mxx=0.97,myx=-0.1255,
   mxy=0.1255,myy=0.97,
   colors=o(1,2,8,14,14,14,14,8,8,2,2,1,1),
   squeeze=-0.009,pspd=9,force=1.5,
  ]],{pos=self.pos+self.exp_d}))
 end

synth=ascender:extend([[
 tags=o("planet","node","prober"),
 req="void synthesis",
 building=5,s=66,name=o("synthesizer",c=13),
 cost=40,
 supplies=o(28,20,21,22),
 pspd=0.12,linger=9,
 arms=5,vrot=1,
 generation=0.3,
 colors=o(1,1,5,5,3,3,3,5,5,1),
 displacement=5,
 mxx=0.98,myx=-0.07,
 mxy=0.07,myy=0.98,
]])
 function synth:accept(sw)
  local cp=sw:counterpart(self)
  for i in all(cp.inputs) do
   if i.satisfied==0
    and contains(self.supplies,i.res) then
     self.output.res,self.supplies=
      i.res,{}
   end
  end
  planet.accept(self,sw)
 end

thub=lab:extend([[
 tags=o("planet","node","prober"),
 req="trade league",lab=f,thub=1,
 building=6,s=68,name=o("trading hub",c=13),
 cost=20,plt=15,
 replacement_resources=o(28,48,18,20,21,22),
]])
 function thub:owned(t)
  float(self,t)
  if self.level>=2 then
   self.plt=8+t%42/6
  end
 end

------------------------------
-- exploding planets
------------------------------

explosion=planet:extend([[
 classname="explosion",
 tags=o(),
 standard=f,
 current_exports=o(),
 hitbox=b(0,0,-1,-1),
 draw_order=3,
 generation=0,
 mxx=0.9,myx=0,
 mxy=0,myy=0.9,
 colors=o(1,2,4,9,9,10,10,7,7,7,7,7),
 squeeze=-0.06,pspd=6,force=3,
]])
 function explosion:init()
  psys_init(self)
  psys_spawn(self,140)
  g_cam.shake=3
 end
 function explosion:point()
  local mag=rnd(1.5)+0.5
  if (rnd()<0.6) mag=flr(mag/0.5)*0.5
  local p=mav(mag,rnd())
  return {
   p=p,v=p*self.force,
   a=p*self.squeeze,
   l=rnd(self.pspd)+self.pspd
  }
 end
 function explosion:render(p)
  local pt
  for i=1,3 do
   pt=self.pts[i]
   if pt then
    circ(p.x,p.y,pt.p:len(),self.colors[flr(pt.l/2)])
   end
  end
  psys_render(self)
  self.done=not pt
 end

------------------------------
-- processors
------------------------------

proc=lab:extend([[
 tags=o("planet","node","prober"),
 building=4,name=o("processor",c=13),
 lab=f,s=100,
 cost=15,
 income_m=0.5,
]])

------------------------------
-- slipgates
------------------------------

gate=lab:extend([[
 tags=o("gate","node","prober"),
 cost=10,time_cost=1,
 hitbox=b(-4,-4,5,5),
 s=170,
 sprites=o(170,170,170,168),
 safe_radius=0.01,
 req="slipgates",
]])
 function gate:dropping(s)
  return s.src~=self and #self.ways<3
 end
 function gate:ldown()
  return self:dropping({}) and slipway({src=self})
 end
 function gate:new_tick()
  self.s=self.sprites[#self.ways+1]
 end
 function gate:consider_offer(offer)
  local t=offer.t
  for w in all(self.ways) do
   if offer.count>0 and not contains(t.via,w) then
    -- let the other side of
    -- the connection consider
    local new_offer=clone(offer)
    new_offer.t=t:append(self,w)
    w:counterpart(self):consider_offer(new_offer)
    -- copy counter to reflect
    -- changes upstream
    offer.count=new_offer.count
   end
  end
 end

infragate=gate:extend([[
 infra=1,
 req="infraspace",
 cost=25,
 s=78,sprites=o(78,78,78,76),
]])

------------------------------
-- camera
------------------------------

cam=entity:extend([[
 v=v(0,0),
 shake=0,
 p=v(192,192),
 pos=v(192,192),
 dirs=o(v(-1,0),v(1,0),v(0,-1),v(0,1)),
]])
 function cam:idle()
  local desired=v(0,0)
  for b=0,3 do
   if btn(b) or btn(b,1) then
    desired+=self.dirs[b+1]*3
   end
  end
  self.p+=self.v
  self.v+=(desired-self.v)*0.2
  self.p.x=mid(-64,320,self.p.x)
  self.p.y=mid(-64,320,self.p.y)
  self.pos=shake(self.p,self)
 end
 function cam:apply(magnitude)
  local cp=self.pos*(magnitude or 1)
  camera(cp.x,cp.y)
 end

------------------------------
-- starting screen
------------------------------

main_menu=wormhole:extend([[
 draw_order=10,pos=v(64,28),
 menu_pos=v(34,56),
 menu_draw_order=11,
 menu_step=v(0,11),
 menu_sound=-1,
 non_modal=1,
 generation=5,
 colors=o(0,1,1,2,4,9,10,9,4,2,1,1,1),
 mxx=1.02,myx=-0.007,
 mxy=0.007,myy=1.02,
 arms=5,displacement=15,
 pspd=0.0067,vrot=1,
 linger=17,
 hitbox=b(-40,78,40,98),
 ptr=11,gpio_hook=5,
 tpl=o(
  o(192,0,11,16,4,fn="s"),
  o(172,20,107,2,2,fn="s"),
  o("need help?",40,110,13,fn="psh"),
  o("slipways.net/help",40,116,5,fn="psh"),
 ),
]])
 main_menu.is_under=std_under
 function main_menu:init()
  for i,d in pairs(difficulty_levels) do
   d.click=start_game
  end
  menu(self,difficulty_levels)
 end
 function main_menu:render(p)
  psys_render(self)
  draw_from_template(self.tpl)
 end

------------------------------
-- adaptive music
------------------------------

loop_table=ob([[
 2,2,5,5,7,7,10,10,14,14,14,19,19,19,
]])
function music_adapt()
 local ps=#filter(entities_tagged.planet,planet.colonized)/2
 for i,lpat in pairs(loop_table) do
  local addr=0x3101+4*lpat
  poke(addr,peek(addr)%128+(ps<i and 128 or 0))
 end
end

------------------------------
-- initialization
------------------------------

function _init()
 -- clean slate
 init_palettes()
 e_reset()
 -- reinitialize globals
 --  (important for re-entry)
 spawner.next_pos,g_info=
  spawner.initial_pos
 -- show the title screen
 main_menu()
 music(0)
end

function start_game(diff)
 g_difficulty=diff
 -- reset entities
 e_reset()
 -- background
 bg()
 -- create map
 generate_planets(90)
 g_economy,g_game=economy(),game()
 -- create hud
 each(hudbtns,button)
 local buyables={
  lab,proc,gate,infragate,
  thub,synth,ascender
 }
 for i,b in pairs(buyables) do
  spawner({
   entity=b,
   tooltip=tooltip(structure_tt[i])
  })
 end
 -- kickstart
 g_economy:update()
end

function _update60()
 e_update_all()
 g_ui:update()
end

function _draw()
 cls()
 set_palette()
 r_render_all("render")
 r_render_all("render_hud")
 --print(stat(24).."/"..stat(20),0,11,2)
 --print(stat(1),0,10,8)
end
-->8
-- economy

------------------------------
-- difficulty levels
------------------------------

difficulty_levels=ob([[
 o(label=o(49,"forgiving   "),name="forgiving",
  trade=7,ptype_bias=-0.99),
 o(label=o(50,"reasonable  "),name="reasonable",
  trade=6,ptype_bias=-0.6),
 o(label=o(51,"challenging "),name="challenging",
  trade=5,ptype_bias=-0.4),
 o(label=o(52,"tough       "),name="tough",
  trade=4,ptype_bias=-0.2),
]])

------------------------------
-- economy object
------------------------------

economy=object:extend()

function economy:init()
 set(self,ob([[
  cash=100,cash_flow=0,
  science=0,tech_level=1,
  invented=o(),
  month=1,yr=3401,
 ]]))
end

function economy:tick(duration)
 local months=with("time compression",12,15)
 self.month+=duration
 self:update()
 if self.month>months then
  self.month-=months
  self:new_year()
 end
end

function economy:new_year()
 self.cash+=self.cash_flow
 self.science+=self.prod[r.k]+1
 self.yr+=1
 self:update()
 for e in all(entities_with.new_year) do
  e:new_year(self.yr)
 end
 -- logging
 --[[debug]]
 --[[local owned_planets=#filter(entities_tagged.planet,planet.colonized)
 printh("[year "..self.year.."] i:+"..self.cash_flow.." u:-"..empire_upkeep().." s:+"..self.prod[r.k].." "..#(entities_tagged.slipway or {}).."sl|"..slipway_multiplier().." "..owned_planets.."pt")]]
 --[[debugend]]
end

function economy:spend(amount)
 if self.cash<amount then
  floater({"-no money-",8})
  return
 end
 self.cash-=amount
 if amount~=0 then
  floater({delta(-amount,10,"$")})
 end
 return true
end

function economy:update()
 -- calculate new planet levels
 -- and exports until they
 -- stabilize
 repeat
  update_import_export()
 until not update_planet_levels()
 -- additional planet dependent
 -- statistics
 self.prod,self.discounts=
  total_production(),
  tech_discounts()
 -- update planet income
 local planet_total=0
 for p in all(entities_tagged.planet) do
  -- update planet
  p.income=flr(
   planet_income(p)-
   planet_upkeep(p)
  )
  -- sum total
  planet_total+=p.income
 end
 -- update cash flow
 self.cash_flow=flr(planet_total*with("skill implants",1,1.15))
  - empire_upkeep()
 -- update happiness
 self.happiness=
  calculate_happiness()
 -- check for game end
 self.game_end=
  self.yr>=3426 and "final score"
  or self.cash_flow<=0 and self.cash<3 and "bankrupt"
 -- notify
 for e in all(entities_with.new_tick) do
  e:new_tick()
 end
end

-------------------------------
-- production
-------------------------------

function resource_tally(initial)
 local p={}
 for _,res in pairs(r) do
  p[res]=initial
 end
 return p
end

function total_production()
 local p=resource_tally(0)
 for pt in all(entities_tagged.planet) do
  if pt.inputs then
   p[pt.output.res]+=pt.output.count
  end
 end
 return p
end

function tech_discounts()
 local d=resource_tally(1)
 for l in all(entities_tagged.lab) do
  d[l.inputs[#l.inputs].res]-=0.15
 end
 return d
end

------------------------------
-- slipway building
------------------------------

slipway_base_cost,slipway_base_len=
 6,0.0977
function slipway_cost(from,to)
 local cost_factor=
  (#(to.p-from.p)/slipway_base_len)^0.75
 return flr(slipway_base_cost*slipway_multiplier()*max(0.5,cost_factor))
end
function slipway_multiplier()
 return max(
  1,sqrt(#(entities_tagged.slipway or {}))*0.27-0.1
 )
end

------------------------------
-- planet levels
------------------------------

function update_import_export()
 for pt in all(entities_tagged.planet) do
  pt.current_imports={}
 end
 for pt in all(entities_tagged.planet) do
  -- update exports
  pt.current_exports=pt:exports()
  -- update slipways and imports
  for e in all(pt.current_exports) do
   for i,w in pairs(e.via) do
    w.sends_to[e.route[i+1].id]=true
   end
   add(e:to().current_imports,e)
  end
 end
end

function update_planet_levels()
 local changes
 for pt in all(entities_tagged.planet) do
  local new_lv=planet_level(pt)
  if not pt.level or new_lv>pt.level then
   -- check for additionals transitioning from lv 1
   if pt.level==1 and pt.industry.additional_i then
    add(pt.inputs,{res=pt.industry.additional_i})
   end
   -- upgrade level
   pt.level,changes=
    new_lv,true
  end
  -- adjust production
  if pt.level~=0 then
   local prod=pt.industry:prod()
   pt.output.count=
    prod[min(pt.level,#prod)] + -- standard production
    (pt.powered or 0) -- energy boost
  end
 end
 return changes
end

function planet_level(pt)
 -- owned?
 if (pt.state~="owned") return 0
 -- satisfied demands?
 local missing=1
 for i in all(pt.inputs) do
  -- how much of this do we import?
  i.satisfied=
   #filter(pt.current_imports,
  		function(im)
	 	  return im.res==i.res
 	  end)
  -- update 'anything missing' flag
  -- if an input isn't satisfied,
  -- it'll end up being 0
  missing*=i.satisfied
 end
 if (missing==0) return 1
 -- hub rules?
 if pt.thub then
  return min(#filter(pt.inputs,function(i)
   return i.satisfied>0
  end),3)
 end
 -- lab rules?
 if not pt.standard then
  local li=pt.inputs[#pt.inputs]
  return li and min(li.satisfied+1,4) or 2
 end
 -- demands satisfied, import/export dependent
 return min(
  4,
  1+mid(#pt.current_exports,
        #pt.current_imports,1)
 )
end

------------------------------
-- upkeeps
------------------------------

upkeep_for=ob([[1,0,1,2,]])
function planet_upkeep(pt)
 return pt.lab
   and #entities_tagged.lab
  or pt:colonized()
   and upkeep_for[pt.level]
  or 0
end

function empire_upkeep()
 local count=#filter(entities_tagged.planet,planet.colonized)
 return flr(0.18*count^2)
end

------------------------------
-- incomes
------------------------------

trade_bonuses=
 ob([[-0.333,0,0.25,0.5,]])
function planet_income(pt)
 -- how much for our exports?
 local total=0
 for e in all(pt.current_exports) do
  local dest=e:to()
  if dest.standard then
   total+=g_difficulty.trade*pt.income_m*(1+trade_bonuses[pt.level]+trade_bonuses[dest.level])
  end
 end
 -- are we making wealth?
 if pt.output.res==r.w then
  total+=pt.output.count*g_difficulty.trade*1.5
 end
 -- done!
 return total
end

-------------------------------
-- scoring
-------------------------------

score_per_level=ob([[0,100,200,400,]])
function scores()
 -- planet score
 local planet_score=0
 for pt in all(entities_tagged.planet) do
  if pt:colonized() then
   planet_score+=score_per_level[pt.level]
  end
 end
 -- income score
 local pop_score=
  g_economy.prod[r.p]*40
 -- tech score
 local tech_score=
  flr((#g_economy.invented*1.2)^2)*10
 -- total
 local total=flr((
  planet_score+
  pop_score+
  tech_score
 )*0.01*g_economy.happiness)
 -- return
 return {
  planet_score,
  pop_score,
  tech_score,
  g_economy.happiness.."%",
  total,
  min(flr(total/2000),5)
 }
end

-------------------------------
-- happiness
-------------------------------

happiness_for=ob([[-5,0,1,1,]])
function calculate_happiness()
 local h=100+2*(
  g_economy.prod[r.h]+
  g_economy.prod[r.w]
 )
 for pt in all(entities_tagged.planet) do
  if pt:colonized() then
   h+=happiness_for[pt.level]
  end
 end
 return h
end
-->8
-- planets, resources, industry

------------------------------
-- resources
------------------------------

r,r_names=ob(--[[stash]][[
 f=28,o=21,
 b=18,p=19,
 g=48,t=22,
 l=20,
 w=12,k=24,
 ?=36,a=33,
 e=54,h=25,
]]--[[stashend]]),ob(--[[prot]]--[[stash]][[
 28="food",21="ore",
 18="bots",19="people",
 48="goods",22="tech",
 20="organics",
 12="luxury",24="science",
 54="energy",25="joy",
]]--[[stashend]]--[[protend]])

------------------------------
-- base planet types
------------------------------

planet_kinds=ob([[
 o("boring",45,0,state="boring"),
 o("e",160,4.5,"earth-like"),
 o("f",128,6,"forgeworld"),
 o("m",134,4,"mineral"),
 o("o",130,3,"ocean"),
 o("r",140,2.5,"remnant"),
 o("x",162,3,"xeno"),
 o("j",136,2,"jungle"),
 o("i",138,2,"iceball"),
 o("s",142,2,"barren"),
 o("g",96,4,"gas giant"),
]])
foreach(planet_kinds,read_def(planet_kinds,ob([[
 "name","s","r","d",
]])))

profiles=ob(--[[stash]][[
 f-=o(0,1,2,3,after="f+"),
 f+=o(0,2,3,4),
 -=o(1,2,3,after="+"),
 +=o(2,3,4),
 lab=o(0,1,3,5,after="lab+"),
 lab+=o(0,2,5,8),
]]--[[stashend]])

industries=ob(--[[stash]][[
 o("","",0,"lab","p?","k","superhuman ai"),
 o("","",0,"f+","p","h"),
 o("","",0,"-","","e"),
 o("","",0,"f-","l","f","xenofoods"),
 o("","",0,"f-","","?"),
 o("","",0,"f-","??","w",f,"?"),
 -- factories
 o("nanotech","f",8,"-","o","t"),
 o("bots","f",8,"+","ot","b"),
 o("goods","f",10,"+","ob","g"),
 o("gadgets","f",10,"+","ot","g"),
 -- people
 o("hiveworld","e",5,"+","f","p",f,"g"),
 o("colony","o",10,"-","of","p","gene rewriting","g"),
 o("colony","x",10,"-","tf","p","gene rewriting","g"),
 -- mines
 o("mine","m",5,"-","p","o"),
 o("strip","r",5,"-","pf","o"),
 -- food
 o("agroworld","e",5,"-","b","f","xenofoods","l"),
 o("algae","o",8,"-","b","f","xenofoods","l"),
 -- life
 o("breed","o",5,"+","p","l"),
 o("breed","x",5,"-","b","l"),
 o("hunt","j",5,"-","p","l"),
 -- tech
 o("dismantle","r",5,"-","pf","t"),
 o("scavenge","r",5,"-","pf","b"),
 -- luxury
 o("tourism","j",10,"f-","pg","w"),
 o("luxury","e",10,"f-","tg","w"),
 -- gated stuff
 "xenofoods",
  o("farm","xj",10,"-","b","f",f,"l"),
 "geneseeds",
  o("habitat","si",12,"-","lf","p",f,"g"),
  o("genefarm","si",12,"-","lb","f"),
 "drillbots",
  o("excavate","m",12,"+","b","o"),
  o("excavate","ig",12,"-","b","o"),
 "gene rewriting",
  o("uplift","f",20,"-","l","p"),
 "replication",
  o("mechanize","mrsoijx",20,special=38,turn_into="f"),
 "biome hacking",
  o("terraform","xisoj",20,special=39,turn_into="e"),
 "starbirth",
  o("collapse","gm",30,special=41,replaces_with="star",snd=45),
 "geoharvesting",
  o("harvest","efmorxjisg",-20,special=23,replaces_with="explosion",snd=46),
]]--[[stashend]])

-------------------------------
-- buildings
-------------------------------

function matching_buildings(planet)
 return filter(buildings,function(b)
  if tech(b.req) then
   local match
   each_char(b.pkind,function(k)
    match=match or k==planet.kind.name
   end)
   return match
  end
 end)
end

building=object:extend([[
 props=o("name","pkind","base_cost","profile","i","o","upgrade","additional_i"),
 res_props=o("o","additional_i"),
 separator=o(f,2),
]])
 function building:init()
  read_def(buildings,building.props,building.res_props)(self)
  if self.special then
   self.label={self.name,32,{self.special,8}}
  end
  self.i=each_char(self.i or "",function(c)
   return {res=r[c]}
  end)
 end
 function building:label()
  local l=
   planet.make_label(
    self.i,self.o,
    max(self:prod()[1],1),
    0,1
   )
  add(l,building.separator)
  add(l,self.name)
  return l
 end
 function building:tooltip()
   if (self.special) return
   local it
   for i in all(self.i) do
    it=(it and it.."," or "")..r_names[tostr(i.res)]
   end
   return {{it,13,r_names[tostr(self.o)]}}
 end
 function building:prod()
   local bef=profiles[self.profile]
   return self.upgrade and tech(self.upgrade)
    and profiles[bef.after]
    or bef
 end
 function building:cost()
  local cost=self.base_cost
  if self.upgrade and tech(self.upgrade) then
   cost*=1.5
  end
  if not self.special and tech("nanomaterials") then
   cost*=0.85
  end
  return flr(cost)
 end

buildings,req={}
for def in all(industries) do
 if type(def)=="string" then
  req=def
 else
  def.req=req
  add(buildings,building(def))
 end
end

-------------------------------
-- structure tooltips
-------------------------------

structure_tt=ob(--[[prot]]--[[stash]][[
 o(
  o("-lab-",c=9),
  o("makes",24,"science when supplied"),
  o("with",19,"and any resource"),
  o("adding more of that resource"),
  o("increases output"),
 ),
 o(
  o("-food processor-",c=9),
  o("converts",20,"into",28),
 ),
 o(
  o("-slipgate-",c=9),
  o("connects up to 3 slipways"),
 ),
 o(
  o("-infragate-",c=9),
  o("connects up to 3 slipways"),
  o("routes through infragates"),
  o("can cross other slipways"),
 ),
 o(
  o("-trading hub-",c=9),
  o("generates",25,23,"once you connect"),
  o("2 or 3 different resources"),
 ),
 o(
  o("-synthesizer-",c=9),
  o("can provide",28,20,21,22),
  o("to a planet that needs it"),
 ),
 o(
  o("-ascension gate-",c=9),
  o("accepts",19,"and turns them"),
  o("into",25,"happiness"),
 ),
]]--[[stashend]])--[[protend]]

-->8
------------------------------
-- technologies
------------------------------

techs=ob(--[[prot]]--[[stash]][[
 o("space folding",1,"t",4,
  o("longer range",
    "on slipways and probes")),
 o("geneseeds",1,"l",5,
  o(o("use",102,105,"planets"),
    o("to settle",19,"and farm",28))),
 o("nanomaterials",1,"o",6,
  o(o("colonizing planets"),
    o("becomes 15% cheaper"))),
 o("drillbots",1,"b",7,
  o(o("build mines using",18),
    o("on",106,105,110,"planets"))),

 o("xenofoods",2,"l",10,
  o(o("allow farming",28,"on",107,108),
    o("improve",28,"output of",103,104,119))),
 o("slipgates",2,"t",12,
  o(o("build",109,"slipgates"),
    o("to extend your slipways"))),
 o("geoharvesting",2,"o",14,
  o(o("destroy empty planets"),
    o("for an instant 20",23,"boost"))),
 o("trade league",2,"t",16,
  o(o("build",120,"trading hubs to"),
    o("turn 2-3 different resources"),
    o("into",25,"happiness and",23,"money"))),
 o("replication",2,"b",18,
  o(o("turn any of",102,104,105,106,107,108),
    o("into",118,"forgeworlds"))),

 o("autoassemblers",3,"b",19,
  o(o("colonizing planets"),
    o("takes 2 months instead of 3"))),
 o("skill implants",3,"b",22,
  o(o("earn 15% more",23,"income"),
    "from trade")),
 o("starbirth",3,"o",25,
  o(o("collapse",110,106,"into stars"),
    o("to make",54,"that fills any need"),
    o("and increases production"))),
 o("biome hacking",3,"l",28,
  o(o("terraform",102,104,105,107,108),
    o("into",103,"earth-like worlds"))),
 o("infraspace",3,"t",31,
  o(o("build",121,"infragates"),
    o("that let slipways pass"),
    o("under other slipways"))),

 o("superhuman ai",4,"t",34,
  o("labs now generate",
    o("2/5/8",24,"based on level"))),
 o("void synthesis",4,"o",38,
  o(o("build synthesizers"),
    o("that create",28,20,21,22))),
 o("gene rewriting",4,"l",42,
  o(o("colonies yield more",19),
    o("you can uplift",20,13,19),
    o("using",118,"forgeworlds"))),
 o("time compression",4,"b",46,
  o(o("adds 3 months to each",15,"year"))),
 o("ascension",4,"a",50,
  o(o("build",127,"ascension gates"),
    o("to turn",19,"into",25,"happiness"))),
]]--[[stashend]])--[[protend]]

foreach(techs,read_def(
 techs,
 ob([["name","lv","kind","cost","desc",]]),
 {"kind"}
))

-------------------------------
-- research in economy
-------------------------------

lv_advance=ob([[2,4,7,12,]])

function economy:invent(t)
 self.science-=tech_cost(t)
 add(self.invented,t.name)
 -- progressing through tech levels
 if self.tech_level<4
  and #self.invented>=lv_advance[self.tech_level] then
   self.tech_level+=1
 end
 -- update to refresh stuff
 -- based on new tech
 self:update()
end

function available_techs(regardless_of_cost)
 return filter(techs,function(t)
  t.affordable=tech_cost(t)<=g_economy.science
  return t.lv==g_economy.tech_level
   and not tech(t.name)
   and (t.affordable
        or regardless_of_cost)
 end)
end

-------------------------------
-- tech logic
-------------------------------

function tech(name)
 return not name or contains(g_economy.invented,name)
end

function with(name,before,after)
 return tech(name)
  and after or before
end

function tech_cost(t)
 return flr(t.cost*max(0.55,
  g_economy.discounts[t.kind]))
end
-->8
-- collision math

-- these functions are simplified
-- to only work in the cases
-- where they're needed
-- they're not general and
-- won't necessarily work
-- in corner cases
function segments_cross(p1,p2,q1,q2)
 local oq1,oq2,op1,op2=
  orientation(p1,p2,q1),orientation(p1,p2,q2),
  orientation(q1,q2,p1),orientation(q1,q2,p2)
 return oq1 and oq2 and op1 and op2
  and oq1~=oq2 and op1~=op2
end

function orientation(a,b,c)
 local slopes=
  (b.y-a.y)*(c.x-b.x) -
  (b.x-a.x)*(c.y-b.y)
 return slopes~=0 and sgn(slopes)
end

function segment_crosses_ball(a,b,c,r_squared)
 local d=b-a
 local cproj=d:dot(c-a)/#d
 return cproj>0.01
  and cproj<0.99
  and #(a+d*cproj-c)<r_squared
end
__gfx__
00000000000000003000000300000003307700033007700330000033333333330000000333000033331133333305033333330303333333333333333333000333
111000211111111130488803077766033077000330700a03050d0503333003330ddd55033076760331551333330703333330e0e0333003333300033330666033
2211002122222222304882030dd555033066570330a00a0300c7c003330760330000000330777760157c50330007000333008880000090333006003306757d03
333110213333333330400003066d0d03306656030a0330a00d777d03dd0660dd0dd555030767776015cc5033076776d030aa08030999ff033066603306557d03
42211021444444443020113305511103306656030a03309000c7c00311500511000000033077776031551033307777600a44a033000090333006003306777d03
5511102155555555302033333333333330dd5d0309033090050d0503330650330dd55503330776033300050333077603094a9033333003333300033330ddd033
66d51085666666663333333333333333333333333333333330000033333003330000000333000003333330333307760330990333333333333333333333000333
776d108d777777763333333333333333333333333333333333333333333333333333333333333333333333333300000333003333333333333333333333333333
88221021a00490903033303333000333330003333300033330000033330003333300033330030033000000033333333330003333333333333333333333000333
942210219a0049000d0005030007000330ddd033307e20330076100330aaa0333077903307e07e03077777033333333307a00033300300333333303330888033
a942108509a0049000d050030f888f030d77b5030ae221030f7d1a030a4449030777a9030e88e80307ddd7033333d3d30a407a033080803333330b0308008203
bb3310854049002007776d03008820030d7bb5030e22e103047d12030a49a90309aa9903028882030777770333333d3330904403330803330030b00308080203
ccd51021240490000d6d6d0330dd50330dbb5033302e22030f6d1a03094aa903309990333028203307ddd7033333d3d33309403330202033070b003308800203
d5511021dddddddd06666d0330d050333055033333012003005510033099903330d55033330203330666660333333333330403333003003330b0033330222033
ee82108504909a000000000330000033330033333330003330000033330003333000003333303333000000033333333333000333333333333300333333000333
f9421085004909a03333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333300000333300333333333333330003333300033333000003330000033330033330001003330000330000000000000000001111100000000000000000
33300333050d0503307033330033333330dd003330ddd03330756d1330ab5d130007033304249403330a90330001110000000000011000110000000000000000
0000503300c7c003077000330d0333333000d0330d773d030757dd130bb5cd1307660633029aaa13330900330015551000000000110110011000000000000000
015555030d777d037777603305503333300500330d333d0306555113055cd5130666033304a7771330090333015dd50100000000101000001000000000000000
0000503300c7c003067000330503333333000333303330330657651306c515130556063319a777230aa90333015d550100000000100000001000000000000000
33300333050d0503306033330033333333050333305110330d56dd130cdbb1130005033304a77723099403330155500100000000100000001000000000000000
33333333300000333300333333333333330003333000003301111113011111133330033300112223300033330010001000000000110000011000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333330001110000000000011000110000000000000000
33000003333333333333333333333333311133331111133330000033330003333330333333303333003333330000000000000000001111100000000000000000
3049940333333333311133331111133330703333171a13330209020330adc0333307033333020333060333330000000000000000000000000000000000000000
044449033111333330a03333070a0333111113331100033300a7a0030ab5cd030077a00000221000076033330000000000000000000000000000000000000000
04ff490330a0333330003333000003330a0903330a090333097779030d5ccd037777aaa022221210077603330000000000000000000000000000000000000000
04ff4403300033333090333350905333000003330000033300a7a0030ccc5b0309aaa90301111103077760330000000000000000000000000000000000000000
0444403335553333300033333000333350905333509053330209020330ddb03307949a0302101103000700330000000000000000000000000000000000000000
00000333333333333555333335553333300033333000333330000033330003330a000a0301000103330060330000000000000000000000000000000000000000
33333333333333333333333333333333355533333555333333333333333333330033300300333003333000330000000000000000000000000000000000000000
00007000000000000000700000000000015555510000000033003333003333330000000000000000000000000000000000017100000000000001710000000000
007561d000000000007561d0000000001566dd55100000003055333355033333000000000000000000100000000000000001d100000000000001d10000000000
076511d500000000076511d500000000115555511000000005553333555033330000000000000000000000000000000001000001000000000100000100000000
0512221100000000051111110000000005111115000000000555333355503333000100000000000000000000000000006502220560000000650ccc0560000000
002eae2000000000001b7b10000000001607060d000000000555333355503333000000000000000000000000000000000502880500000000050c770500000000
0089798000000000013777310000000051777661100000000555333355503333000000000000000000000000010000000002880000000000000c770000000000
0089a98000000000013a7a31000000005d1111151000000005553333555033330000000000000000000000000000000005700075000000000570007500000000
008e7e8000000000003b7b300000000015dd55511000000005553333555033330000000000000000000000000000000000105050000000000010505000000000
070222050000000007055505000000001c55551b1000000005553333555033330000000001000000000000000000000000000000000000000000000000000000
076616d500000000076616d50000000001ef89a10000000005553333555033330000001000000000000000000010000000000000000000000000000000000000
00650d500000000000650d5000000000001111100000000005553333555033330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000030553333550333330000000000000000000000100000001000000000000000000000000000000000
00000000000000000000000000000000000000000000000033003333003333330000000000000100100000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000033333333333333330000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000033333333333333330100000000000000000000000000100000000000000000000000000000000000
00000000000000000000000000000000000000000000000033333333333333330000000000000000000000000000000000000000000000000000000000000000
0001222101000000000001000000000000076d000000000031244403315abd03315ddd0331155503311222033015550330555503306660333000000330ddd033
0024f9e2101000000200020002000000007000d00000000014ffff0315ab5c031dcccc031577760312eee80305babd030577770306000d03221010030d000503
01499e44212000000042494240000000d707000d500000002ff77f035ab5cd035cc77c03177777031e8821031bddbb03577bbb0370ccc0509e210203d0d50050
02efffe4490000000029aaa920000000d711111d500000004f79f903555cdd03dc77cc03577676031228ee035abdba0357bbb60370c77050e4421403d0500050
02ef9ee7a0000000104a777a4010000050ddddd0500000004fffff035cc55d03dccccd0357776d03128e88035bdadd0357b6bb0370c77050fe449003d0000050
4249977f21000000529a777a9250000010000000100000004f9f99035cdbb5035cdcdd035776660328e822035dbd5d0357bb660306000503ee7a000305000503
09a7aa9421000000004a777a40000000003bb3300000000000000003000000030000000300000003000000030000000300000003305550330000000330555033
00224422100000000759aaa91d000000000311000000000033333333333333333333333333333333333333333333333333333333330003333333333333333333
000222210000000000725552600000000000000000000000301555033076d003366ddd03301d1003000000000100000010000000000000000000000030d0d503
00000000000000000100676001000000000000000000000005756d0307000d03d55555031000001300000101100110000000000000000000000001000c000503
0000000000000000000001000000000000000000000000001757dd03707000d3d111110350ccc053000100100011000110011000000110000100000050000003
00000000000000000000000000000000000000000000000056555103711111d36070600350c770530010010001100000001001001010001000011000000c0003
000000000000000000000000000000000000000000000000565765030ddddd037777660300c77003001000000100000000100000001000010111000050c77003
0000000000000000000000000000000000000000000000005d56dd0300bb5003d111110357000753000100000000000100010010000100000100000050070003
00000000000000000000000000000000000000000000000000000003000000030000000301050503010000000000000000000100000000000000001000000003
00000000000000000000000000000000000000000000000033333333333333333333333333333333100000000000010000000010000000000000000033333333
0015551000000000005ddd50000000000000000000000000001222100000000000155510000000000015551000000000005dd410000000000024441000000000
05756d51000000000dccccd500000000000000000000000002eee8210000000005bab3b10000000005777651000000000d565f410000000004ffff4100000000
1757dd15100000005cc77cc51000000000000000000000001e882110000000001b33bb3500000000177777650000000057d55f94000000002ff77f9400000000
565551d510000000dc77ccd51000000000000000000000001228ee82100000005ab3ba5510000000577676d510000000d655f944100000004f79f99410000000
5657655510000000dccccdc5100000000000000000000000128e8822100000005b3a33311000000057776dd510000000d5ff9472100000004fffff9210000000
5d56dd15100000005ccddc5510000000000000000000000028e822121000000053b3535110000000577666d51000000049994755100000004f9f994210000000
15d56551100000001ddcd551000000000000000000000000188282210000000013353511000000001566dd510000000014426d110000000014f9942100000000
01555511000000000155551000000000000000000000000001222210000000000155111000000000015555100000000001222510000000000144221000000000
00111110000000000001110000000000000000000000000000011100000000000001110000000000000111000000000000011100000000000001110000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005abd500000000000533310000000000000000000000000000606d010000000050070050000000005007005000000000000000000000000000dd50000000000
03ab3cd500000000037777b1000000000242022000000000070d0d550100000000056100000000000005610000000000000000e8820000000007760000000000
5ab3cdd5100000005777bb3d0000000027f92ff20000000000c00050c0100000006000d000000000006000d000000000000000ea820000000d07760500000000
b33cddb310000000377bb6b3100000004f94ff9410000000d500000c001000000702220600000000070ccc060000000000000022220000006dd06055d0000000
dcc55d111000000037b6bb331000000049427422100000000000c000501000000702e80600000000070c77060000000000000067cd00000076001006d0000000
5cdbb5551000000037bbbd35100000004f97f94210000000d50c770d501000000702880600000000070c7706000000000000cd5c5dcd00000667776d00000000
1ddb3b31000000001bbd33510000000014f4422100000000d500700d501000000060006000000000006000600000000000000dc6c5d000000066666000000000
0151331000000000013351100000000001442100000000000500000d010000000d0ddd0d000000000d0ddd0d00000000000000c6c50000000600000d00000000
000111000000000000011100000000000001100000000000000d55000000000000001000000000000000100000000000000000cdc50000000066ddd000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ea8060d08a82000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001220701d02222000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008110c010d0000100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008821000000211100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008821900109221100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008221401104221100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002110200002110000000000000000000
33333333333333333333333333333333333333333333333333333333333499994923333333333333333333333333333333333333333333333333333333333333
333333333333333333333333333333333333333333333333333333334aa999949444423333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333334aaa4000000024444233333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333aa4000000000000024423333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333aa00000000000000000442333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333344000000000000000000044233333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333000000000000000000000002203333333333333333333333333333333333333333333333333333
33333333333333000000000000000000000033000000000000000000000000000000000000000000000000000000333000000300000000003333333333333333
3333333333333007777777766600777d000033077770077761777d00007750000000077500000777766d000777d03330776d000766ddddd00333333333333333
33333333333300776ddddddddd00776d0100330777d07776505666d0007750000000077d0000766ddd66d00666d033306ddd106dd55555550333333333333333
3333333333330776d0000000000776d01003300766d076650006666d057650000000076d000666d000d66d066dd003300ddd50dd500000000333333333333333
333333333330011000111111100766d0100330766d0666501110666d0d6650000000066d100ddd00110ddd00ddd503330ddd5011101111110333333333333333
333333333330777d0000000000666d01003330666d01110000001110066d500000000d6d5011000100011100ddd5003300ddd50dd60000000003333333333333
3333333333307666666666d000666d0100330011100775000000777507dd10007600056d50665010000076500ddd5000006dd500dd6666dddd00033333333333
3333333333300555555566650111001003330777607665000007665007d50007dd50006d507d500000007dd50ddd5177617dd5010ddddddddd51003333333333
3333333333301000000056650776501003330766d07666661676d5010655007dddd500d5507dd67716776dd500dddd16d51dd500100000000555100333333333
3333333333300111111011107665010033300766506ddd5505551011011106dd5ddd5011107ddddd16dddddd5005551dd5155000011111111011100033333333
3333333300000000000776507665000000006dd506ddd5000000011006656dd500ddd5dd10d55555055555dd5000000ddd50010000000000000d551033333333
333333300777777777766506ddd6777766506dd506dd50155055110006dd5550110d555510d5100000000055510155155d50010330ddddddddd5551033333333
333333007666d6dddddd5006dddddddddd506dd506dd50111011100006555101111055551055101110111055510011105551000330d555555555551033333333
3333330655555555555501d555555555555055550555500000000000055110110011011110111011101110111100000011110033301111111111110033333333
33333300000000000000110000000000000000000000000000000000000001100001100000000000000000000000000000000033300000000000001033333333
33333301000010111111101111515155555055550555503300000000055151000000111110111000000000111100333011110333301111110100001033333333
33333301000101111111001111111111111011110111103332000000011110000000011110111000000000111100333011110333301111101000010033333333
33333300000000000000000000000000000000000000003334400000000000000000000000000003333300000000333000000333300000000000000033333333
33333300000000000000000000000000000000000000003333440000000000000000000000000003333300000000333000000333300000000000000033333333
33333333333333333333333333333333333333333333333333344000000000000000000011133333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333332200000000000000000222333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333222000000000000012223333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333312221000000012222133333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333122222222222213333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333122222213333333333333333333333333333333333333333333333333333333333333
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888eeeeee888777777888eeeeee888eeeeee888eeeeee888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88ee88eee88778887788ee888ee88ee8e8ee88ee888ee88888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee8eeee8eee8777778778eeeee8ee8eee8e8ee8eee8eeee88888e88888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8eeee8eee8777888778eeee88ee8eee888ee8eee888ee8888eee8888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee8eeee8eee8777877778eeeee8ee8eeeee8ee8eeeee8ee88888e88888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee8eee888ee8777888778eee888ee8eeeee8ee8eee888ee888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee8eeeeeeee8777777778eeeeeeee8eeeeeeee8eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888
5555555555555d5d5d5d5d5d5d5d55d55d5d5d555d555d5555555555555555555555555555555555555555555555555555555555555555555555555555555555
5ddd5ddd55555ddd5ddd5ddd5ddd55d55d5d5dd55ddd5ddd55555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555d5d5d5d5d555d5555d55d5d5d55555d555d55555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555d5d5d5d5d555d555ddd5d5d5ddd5dd55dd555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5ddd5555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
565656665666566656665665566655665566555556665566566655555566566655755cc55cc555555ccc55555ccc55555cc555555cc5555555cc55cc55755555
565656565656565655655656565556555655555556555656565657775656565657555c555c5555555c5555555c5c555555c5555555c55555555c555c55575555
566656665666566655655656566556665666555556655656566555555656566557555c555c555ccc5ccc55555c5c555555c5555555c55555555c555c55575555
565656565655565555655656565555565556555556555656565657775656565657555c555c555555555c55c55c5c55c555c555c555c555c5555c555c55575555
565656565655565556665656566656655665566656555665565655555665566655755cc55cc555555ccc5c555ccc5c555ccc5c555ccc5c5555cc55cc55755555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56565666566656665656555556665666556655665656566655665666556655555566566655755cc55cc555555555555555555555555555555555555555555555
56565656565656565656555556565655565556565656565656555655565557775656565657555c555c5555555555555555555555555555555555555555555555
56665666566656665666555556655665566656565656566556555665566655555656566557555c555c5555555555555555555555555555555555555555555555
56565656565556555556555556565655555656565656565656555655555657775656565657555c555c5555555555555555555555555555555555555555555555
56565656565556555666566656565666566556655566565655665666566555555665566655755cc55cc555555555555555555555555555555555555555555555
55558888855555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55558888855555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55558888855555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55558888855555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55558888855555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55558888855555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5ccc5c5c5cc555cc5ccc5ccc55cc5cc5555555cc5ccc5c5555cc5c5c5c555ccc5ccc5ccc55555c5c5ccc5ccc5ccc5ccc5cc55ccc55cc55cc55c555c555555555
5c555c5c5c5c5c5555c555c55c5c5c5c55555c555c5c5c555c555c5c5c555c5c55c55c5555555c5c5c5c5c5c5c5c55c55c5c5c555c555c555c55555c55555555
5cc55c5c5c5c5c5555c555c55c5c5c5c55555c555ccc5c555c555c5c5c555ccc55c55cc555555ccc5ccc5ccc5ccc55c55c5c5cc55ccc5ccc5c55555c55555555
5c555c5c5c5c5c5555c555c55c5c5c5c55555c555c5c5c555c555c5c5c555c5c55c55c5555555c5c5c5c5c555c5555c55c5c5c55555c555c5c55555c55555555
5c5555cc5c5c55cc55c55ccc5cc55c5c555555cc5c5c5ccc55cc55cc5ccc5c5c55c55ccc5ccc5c5c5c5c5c555c555ccc5c5c5ccc5cc55cc555c555c555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555c5555cc55cc5ccc5c5555555c5c55555cc55ccc5ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555
55555c555c5c5c555c5c5c5555555c5c5ccc55c55c5c5c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555
55555c555c5c5c555ccc5c5555555ccc555555c55c5c5c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555
55555c555c5c5c555c5c5c5555555c5c5ccc55c55c5c5c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555
55555ccc5cc555cc5c5c5ccc55555c5c55555ccc5ccc5ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555ccc55cc5ccc55555ccc5ccc55555ccc5cc555555ccc5c555c5555c55ccc5cc55ccc5ccc5ccc5ccc5ccc55cc55555ccc5ccc55cc55cc5ccc5cc555555ccc
55555c555c5c5c5c55555c5c55c5555555c55c5c55555c5c5c555c555c555c555c5c55c555c555c555c55c555c55555555c55c5c5c555c555c555c5c55555c5c
55555cc55c5c5cc555555ccc55c5555555c55c5c55555ccc5c555c555c555cc55c5c55c555c555c555c55cc55ccc555555c55ccc5c555c555cc55c5c55555ccc
55555c555c5c5c5c55555c5555c5555555c55c5c55555c5c5c555c555c555c555c5c55c555c555c555c55c55555c555555c55c5c5c5c5c5c5c555c5c55555c55
55555c555cc55c5c55555c5555c555555ccc5c5c55555c5c5ccc5ccc55c55ccc5c5c55c55ccc55c55ccc5ccc5cc55ccc55c55c5c5ccc5ccc5ccc5ccc55c55c55
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555ccc5ccc55555ccc5ccc555555cc55cc5c5555cc5cc55ccc5ccc5ccc5cc555c555c555555ccc5c5c5ccc5cc555555555555555555555555555555555
5555555555c55c5555555c5c55c555c55c555c5c5c555c5c5c5c55c5555c5c555c5c5c55555c555555c55c5c5c555c5c55555555555555555555555555555555
5555555555c55cc555555ccc55c555555c555c5c5c555c5c5c5c55c555c55cc55c5c5c55555c555555c55ccc5cc55c5c55555555555555555555555555555555
5555555555c55c5555555c5555c555c55c555c5c5c555c5c5c5c55c55c555c555c5c5c55555c555555c55c5c5c555c5c55555555555555555555555555555555
555555555ccc5c5555555c5555c5555555cc5cc55ccc5cc55c5c5ccc5ccc5ccc5ccc55c555c5555555c55c5c5ccc5c5c55555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555c5c555555555c5c5ccc5ccc5ccc5ccc5cc55ccc55cc55cc55555ccc55cc5ccc5cc55ccc5ccc55555c555ccc5c5c5ccc5c5555cc555555555555
5555555555555c5c55c55ccc5c5c5c5c5c5c5c5c55c55c5c5c555c555c5555555c555c5c5c5c5c555c5c55c555555c555c555c5c5c555c55555c555555555555
5555555555555ccc5ccc55555ccc5ccc5ccc5ccc55c55c5c5cc55ccc5ccc55555cc55c5c5cc55c555ccc55c555555c555cc55c5c5cc55c55555c555555555555
5555555555555c5c55c55ccc5c5c5c5c5c555c5555c55c5c5c55555c555c55555c555c5c5c5c5c555c5555c555555c555c555ccc5c555c55555c555555555555
5555555555555c5c555555555c5c5c5c5c555c555ccc5c5c5ccc5cc55cc55ccc5c555cc55c5c5cc55c5555c555c55ccc5ccc55c55ccc5ccc55cc555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555ccc5cc55cc5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555c555c5c5c5c555555555555555555555555555555555555555555555155555555555555555555555555555555555555555555555555555555555555
555555555cc55c5c5c5c555555555555555555555555555555555555555555551715555555555555555555555555555555555555555555555555555555555555
555555555c555c5c5c5c555555555555555555555555555555555555555555551771555555555555555555555555555555555555555555555555555555555555
555555555ccc5c5c5ccc555555555555555555555555555555555555555555551777155555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555551777715555555555555555555555555555555555555555555555555555555555
555555555ccc5ccc55555ccc5ccc555555cc5c5c5ccc5ccc5c5c5ccc55555ccc177115cc555555555ccc55555c5c555555cc5ccc55555ccc5ccc555555cc5c5c
5555555555c55c5555555c5c55c555555c5c5c5c55c55c5c5c5c55c555555c5c51171c555ccc5ccc5c5c55555c5c55555c5c5c5c55555c5c55c555555c5c5c5c
5555555555c55cc555555ccc55c555555c5c5c5c55c55ccc5c5c55c555555cc55cc55ccc555555555cc555555c5c55555c5c5cc555555ccc55c555555c5c5c5c
5555555555c55c5555555c5555c555555c5c5c5c55c55c555c5c55c555555c5c5c55555c5ccc5ccc5c5c55555ccc55555c5c5c5c55555c5555c555555c5c5c5c
555555555ccc5c5555555c5555c555c55cc555cc55c55c5555cc55c555c55c5c5ccc5cc5555555555c5c55c55ccc55555cc55c5c55555c5555c555c55cc555cc
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555c5c555555555ccc5c5c5ccc5ccc555555cc5c5c5ccc5ccc5c5c5ccc555555cc55cc5c5c5cc55ccc555555555555555555555555555555555555
5555555555555c5c55c55ccc555c55c55c5c55c555555c5c5c5c55c55c5c5c5c55c555555c555c5c5c5c5c5c55c5555555555555555555555555555555555555
5555555555555ccc5ccc555555cc5ccc5ccc55c555555c5c5c5c55c55ccc5c5c55c555555c555c5c5c5c5c5c55c5555555555555555555555555555555555555
5555555555555c5c55c55ccc555c55c55c5555c555555c5c5c5c55c55c555c5c55c555555c555c5c5c5c5c5c55c5555555555555555555555555555555555555
5555555555555c5c555555555ccc5c5c5c5555c555c55cc555cc55c55c5555cc55c555c555cc5cc555cc5c5c55c5555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555ccc5cc55cc5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555c555c5c5c5c555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555cc55c5c5c5c555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555c555c5c5c5c555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555ccc5c5c5ccc555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555ccc5cc55cc55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555c555c5c5c5c5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555cc55c5c5c5c5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555c555c5c5c5c5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555ccc5c5c5ccc5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555ccc5ccc5ccc5c5c5ccc5cc555555c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555c5c5c5555c55c5c5c5c5c5c55555c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555cc55cc555c55c5c5cc55c5c55555ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555c5c5c5555c55c5c5c5c5c5c55555c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555c5c5ccc55c555cc5c5c5c5c55555c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5ccc5cc55cc555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5c555c5c5c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5cc55c5c5c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5c555c5c5c5c55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5ccc5c5c5ccc55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822282228222888282228222822288888888888888888888888888888888888882228222822282228882822282288222822288866688
82888828828282888888888282828282882888828882828288888888888888888888888888888888888882828282888282828828828288288282888288888888
82888828828282288888882282828222882888228222828288888888888888888888888888888888888882228282888282228828822288288222822288822288
82888828828282888888888282828282882888828288828288888888888888888888888888888888888882828282888282828828828288288882828888888888
82228222828282228888822282228222828882228222822288888888888888888888888888888888888882228222888282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000001000100000000000000000000000000010001000001000000000100000000010101000000000000000000000001000000000000
0002000001000001010000000101010100000000010000000100000000010101000001000101000201000100000000000000010001010000010001000000000000000000000001000201000101000001000000000000010000010000000000010000000000000001000100000000000100010100000000010000000000000001
__map__
00000000000000000000000000000000000000000000000000006c6d0000000000000000b80000bcbf7e6f7e7eb8b8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000004b4a5e005e5f00005f00000000000000b80000000000416d6c6d7c000000000000b80000206f7f6f8c8fb8b80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004f000000000000000000004f
5f0000494a494a00000000000000000000000000848586876c416c848586858700002000b80000007f6f8cacbf8e8e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a0000004f0000004a004c00000000004d0000
000000005a58490000005f000000000000000000b4b5b6b76e416d949595959700000000b800007f7e6f9c8cad000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004f4c4f00004a4c004b4900004e000000480000
00000000005a4b4b00000000005f0000000000006c6c6e6e6d416c949596959700000000b8007f6f7e8cbebfbcad9e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004900004a4849004e004a004c4b4d004900004c
0000000000004b0000005d5d000000000000007d6d6a40406a418494959595978800000000007e7e7e7f6f7f6f9c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000484b00490048004b4d4b0000004800484f4900
00005f000000005d4b4b494a5900004100000084858740407a4194a49595969787000000886f7e6f6f417e6f6f9c9e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a595a004f004a004a00494b4900004849
000000000000004b4b4a5b58585900410000939400974040000000009595959797a3008c8f7f8c8d8f418c8e8e8fbd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a005800005c004a4b595a0048004a00494b00
0000710000005d5a4958585b5b494b41000000a4a5a7008500000000a5949597a70000bcbf8dbcbebf41ac9eaebf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000595a005900005c595b00005a00494b00595a00
000000005f0000594a585b58584a5a410000000000a4a6a5a5a5a70000a4a6a700000000bcbdbf4200419caebf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005800000000005958005c005c585c5a5900005b
005f00000000005d59585b585b494b0000000000000000003400000000000000000000000042005200419c9f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000590000005c000000
000000005f0000005a5949584a5a4b000000000000000000b80000000000697968000000005200520041bcbf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000595800005c0000595a0000005900005a0000
000000000000000000494a494b5d00000000000000000000000000000000000047004300005200620041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005a00000000000000000059005c000000000058
0000007500000000000000000000000000000000000000000000000000000000000053430062000000418c8f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000595800005958000000000000585b005c00
00000000000000000000000000000000000000a20000a20000a200004446470000006353000000000041acaf8f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005a0000000000000000595b00590000000000
000000000000000000000000000000000000000000000000000000005455670000444747000000444741acbfaf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000580000005800000000000000000000
000000000000000000000000000000000000000000000000000000007455555050545657606060546747bcbebf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c000000000000
0000000000000000000000000000000000000079000000000000000000545555555465677070706466570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005800005900000000000000000000580000
00440000000000000000000000800000004446470000000000000000007476767574556578787855767700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005900000000000000005a0000000000000000
0074555577655555657777900000910055747500000000000000000000007477000064555555557700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000747777556555556790000000007465006700000000000000000000000000000074757675770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000007475777476757700004300000074757700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000000000000000005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18000000000000000000005d635f00b800b80069790000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000000000000000444647004500450044470000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000000000000000000000000000000074770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0110001e1f7741f74518774187101a7741a7451f7741f74518711187441a7741a7451f7741f745187741d0161f7741f7451a7741a74518774187451a7741a710227111f77418774187451a7741a7451f7041f705
011000140c174000550c1740c1751f0341f0440c174180550c1000c1000c17400575131451f1350c174000750c1740c1750c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c1000c100
010800200c6150c6050c6150c605186150c6050c6150c605306150c6050c6150c605186150c6050c6150c6050c6150c6050c6150c605186150c6050c6150c605306150c6050c6150c605186150c6050c6150c615
010714200a7700a7700a7700a7700a7700a7700b7710b7700c7710c7700c7700c7700c7700c7700c7700c7700c7700c7700c7700c7700c7600c7600c7600c7600c7600c7600c7600c7600c7600c7600c7600c760
010c10201052511545187501875018750187501875018750187501875018750187501876018760187601876018770187701877018770187601876018760187601876018750187501875018750187501876018760
010716181851018510185201852018530185301854018540185501855018560185601855018550185401854018530185301852018520185101851018514185151850018500185001850018500185001850018500
01051f201853018530185301853018520185201851518530185301853018520185201851518530185301853018520185151853018530185201851518530185201851518520185101852518515185151851518500
0110000518735187101f71218735187152670518705187051f7051f70526705267051f7051f7052670526705267051f70518705187051a7051a7051f7051f7050070500705007050070500705007050070500705
0194000012b4412b350d52512b4412b3012b350dd4512b4412b450652512b4412b4012b450d52512b4412b450d52510b4410b4010b450b53510b4410b451052510b4410b4010b450b52510b4410b4010b4510525
018100201052517c2017c2514d3414d2014d2517d3417d2514c2014c2214c2017d3417d2514c2414c2014c251972417c2417c2514d3414d2014d1517d3417d2514c2014c2214c2517d3417d2514c2014c2014c25
019400201cc141cc101cc1519d3419d251cd341cd201cd1519c2419c2219c251cd341cd2519c2019c2019c25155051cc201cc2519d3419d2019d251cd341cd2519c2019c2219c251cd341cd2519c2419c2019c25
012000090a51511515185150a515115151a5150a515115151a5171a5051d5050e505055050e5050e505005051a5050a505115051a5051a5050a505115051a5050a505115051a5050a5051a5050a505115051a505
0180000010d2500a2016e2400a2016e2400a2000a2000a2016e2000a200fe2000a2016d1000a2016e2000a200fd2400a2016e2400a2016e2400a2000a2000a2016d2400a200fe2000a200ad2000a200fd2000a20
01ac00000cb440cb400cb400cb450cb440cb400cb400cb450cb440cb400cb400cb450cb440cb400cb400cb450cb440cb400cb400cb450cb440cb400cb400cb450cb440cb400cb400cb450cb440cb400cb400cb45
01ac0000107041cb241cb201cb201cb201cb25000001cb241cb201cb201cb201cb25000001cb241cb201cb201cb201cb2510d341cb241cb201cb201cb201cb25000001cb241cb201cb201cb201cb201cb2510d34
01ac000026b041ab0426b2426b2026b2026b2026b251ab0523b2423b2023b2023b2023b2524b0026b2426b2026b2026b2026b2524b0023b2423b2023b2023b2023b2524b002db242db202db202db202db202db25
01ac00001ab0410d442ab242ab202ab202ab202ab251cb00175241752017520175201752518b002ab242ab202ab202ab202ab2518b0026b2426b2026b2026b2026b2518b0021b2421b2021b2021b2021b2021b25
018000002082420810208242081020824208152082420810228242281022824228102282422815228242281020824208102082420810208242081520824208102782427810278242781022824228102282422810
01ac000013b4413b4013b400252513b4413b4013b4013b4513b4413b4013b400252513b4413b4013b4013b4513b4413b4013b4013b4513b4413b4013b400252513b4413b4013b4013b4513b4413b4013b4013b45
01ac0000105051ab241ab201ab201ac201ac2510d341ab141ab101ab101ac201ac2512d341cb141cb101cb101cc201cc2510d341cb241cb201cb201cb201cb2510d341ab241ab201ac201ac201ac201ac2510524
01ac000026b041252426b2426b2226b251ac201ac2510d4423b1417c2017c2017c2217c2217c251ac201ac201ac2526b1426b2026b2517c2017c2523b2423b2023b25125242db242db252ab242ab202ab222ab25
01ac0000105251cb241cb2221b2421b2510d341eb241eb201eb201eb201eb201eb2510d441fb241fb201fb201fb201fb2510d441eb241eb221eb201eb201eb2510d4421b2421b2021b2021b2021b2221b2510524
01ac000026b042db142db151ec201ec201ec221ec251ab052db242db252ab242ab202ab222ab251ac002fb242fb252ab242ab202ab222ab2517c052db242db251ec201ec201ec221ec252ab042db242db202db25
01ac000026b040e50226b1426b1226b101ac101ac151ab0523b1417c1017c1017c1217c1524b001ac101ac101ac1526b1426b1026b1517c1017c1523b1423b1023b15125142db142db152ab142ab102ab122ab15
01ac00000cb440cb4507d350cb440cb400cb450b5250cb440cb450b5250cb440cb400cb450b5250cb440cb40075250cb440cb400cb450e5250cb440cb45075250cb440cb400cb450e5250cb440cb400cb4507525
018000201182400a2024b1400a201482400a2000a2000a201182400a2024b1400a201681500a2000a2000a201182400a2024b1400a201681500a2000a2000a201182400a2024b1400a201681500a2000a2000a20
01ac000010b4410b450b52510b4410b4010b450d52510b4410b451052510b4410b4010b45105250eb440eb40095250eb440eb400eb45105250eb440eb45095250eb440eb400eb450e5250eb440eb400eb4509525
0180032010d2517c2017c250ad200ad200bd200bd200bd2016e2016e200bd200bd200bd2016d2016d200bd200bd200bd2016e2416e200bd200bd200bd2016d2016d200bd200bd200ad200ad200bd200bd2016d20
012000221d5151f515225152451526514295142951524514245102451224515295002e5142e5102e5152950029514295122951229515265142651026512265152b5142e5142e5102e512225142e5142e51529500
018000200db440db45085250db440db400db4508d45015250fb440fb45035250fb440fb400fb450ad450352511b4411b451151511b4411b4011b450cd450552514b4414b450852514b4414b4014b4214b3508525
01400322147141471014710197141b7141b710227142271022710227102271022712227151d71420714207102071020710257142771427710277102e7142e7102e7102e7102e7152c7142c7102c7150fe340fe35
0180032010d1517c1017c150ad100ad100bd100bd100bd100ad100ad100bd100bd100bd1016d1016d100bd100bd100bd100ad100ad100bd100bd100bd1016d1016d100bd100bd100ad100ad100bd100bd1016d10
01800020087250db4508e45010250de440102508d4501125030350fe35031240fb45030240fe350ae250353511b450502511e350502511e34050250cd45051240802514e350802514b4414b4514e3514e2508114
018000201491014910149101492516910169101691016925089100891008910089250a9100a9100a9100a9251491014910149101492516910169101691016925089100891008910089250a9100a9100a9100a925
0110001818a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a1518a0018a0018a0018a0018a0018a0018a0018a00
01800000208242081022824225152282422810278241651529824298102c824275152782427810278241b51529824298102c8242251527824278102782416515208242081022824275152282422810278241b515
018000201391013910139101392516910169101691016925079100791009910099100a9100a9100a9100a92514910149101491014925139101391013910139250891008910089100892507910079100791007925
01800000228242251522824295152282422515278241651522824245151f824265152282422515278241651529824275152c824265152782422515278241651529824275152c8242951527824225152782416515
0180000e0f9100f91011910119101391013910159101591016910169100c9100c9100e9100e9100e9000e9050f9000f9000f9000f905000000000000000000000000000000000000000000000000000000000000
018000102281427814298143381426714227141d7141a7141f7141f710298142e814298142e814267142271429804275052c804265052780422505278041650529804275052c8042950527804225052780416505
0180000e109101091012910129101491014910169101691017910179100d9100d9100f9100f9100f9000f9050f9000f9000f9000f905000000000000000000000000000000000000000000000000000000000000
0180001023814288142a8143481427714237141e7141b71420714207102a8142f8142a8142f814277142371429804275052c804265052780422505278041650529804275052c8042950527804225052780416505
012000090b51512515195150b515125151b5150b515125151b5171b5051e5050f505065050f5050f505015051a5050a505115051a5051a5050a505115051a5050a505115051a5050a5051a5050a505115051a505
012000221ef3020f3023f3025f3027f302af302af3025f3025f3025f3025f3025f35237142371023712237151e7141e7101e7121e7151b7141b7101b7121b7152071423714237102371017f3023f3023f3023f25
0120040d2e5102e5122e5152e5050a51511515185150a515115151a5150a515115151a5171a5051d5050e505055050e5050e50500505000000000000000000000000000000000000000000000000000000000000
010500003f62039620306102424329610162431f6100f24300243035430224305543032430654304243075430524308543072430a543092330c5330a2330d5330b2230e5230c2230f5230d213105130e21311513
010500003f62039620306102424329610162431f6100f2431961009243136100524311610032430e610012430c61001240096100124006610012300461001230026100122002610012200061001210005143d521
0120172038b1438b1038b1038b153db143db103db123db1233b1433b1033b1033b1536b1436b1036b1036b1538f2436f2034f2033f2031f2036f2233f2523f2023f202af202af2231f2033f202af202af202af20
0103000022625001450d6250414500234004450024401425012340144402224024350224403425032340344504224044350424404234044250422404224044150421408405082040840508204084050820408405
010700003003030020300123001230714300203001230012300153002030012300143002030012307140000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400060074400755007640074500754007650070400705007040070500704007050020400405002040040500204004050020400405002040040500204004050020400405002040040500204004050020400405
018000000f9100f92513910139250f9100f925139101392510910109251491014925109101092514910149250f9100f92513910139250f9100f92513910139251091010925149101492510910109251491014925
0140001510910109100601512910129100801514910149100a01516910169100b0150b9100b910010150d9100d910030150f9100f910040150d9000d9000b9000b90014900149001290012900000000000000000
010200002e5142e5152e5142e5152e5242e5252e5242e5252e5342e5352e5342e5352e5442e5452e5442e5452e5542e5452e5442e5452e5442e5452e5442e5452e5342e5352e5342e5252e5242e5252e5142e515
0104000019433014213062024620186100c6100003106021010110703102021080110303109021040110a031050210b011060210d011070310e021080110f03109021100110a0311270100501061010050100000
01040000013303062030610080000b041070310302102011010110002100031000430c5241173516524187351d5242273524524297352e5243c735355243a7353060008001050010300101300306003060008001
0180000029e1429f252be142bf2529e1429f252be142bf252ae142af252ce142cf252ae142af252ce142cf2529e1429f252be142bf2529e1429f252be142bf252ae142af252ce142cf252ae142af252ce142cf25
010800000734501345000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
014000201df201ff301df201ff301df201ff301df201ff3024f2026f3024f2024f3524f2026f3024f2024f351ef2020f301ef2020f301ef2020f301ef2020f3025f2027f3025f2025f3025f2027f3025f2025f30
0180000023f1018a153000518a153000518a153000518a153000518a153000518a153000518a153000518a153000518a153000518a153000518a153000518a153000518a153000518a153000518a153000518a15
0102000019045000001e0450000023045000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
014000200f9100f925030151391013925070150f9100f925030151391013925070150f9100f9100f9250301510910109250401514910149250801510910109250401514910149250801510910109101092504015
00020000016100d6111c61131611146110c61108611056110261501601016050c600116001a600006000060000600006000060000600006000060000600006000000000000000000000000000000000000000000
01010000006000c7000c600137001860018700306001f7003c6002b70518600187000c60013700006000c70000600006000060000600006000060000600006000060000600006000060000600006000060000600
__music__
00 0d0e0f44
01 0d0e1044
02 12131044
00 18151444
01 1a151644
02 08090a44
01 1d1b1e44
02 201b1e44
00 200c1e44
01 210c1144
02 21191144
00 21110b22
01 21230b22
00 21230b22
02 24250b22
00 26270b22
00 26270b22
00 26271c22
00 26271c22
02 21112c22
01 28292b22
00 33383a22
00 34292f22
00 3d383a22
00 28292f22
00 33383a22
00 34292b22
02 3d383a22
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 21110b22

