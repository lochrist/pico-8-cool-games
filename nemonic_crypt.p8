--nemonic crypt
--by nemo_dev
--6/9/2021


delay_set=30--time before turret is ready
tur_speed=.6--turret rotation speed

--do not touch :p legacy code
worldx=7
worldy=4

--pallet stuff
pallist=[[
red,0,2,8,14,1,13,5,3,11,3,10,133,7,6,8,12
blue,0,140,12,11,1,13,5,3,9,137,10,133,7,6,8,12]]
unlocklist=[[
green,0,3,11,138,1,13,5,3,9,137,10,133,7,6,8,12
orange,0,4,9,10,1,13,5,3,11,3,12,133,7,6,8,12
pink,0,141,14,143,1,13,5,3,11,3,10,133,7,6,8,12
yellow,0,131,10,135,1,13,5,3,12,140,12,133,7,6,8,12
white,0,6,7,135,1,13,5,3,11,3,10,133,7,6,8,12
paint red,0,2,8,14,5,7,6,6,11,3,11,3,7,6,8,7
paint blue,0,1,12,140,5,7,6,6,9,137,9,137,7,6,140,7
paint orange,0,137,9,10,5,7,6,6,14,141,14,141,7,6,9,7
paint green,0,3,11,138,5,7,6,6,8,2,8,2,7,6,11,7
monochrome,0,6,7,6,5,7,6,6,6,5,6,5,7,6,7,7
gameboy,138,131,3,131,139,131,3,3,131,3,131,3,138,3,131,3
demonic,0,136,8,8,130,2,128,133,12,140,10,5,7,6,136,12
higgs,0,5,10,135,128,134,5,3,6,5,6,5,7,6,10,6
aqua,0,131,12,138,1,140,131,143,11,3,10,140,7,9,12,11
splatoon,0,14,11,11,141,9,137,3,10,140,10,140,7,6,14,10
xmas,0,11,8,8,6,7,5,6,12,140,137,5,7,6,8,12
nemo,0,12,7,140,1,140,129,3,9,137,10,5,7,6,12,9
devskin,7,0,0,0,7,0,0,0,0,7,0,0,7,0,0,0]]
unlockstrs=split(unlocklist,"\n")
palstrs=split(pallist,"\n")




function _init()
    cartdata("nemonic")
    debug=""
    --directionals
    dirx={1,0,-1,0}
    diry={0,1,0,-1}
    --initialize world
    mpos={}
    init_world()
    --trap stats
    trapct=120
    trapst=30
    --pause stuff
    pause=-1
    pfunction=function() end
    --set menu items
    menuitem(2,"retry dailycrypt",retry_daily)
    menuitem(3,"reset unlocks",resetunlocks)
    hardmode=false
    start_game()
--    add_obj(150,94,2)
--    show_sash("hello world",2,0)
end

function start_game()
    --set unlocked pallets
    setunlockpal()
    --pallet select
    if (dget(4)==0) dset(4,1)
    palsel=dget(4)
    if #palstrs<palsel then
        palsel=1
        dset(4,1)
    end
    --set seed
    dc=false--daily crypt
    seed=stat(92)*.1+stat(91)*3.1+stat(90)*37.2
    date=oh(tostr(stat(91))).."/"..oh(tostr(stat(92))).."/"..oh(tostr(stat(90)))
    if dget(0)==seed then
        seed=rnd(999)
    else
        dc=true
    end
    --win screen variables
    win=false
    wint=0
    tcrdst=24
    showcryst=true
    winmode=0
    --stats
    totalkills=dget(3) or 0
    unlk=nil
    --map generation stuff
--    startrn=0
--    endrn=2
--    floor=0
--    clear={}
    wpos,wposx,wposy=0,0,0
    --player direction
    dirlx,dirly=0,0
    dirdx,dirdy=1,0
    anispeed=30--animation speed
    --eye directionals
    eyedirx={1,2,2,1,0,0,0,1,2}
    eyediry={1,1,0,0,0,1,2,2,2}
    eyepos=1
    eyet=-1
    dashcool=false
    set_bounce=10
    kills=0
    door=true
    ltime=time()
    --global tick
    t=0
    --hit/miss count
    hit=0
    shot=0
    devskin=false
    --map stuff
    xtxt=true--tutorial
    mposx=0
    mposy=0
    camx=0
    camy=0
    camtx=0
    camty=0
    shake=0
    trapt=0--trap timer
    --spawn timer
    spawnt=0
    trapset=false
    --tables
    particle={}
    uparticle={}
    turret={}
    bullet={}
    enemy={}
    obj={}
   
    --sash
    sash_vis=false
    --adding a sash initilizes 
    --all other needed variables
   
    --spawn first crystal
--    local ex,ey=get_rpos(endrn)
--    add_obj(ex*128+64,ey*128+58,1)
   
    ground_floor()
   
    --over stuff
    over=false
    overt=0
    gover_thiq1=0
    gover_thiq2=0
    gover_thiq3=0
    gover_textoff=128
    gover_choice="none"
end

function retry_daily()
    lock(wpos%8,wpos\8,false)
    dset(0,0)
    music(-1)
    start_game()
end

function _update()
    t+=1
    update_pause()
    if win then
        update_end()
        update_over()
        update_particle()
    else
        update_turret()
        update_player(player)
        update_enemy()
        update_bullet()
        update_particle()
        update_room()
        update_obj()
        update_sash()
        update_camera()
        update_over()
    end
    local ox,oy=0,0
    if shake>0 then
        ox=rnd(2*shake)-shake
        oy=rnd(2*shake)-shake
    end
    camera(camx+ox,camy+oy)
end

function _draw()
    cls()
    setpal()
    if win then
        draw_end()
        draw_particle()
        draw_over()
    else
        draw_floor()
        draw_particle(true)
        draw_player()
        draw_bullet()
        draw_turret()
        draw_enemy()
        draw_obj()
        draw_particle()
        draw_sash()
        draw_over()
    end
    if debug~="" then
        print(debug,12+camx,12+camy,7)
    end
end

function init_win()
    win=true
    endt=time()
    crdst=100
    floor=6
end





-->8
--object 웃

----------
--player--
----------
function new_player(_hp)
    local rx,ry = get_rpos(startrn)
    local p={
        hp=_hp or 5,
        live=true,
        iframe=0,
        --positional stuff
        x=64+128*rx-3,
        y=64+128*ry-4,
        dx=0,
        dy=0,
        dirx=1,
        diry=0,
        w=4,
        h=8,
        r=3,
        --dash stuff
        dash=false,
        dasht=20,
        --turret stuff
        tur_ang=0,
        tur_sel=1,
        --room stuff
        fighting=false,
        --sprite stuff
        snum=0,
        sflip=false
    }
    if (not _hp) p.y+=8
    large_puff(p.x+p.w/2,p.y+p.h/2)
    return p
end

----------
--turret--
----------
function new_turret()
    local t={
        dist=0,
        tdist=9,
        delay=0,
        num=#turret,
    }
    return t
end

function fire_turret(_n)
    local t=turret[_n]
    if t.delay==0
    and player.fighting then
        local px,py=get_wpos(t)
        if mcol(px,py,1,1,0) then
            sfx(13)
            return true
        else
            sfx(1)
            shot+=1
            local pdx,pdy=2*cos(player.tur_ang+t.num/#turret),2*sin(player.tur_ang+t.num/#turret)
            add_bullet(px,py,pdx,pdy,5+5*floor,1,{2,1})
            t.delay=delay_set
            --particles
            medium_puff(get_wpos(t))
            return true
        end
    else
        return false
    end
end

----------
--bullet--
----------
function add_bullet(_x,_y,_dx,_dy,_bounce,_tpe,_pal)
    local b={
    bounce=_bounce,
    x=_x, y=_y,
    dx=_dx, dy=_dy,
    tpe=_tpe, cpal=_pal,
    flame=false
    }
    add(bullet,b)
end

function bullet_blast(_x,_y)
    local bnum=14
    local ao=rnd()
    for a=0,1,1/bnum do
        local dx,dy=1.5*cos(a+ao),1.5*sin(a+ao)
        add_bullet(_x,_y,dx,dy,1,3,{10,11})
    end
end

function delete_bullet(_b,_p)
    medium_puff(_b.x,_b.y,_b.cpal)
    if (_b.tpe==2 and not _p) bullet_blast(_b.x,_b.y)
    del(bullet,_b)
end

---------
--enemy--
---------
function new_enemy(_x,_y,_tpe,_elite)
    local e={
        hp=3,
        x=_x*8,
        y=_y*8,
        dx=0,
        dy=0,
        w=8,
        h=8,
        fdel=5,
        sflip=false,
        elite=_elite,
        tpe=_tpe,
        eid=#enemy
    }
    if (_elite) e.hp=5
    if _tpe==1 then
        e.h=5
    end
    if _tpe==3 then
        e.invt=20
    end
    return e
end

function add_obj(_x,_y,_tpe)
    add(obj,{x=_x,y=_y,tpe=_tpe})
end
-->8
--update ⬆️
function update_player(_p)
    local p=_p
    anispeed=30
    if p.live and not over then
        if (p.iframe>0) p.iframe-=1
        local nx,ny=p.x,p.y
       
        --pallet changing on floor 0
        if floor==0  
        and (wpos==0 or wpos==1) then
            if btnp(❎) then
                nextpal()
                large_puff(p.x+p.w/2,p.y+p.h/2)
            elseif btn(➡️) and btn(⬆️)
            and btn(⬅️) and btn(⬇️) 
            and not hardmode then
                hardmode=true
                show_sash("hardmode: enebled",2,1)
            end
--            debug=hardmode
            if (hardmode) p.hp=3
        end
        --make velocity 0 if slow
--        if (abs(p.dx)<.1) p.dx=0
--        if (abs(p.dy)<.1) p.dy=0
        --cape
        dirlx,dirly=0,0
        if abs(p.dx)>.3 then
            dirlx=1*sgn(p.dx)
        end
        if abs(p.dy)>.3 then
            dirly=1*sgn(p.dy)
        end
        --dash
       
       
        if btn(🅾️) and not dashcool
        and not dabort then
            sfx(0)
            p.dash=true
            p.dasht-=1
        elseif p.dash then
            p.dash=false
            dashcool=true
        end
       
        if p.dasht<=0 or dabort then
            p.dash=false
            dashcool=true
        end
       
        if p.dasht>=20 then
            dashcool=false
            p.dasht=20
        end
        if dashcool then
            p.dasht+=.5
        end
       
       
        local dirx,diry=0,0
        local maxspeed=2
        local a=.7
        if p.dash then
            maxspeed=5
            a=2
            dirx,diry=dirdx,dirdy
        end
       
        if btn(➡️) then
            dirx+=1
            p.sflip=false
            anispeed=8
        end
        if (btn(⬅️)) then
            dirx-=1
            p.sflip=true
            anispeed=8
        end
        if (btn(⬆️)) then
            diry-=1
            anispeed=8
        end
        if (btn(⬇️)) then
            diry+=1
            anispeed=8
        end
       
        --move player into room if not generated yet
        if not p.fighting
        and not clear[get_rnum(mposx,mposy)] then
            local rx,ry=p.x-camtx,p.y-camty--worldpos(p.x,p.y)
            if (rx<16) dirx=1
            if (rx>110) dirx=-1
            if (ry<16) diry=1
            if (ry>110) diry=-1
        end
       
        p.snum=(t\anispeed%2)
       
        --room clip fix
        local rdx,rdy=p.x+p.w/2-camtx,p.y+p.h/2-camty
        local dabort=false
--        if floor>0 and
        if rdx<10 or rdx>118 then
            dabort=true
            diry=0
        end
        if rdy<8 or rdy>118 then
            dabort=true
            dirx=0
        end
       
        if (dirx==0) p.dx*=.8
        if (diry==0) p.dy*=.8
       
       
        accel(p,dirx,diry,a,maxspeed)
       
        nx+=p.dx
        ny+=p.dy
       
        move(p,nx,ny)
       
        --eye movement
        if eyet>0 then
            eyet-=1
        elseif eyet==0 then
            eyet=-1
            eyepos=1
        end
       
        --particles
        if player.dash then
            local px=player.x+rnd(3)+1.5
            local py=player.y+rnd(3)+1.5
            local pdx,pdy=norm(player.dx,player.dy)
            pdx*=2 pdy*=2
            add_particle(2,px,py,pdx,pdy,15+rnd(15),{2,1},3)
        end
       
--        dirlx,dirly=dirx,diry
        if dirx~=0 or diry~=0 then
            dirdx,dirdy=dirx,diry
        end
        local nmposx,nmposy=(p.x+p.w/2)\128,(p.y+p.h/2)\128
       
        if mposx~=nmposx
        or mposy ~=nmposy then
            dashcool=true
        end
       
       
       
        mposx,mposy=nmposx,nmposy
        wpos=floormap[mposx+mposy*24]
        wposx,wposy=wpos%8,wpos\8
        camtx=mposx*128
        camty=mposy*128
       
       
       
        if not p.fighting
        --and wpos~=startrn
        and not clear[get_rnum(mposx,mposy)] then
--        and p.x-p.w/2-camtx>11
--        and p.x+p.w/2-camtx<116
--        and p.y-p.h/2-camty>11
--        and p.y+p.h/2-camty<116 then
            local rx,ry=p.x+p.w/2-camtx,p.y+p.h/2-camty
            if rx>12 and rx<116
            and ry>12 and ry<116 then
                gen_room(wpos%8,wpos\8)
            end
        elseif p.fighting
        and #enemy<=0 then
            if (xtxt) xtxt=false
            music(2)
            p.fighting=false
            lock(wpos%8,wpos\8,false)
            clear[get_rnum(mposx,mposy)]=true
        end
       
       
        --fire 
        local f=3
        if (trapset) f=2
        if trapt>trapst and not player.dash
        and mcol(p.x+1,p.y+1,p.w-2,p.h-2,f)
        and p.iframe==0 then
            sfx(4)
            damage_player()
        end
        --bullet hit detection
        if not player.dash 
        and p.iframe==0 then
            for b in all(bullet) do
                if aabb(p.x,p.y,p.w,p.h,b.x,b.y,0,0) then
                    sfx(4)
                    damage_player()
                    if b.flame
                    and player.hp>0 then
                        damage_player()
                    end
                    delete_bullet(b,true)
                end
            end
            if p.iframe==0 and spawnt==0
            and ecoli(p.x,p.y,p,true) then
                sfx(5)
                damage_player()
            end
        end
        if p.hp<=0 then
            kill_player()
        end
    else
        if not over and isnot_savable() then
            endt=time()
            set_over()
        end
    end--end of live check
    --turret stuff
    local tim=time()
    p.tur_ang+=(tim-ltime)*tur_speed
    ltime=tim
    if p.tur_ang>=1 then
        p.tur_ang=0
    end
end

function isnot_savable()
    local ns=true
    for b in all(bullet) do
        ns=b.tpe~=1 and ns
    end
--    debug=ns
    return ns
end

function set_over()
    dset(3,dget(3)+kills)
    over=true
end

function damage_player()
    player.hp-=1
    player.iframe=30
    shake=3
end

function kill_player()
    sfx(8)
    music(4)
    player.live=false
    shake=10
    large_puff(player.x,player.y)
end

--tomove
function move(_o,_nx,_ny)
    --offset for player
    local o=0
    --bounce check
    local b=mag(_o.dx,_o.dy)>1.5
    if (_o==player) o=4 
    if not mcol(_nx,_ny+o,_o.w,_o.h-o)
    and not ecoli(_nx,_ny,_o) then
        _o.x,_o.y=_nx,_ny
    else
        if not mcol(_nx,_o.y+o,_o.w,_o.h-o)
        and not ecoli(_nx,_o.y,_o) then
            _o.x=_nx
        else
            if b then _o.dx*=-.9
            else _o.dx=0 end
        end
        if not mcol(_o.x,_ny+o,_o.w,_o.h-o)
        and not ecoli(_o.x,_ny,_o) then
            _o.y=_ny
        else
            if b then _o.dy*=-.9
            else _o.dy=0 end
        end
    end
end

function ecoli(_x,_y,_o,_b)
    if _o==player and not _b then
        return false
    end
    for e in all(enemy) do
        if e~=_o
        and aabb(_x,_y,_o.w,_o.h,e.x,e.y,e.w,e.h) then
            return true
        end
    end
    return false
end

function update_turret()
    for t in all(turret) do
        if player.live then
            if t.delay>0 then
                t.delay-=1
                t.tdist=4+5*(1-t.delay/delay_set)
            else
                t.tdist=9
            end
           
            if player.dash
            or not player.fighting then
                t.tdist=0
            end
        else
            t.tdist+=2
            player.tur_ang+=.01
        end
        t.dist+=(t.tdist-t.dist)/2
    end--end turret loop
    if btnp(❎) and floor~=0 and not player.dash 
    and not over then
        local f=fire_turret(player.tur_sel)
        if f then
            if (devskin) nextpal(true)
            --eye movement
            local tang=(player.tur_ang+(player.tur_sel-1)/#turret)+1/16
            if (tang>=1) tang-=1
            eyepos=tang\(1/8)+2
            eyet=15
           
            --turret change
            player.tur_sel-=1
            if player.tur_sel<=0 then
                player.tur_sel=#turret
            end
        else
            --nrr nrr sfx
        end
    end--end btn(❎)
end


function update_bullet()
    for b in all(bullet) do
        local nx=b.x+b.dx
        local ny=b.y+b.dy
        local tx,ty=worldpos(nx,ny)
        if fmget(tx,ty,0) then
--            sfx(2) 
            b.bounce-=1
            if b.flame then
                b.flame=false
                medium_puff(nx,ny,b.cpal)
            end
           
            tx,ty=worldpos(nx,b.y)
            if fmget(tx,ty,0) then
                b.dx*=-1
            else
                b.x=nx
            end
            tx,ty=worldpos(b.x,ny)
            if fmget(tx,ty,0) then
                b.dy*=-1
            else
                b.y=ny
            end
            small_puff(nx,ny,b.cpal)
        else
            b.x,b.y=nx,ny
        end
       
        if b.bounce<=0 then
            if (b.tpe==1) delete_bullet(b)
            delete_bullet(b)
        end
       
        --flame set
        local f=3
        if (trapset) f=2
        if trapt>trapst and b.tpe==1
        and fmget(tx,ty,f) then
            b.flame=true
        end
       
        if b.tpe==1 then
            if b.flame then
                b.cpal={3,3,1}
            else
                b.cpal={2,1}
            end
        end
       
        --particles
        local ptpe=1
        if (b.flame) ptpe=2
        local px=b.x+rnd(2)-1
        local py=b.y+rnd(2)-1
        local pl=10+rnd(5)
        add_particle(ptpe,px,py,0,0,pl,b.cpal,2)
    end
end

function update_enemy()
    if spawnt>0 then
        spawnt-=1
    else
        for i,e in ipairs(enemy) do
            local nx,ny=e.x,e.y
            --target palyer
            local dirx,diry=norm(player.x+player.w/2-e.x,player.y+player.h/2-e.y)
            local eoff=i/#enemy
            local a=.1
            local maxspeed=2
            local f=.8--friction
            if e.tpe==1 then
                --slime/flare
                a=2
                f=.9
                if e.elite and not over then
                    f,a,maxspeed=.9,3,3
                    local px,py=e.x+rnd(8),e.y+2
                    add_particle(1,px,py,rnd()-.5,-1,4+rnd(2),{8,9})
                end
                if t%30~=flr(30*eoff)-1 then
                    dirx,diry=0,0
                end
            elseif e.tpe==2 then
                --bat/wasp
                if dist(player.x,player.y,e.x,e.y)<40 then
                    a*=-1
                end
                if player.live and t%120==flr(120*eoff)-1 then
                    local btpe,bdx,bdy,bpal,bbnce=3,dirx*1.5,diry*1.5,{10,11},3
                    if e.elite then
                        btpe=2 bdx=dirx bdy=diry
                        bbnce=1 bpal={10,11}
                    end
                   
                    add_bullet(e.x,e.y,bdx,bdy,bbnce,btpe,bpal)
                end
            elseif e.tpe==3 then
                --ghost/eye
                maxspeed=1
                if e.elite and rnd()<.4 then
                    local pc=13
                    if (e.invt==-1) pc=4
                    add_particle(2,e.x+rnd(4)+2,e.y+rnd(4)+2,0,0,25+rnd(15),{pc},2.5,true)
                    maxspeed=1.5
                    if e.invt>0 then
                        e.invt-=1
                    elseif e.invt==0 then
                        medium_puff(e.x+e.w/2,e.y+e.h/2,{13})
                        e.invt=-1
                    end
                end
               
            end
            --friction
            if (dirx==0) e.dx*=f
            if (diry==0) e.dy*=f
            accel(e,dirx,diry,a,maxspeed)
           
            nx+=e.dx
            ny+=e.dy
           
           
            --face sprite
            if e.dx<0 then
                e.sflip=true
            else
                e.sflip=false
            end
           
            if e.tpe==3 then
                if not ecoli(nx,ny,e) then
                    e.x,e.y=nx,ny
                else
                    e.dx*=-1
                    e.dy*=-1
                end
            else
                move(e,nx,ny)
            end
            --hit detection
            for b in all(bullet) do
                if b.tpe==1
                and aabb(e.x-1,e.y-1,e.w+2,e.h+2,b.x-1,b.y-1,2,2) then
                    hit+=1
                    sfx(3)
                    e.hp-=1--★
                    if e.tpe==3 and e.elite then
                        e.invt=20
                    end
                    if (b.flame) e.hp-=1
                    e.dx+=2*b.dx
                    e.dy+=2*b.dy
                    delete_bullet(b)
                end
            end
           
            if e.hp<=0 then
                sfx(6)
                local ppal={8,9}
                if (e.tpe==2) ppal={10,11}
                if (e.tpe==3) ppal={12,13}
                medium_puff(e.x+e.w/2,e.y+e.h/2,ppal,4,15+rnd(15))
                srand(seed+e.eid*.666+floor*10.1+mposx*.2+mposy*.3)
                if rnd()<.25 
                and not hardmode then
                    add_obj(e.x+e.w/2,e.y+e.h/2,2)
                end
                del(enemy,e)
                kills+=1
                if not player.live and #enemy==0 then
                    show_sash("sudden death",1,2)
                    player.live=true
                    player.hp=1
                    player.iframe=30
                    large_puff(player.x,player.y)
                end
            end
        end
    end
end

function update_room()
    if player.fighting then
        trapt+=1
        if trapt>=trapct then
            trapset=not trapset
            trapt=0
        end
    else
        trapt=0
    end
   
    local trapl=mpos[wpos].trap
    if (trapset) trapl=mpos[wpos].trap2
    if trapt~=0 then
        local ptpe=1
        if (trapt>trapst) ptpe=2
        for i=1,#trapl,2 do
            if rnd()<.5 and not over then
                local px=mposx*128+trapl[i]*8+4.5-rnd()
                local py=mposy*128+trapl[i+1]*8+3+rnd()
                add_particle(ptpe,px,py,1-rnd(2),-1-rnd(),5+(ptpe-1)*15-rnd(5),{8,9},3,true)
            end
        end
    end
   
    local torch=mpos[wpos].torch
    for i=1,#torch,2 do
        if rnd()<.75 then
            local px,py=torch[i],torch[i+1]
            px=px*8+4+mposx*128
            py=py*8+1+mposy*128
            local pcol={8,9}
           
            if clear[get_rnum(mposx,mposy)] then
                pcol={2,1}
                if dc then
                    pcol={3,1}
                end
            end
            add_particle(2,px,py,.5-rnd(),-.5-rnd(),15-rnd(5),pcol,1.1,true)
        end
    end
end

function update_camera()
    local dx,dy=camtx-camx,camty-camy
    camx+=(dx)/2
    camy+=(dy)/2
    shake*=.8
    if shake<.25 then
        shake=0
    end
    if (abs(dx)<1) camx=camtx
    if (abs(dy)<1) camy=camty
end

function update_obj()
    for o in all(obj) do
        if o.tpe==1 then
            local dsty=abs(o.y-player.y)
            local dstx=abs(o.x-player.w/2-player.x)
            local close=dsty<8 and dstx<8
            if rnd()<.1 then
                local pspeed=1
                add_particle(4,o.x,o.y,rnd(pspeed)-pspeed/2,rnd(pspeed)-pspeed/2,60+rnd(60),{2,1},5)
            end
            if player.dash then
               
                if close then
                    del(obj,o)
                   
                    if floor==5 then
                        init_win()
                    else
                        new_floor()
                        sfx(10)
                        sfx(11)
                    end
                end
            elseif close then
            player.dx*=-3
            player.dy*=-3
            end 
        elseif o.tpe==2 then
            local dsty=abs(o.y-player.y-player.h/2)
            local dstx=abs(o.x-player.x-player.w/2)
            local close=dsty<6 and dstx<6
            local mhp=5
            if (hardmode) mhp=3
            if player.hp<mhp and close 
            and player.live then
                sfx(9)
                player.hp+=1
                small_puff(o.x,o.y,{14})
                del(obj,o)
            end
        end
    end
end

function update_over()
    if over then
        if overt<1000 then
            overt+=1
        end
        local pa=rnd()
        local pspd=3+rnd(4)
        local pdx,pdy=pspd*cos(pa),pspd*sin(pa)
        local pr=1+overt/1.5
        if overt<120 then
            add_particle(5,player.x,player.y,pdx,pdy,600,{2},pr)
        end
        if overt==20 then
            if win then
                --win sfx
            else
                sfx(12)
            end
            music(-1)
        end
        if not unlk then
            unlk=checkunlock()
        end
        --reduce tokens here vvv
        if (overt>70) gover_thiq1+=(69-gover_thiq1)/8
        if (overt>78) gover_thiq2+=(69-gover_thiq2)/8
        if (overt>84) gover_thiq3+=(36-gover_thiq3)/8
        if (overt>86) gover_textoff+=(0-gover_textoff)/10
        if overt>60 then
            lock(wpos%8,wpos\8,false)
            if pause<0 then
                if btnp(🅾️) then
                    gover_choice="new"
                    sfx(9)
                    pause=24
                    pfunction=start_game
                elseif btnp(❎) and dc then
                    gover_choice="retry"
                    sfx(9)
                    pause=24
                    pfunction=retry_daily
                end
            end
        end
    end
end

function update_end()
    wint+=1
    if winmode==0 then
        crdst+=(tcrdst-crdst)/18
        if wint>60 and tcrdst>0 then
            tcrdst-=1
        elseif tcrdst<1 and showcryst then
            showcryst=false
            mega_puff(64,64)
            large_puff(64,64)
            winmode=1
        end
    elseif winmode==1 then
        if rnd()<.1 then
            local pspeed=1
            add_particle(4,64,64,rnd(pspeed)-pspeed/2,rnd(pspeed)-pspeed/2,60+rnd(60),{2,1},5)
        end
        if btnp(🅾️) then
            player.x=64
            player.y=64
            mposx,mposy=0,0
            set_over()
        end
    end
end
-->8
--draw ∧
function draw_player()
    if floor==0 then
        sspr(66,0,62,15,14,22)--nemo
        sspr(96,39,32,20,77,17)--onic
        sspr(82,15,46,24,69,33)--crypt
--        print("project: balls",40,30,2)
--        palt(2,true)
--        for i=0,2 do
--            spr(16+16*i,12+12*i,80)
--        end
--        palt()
        print("BY NEMO_DEV",22,38,1)
        if (hardmode) print("hardmode",0,0,1)
        print("pallet -",32,100,1)
        print(palname,68,100,2)
        print("press ❎ to change color",16,116,1)
        if (dc) print(oh(stat(91)).."/"..oh(stat(92)).."/"..stat(90),178,41,1)
        if (wpos==1 or wpos==2)
        and not hardmode then
            print("hold 🅾️",player.x-10,player.y-8,1)
            if (not btn(🅾️)) print("     🅾️",player.x-10,player.y-9,3)
        end
    elseif xtxt and not hardmode
    and player.live 
    and get_rnum(mposx,mposy)~=startrn then
        print("❎",player.x-2,player.y-8,1)
        if (not btn(❎)) print("❎",player.x-2,player.y-9,3)
    end
   
   
    if player.live then
        palt(0,false)
        palt(11,true)
        local ifrmoff=0
        if player.iframe\5%2==1 then
            ifrmoff=8
        end
        if player.dash then
            circfill(player.x+2,player.y+2,2,2)
        else
            sspr(8+player.snum*4+ifrmoff,0,player.w,player.h,player.x,player.y,player.w,player.h,player.sflip)
            --eye
            local ex=player.x+eyedirx[eyepos]
            local ey=player.y+1+eyediry[eyepos]+player.snum
            if (not player.sflip) ex+=1
            pset(ex,ey,2)
            --cape
            local cx=player.x-1-dirlx
            if (player.sflip) cx+=2
            local cy=player.y+player.h-1-dirly
            local ccol=1
            if (ifrmoff>0) ccol=14
            line(cx,cy,cx+3,cy,ccol)
        end
        palt()
        setpal()
    else
        --player is dead
        --draw corpse
        spr(3,player.x-1,player.y)
    end
    --ui
    if wpos~=0 then
        camera(0,0)
        local hux=31
        if (hardmode) hux=19
        rectfill(0,0,hux,7,0)
        rect(-1,-1,hux,7,1)
        if player.hp>0 then
            for i=1,player.hp do
                print("♥",(i-1)*6,1,14)
            end
        end
        rectfill(0,7,7,31,0)
        rect(-1,7,7,31,1)
        local dc=2
        if (dashcool) dc=4
        rectfill(1,29,5,29-20*player.dasht/20,dc)
        camera(camx,camy)
    end
end

function draw_turret()
    for t in all(turret) do
        if t.dist>1 then
            local x,y=get_wpos(t)
            local sn=0
            if t.num+1==player.tur_sel then
                sn=1
            end
            if t.delay>0 then
                sn=2
            end
            spr_r(5+sn,0,x,y,1,1,false,false,0,4,player.tur_ang+t.num/#turret,0)
        end
    end
end

function draw_bullet()
    for b in all(bullet) do
        local r=1
        if (b.flame or b.tpe==2) r+=1
        circfill(b.x,b.y,r,b.cpal[1])
    end 
end

function draw_enemy()
   
    for e in all(enemy) do
        palt(0,false)
        palt(2,true)
        local s=16*e.tpe+t\e.fdel%4
        if (e.elite) s+=4
        if spawnt==0 then
            if e.tpe==3 and e.elite
            and e.invt==-1 then
                pal(12,0)
                pal(13,4)
                pal(14,4)
            end
            spr(s,e.x,e.y,1,1,e.sflip)
            setpal()
        else
            if spawnt>20 then
                fillp(░|0b.011)
            elseif spawnt>10 then
                fillp(▒|0b.011)
            end
            warpspr(s,e.x,e.y,1,1,spawnt/10)
            fillp()
        end
    end
    palt()
end


function draw_obj()
    for o in all(obj) do
        if o.tpe==1 then
            sspr(40,48,9,16,o.x-3.4+cos(t/69),o.y-11-2*sin(t/120))
        elseif o.tpe==2 then
            print("♥",o.x-2,o.y-3,14)
        end
    end
end

function draw_floor()
    for rpos,mp in pairs(floormap) do
        local rx,ry=get_rpos(rpos)
        local mx,my=mp%8,mp\8
        map(mx*16,my*16,rx*128,ry*128,16,16)
    end
end

function draw_over()
    local scrx,scry=mposx*128,mposy*128
   
    if (gover_thiq1>0) rectfill(scrx,scry+64-gover_thiq1,scrx+127,scry+64+gover_thiq1,1)
    if (gover_thiq2>0) rectfill(scrx,scry+64-gover_thiq2,scrx+127,scry+64+gover_thiq2,0)
    local yt,yb=scry+64-gover_thiq3,scry+64+gover_thiq3
    if gover_thiq3>0 then
        line(scrx,yt,scrx+127,yt,1)
        line(scrx,yb,scrx+127,yb,1)
        local h="\^t\^wgame over"
        local hc=14
        if win then
            h="\^t\^wcongrats"
            hc=2
        end
        print(h,scrx+28,scry-24+gover_thiq3,hc)
       
        local bm1c,bm2c=1,1
        local c=blinkcol({1,2,3,2},3)
        if gover_choice=="new" then
            bm1c=c
        elseif gover_choice=="retry" then
            bm2c=c
        end
       
        print("   press 🅾️ for new crypt",scrx+8-gover_textoff,scry+108+1.5*sin(t/60),bm1c)
        if (dc) print("press ❎ to retry daily crypt",scrx+8-gover_textoff,scry+115+1.5*sin(t/60),bm2c)
    end
    clip(0,64-gover_thiq3,128,2*gover_thiq3)
    if hardmode then
        print("hardmode",scrx+60+gover_thiq3,scry+93,2)
    end
    if overt>30 then
        local tx,ty=scrx+6,scry+38
        local dtime=(endt-startt)\1
        local m=oh(dtime\60)
        local s=oh(dtime%60)
--        if (#m<2) m="0"..m
--        if (#s<2) s="0"..s
        dtime=m..":"..s
        local acc=tostr(flr(hit/shot*100)).."%"
        local ltk=ceil(totalkills)
        if (overt>104) totalkills+=(dget(3)-totalkills)/24
        if (ltk~=ceil(totalkills)) sfx(3)
        local statvals={
        tostr(floor).."/6",
        dtime,
        acc,
        tostr(kills),
        ceil(totalkills)}
        local stats=[[
           crystals -
               time -
           accuracy -
              kills -
        total kills -]]
        if dc then 
            ty+=3
            stats="            attempt -\n"..stats
            for i=#statvals,1,-1 do
                statvals[i+1]=statvals[i]
            end
            statvals[1]=attempt
            sprint("daily crypt : "..date,tx+10,ty-10,3,1)
        end
        local statstrs=split(stats,"\n")
        --pixel spacing
        local psp=60/#statstrs
        for i=1,#statstrs do
            local y=ty+psp*(i-1)
            sprint(statstrs[i],tx,y,2,1)
            print(statvals[i],tx+67+gover_textoff+sin((t+i*5)/30),y)
        end
    end
    clip()
    if unlk and unlk>0 
    and overt>100 then
--        debug=unlk
        print("+"..unlk.." new pallet(s) unlocked",scrx+28,scry+123,3)
    end
end

function draw_end()
    camera()
    if showcryst then
        for i=1,6 do
            local a=i/6+t/120
            local x=60+crdst*cos(a)
            local y=56+crdst*sin(a)
--    circfill(x,y,3,2)
            sspr(40,48,9,16,x,y)
        end
    else
        sspr(56,48,17,16,56,56)
        if wint>170 then
            print("\^t\^wthanks for\n playing!",26,22,2)
        end
        if wint>180 then
            print("press 🅾️ to continue",24,100,1)
        end
    end
end
-->8
--map ●
--helper functions
function mcol(_x,_y,_w,_h,_f)
    local rx,ry=worldpos(_x,_y)
    local flag = _f or 0
    local collision=false
    for x=rx,rx+_w,_w do
        for y=ry,ry+_h,_h do
            if x>128*wposx and x<128*wposx+127
            and y>128*wposy and y<128*wposy+127 then
                if (fmget(x,y,flag)) collision=true
            end
        end
    end
    return collision
end

function worldpos(_x,_y)
    local rx,ry=_x-mposx*128,_y-128*mposy
    return rx+wposx*128,ry+wposy*128
end

function fmget(_x,_y,_f)
    return fget(mget(_x/8,_y/8),_f)
end

--world generator
function init_world()
    mpos={}
    for wx=0,7 do
        for wy=0,3 do
            local room={
                x=wx,
                y=wy,
                clear=false,
                doorpos={},
                spawnpoint={},
                trap={},
                trap2={},
                torch={}
            }

            for tx=0,15 do
                for ty=0,15 do
                    local dx,dy=wx*16+tx,wy*16+ty
                    local tspr=mget(dx,dy)
                    if tspr<64 and tspt~=0 then
                        add(room.spawnpoint,tspr\16)
                        add(room.spawnpoint,tx)
                        add(room.spawnpoint,ty)
                        mset(dx,dy,64)
                    elseif tspr==83 then
                        add(room.doorpos,tx)
                        add(room.doorpos,ty)
                        mset(dx,dy,65)
                    elseif tspr==84 then
                        add(room.trap,tx)
                        add(room.trap,ty)
                    elseif tspr==68 then
                        add(room.trap2,tx)
                        add(room.trap2,ty)
                    elseif tspr==86 then
                        add(room.torch,tx)
                        add(room.torch,ty)
                    end
                end
            end
            mpos[wx+wy*8]=room
        end
    end
end

--world functions
function lock(_rx,_ry,_l)
    local r=mpos[_rx+8*_ry]
    for i=1,#r.doorpos,2 do
        local tx,ty=r.doorpos[i]+16*mposx,r.doorpos[i+1]+16*mposy
        local t=65
        if _l then
            digital_puff(tx*8+4,ty*8+4)
            t=83
        else
            for b in all(bullet) do
                delete_bullet(b)
            end
        end
        mset(16*_rx+r.doorpos[i],16*_ry+r.doorpos[i+1],t)
    end
end

function summon(_rx,_ry)
    srand(seed+wpos+100*floor)
    sfx(7)
    local rsp=mpos[_rx+_ry*8].spawnpoint
    local spawns=gen_nums(#rsp/3-1,min(floor,4))
    local elite_num=0
    if (floor>=3) elite_num=floor-2
    local elist=gen_nums(#spawns-1,elite_num)
    spawnt=30
    for e=1,#spawns do
        i=spawns[e]*3+1
        local elite=false
        for n=1,#elist do
            if (elist[n]+1==e) elite=true
        end
        add(enemy,new_enemy(16*mposx+rsp[i+1],16*mposy+rsp[i+2],rsp[i],elite))
    end
--    for i=1,#rsp,3 do
--        add(enemy,new_enemy(16*mposx+rsp[i+1],16*mposy+rsp[i+2],rsp[i]))
--    end
    music(0)
end

function gen_nums(_v,_n)
    local nums={}
    local cnums={}
    for i=0,_v do
        add(nums,i)
    end
    for i=1,_n do
        local sel=ceil(rnd(#nums))
        add(cnums,nums[sel])
        del(nums,nums[sel])
    end
    return cnums
end

function gen_room(_rx,_ry)
    lock(_rx,_ry,true)
    summon(_rx,_ry)
    player.fighting=true
end
-->8
--tools ♥
--pallet stuff
function nextpal()
    palsel+=1
    if (palsel>#palstrs) palsel=1
    dset(4,palsel)
end

function setpal()
    local p=split(palstrs[palsel],",",true)
    pal()
    palname=p[1]
    for c=0,15 do
        pal(c,p[c+2],1)
    end
end

--pause
function update_pause()
    if pause>0 then 
        pause-=1
    elseif pause==0 then
        pause=-1
        pfunction()
    end
end

--blink
function blinkcol(_t,_bs)
    local _bs=_bs or blinkspeed
    return _t[(t\_bs)%#_t+1]
end

--make a char 2 char long :o
--used for dates and times
function oh(_s)
    _s=tostr(_s)
    if (#_s<2) _s="0".._s
    return _s
end

--printing tools
function sprint(_s,_x,_y,_c1,_c2)
    print(_s,_x,_y+1,_c2)
    print(_s,_x,_y,_c1)
end

--vector maths
--normalizer
function norm(_x,_y)
    local m=mag(_x,_y)
    return _x/m,_y/m
end
--magnitude
function mag(_x,_y)
    return sqrt(_x^2+_y^2)
end

--distance
function dist(_x1,_y1,_x2,_y2)
    return sqrt((_x1-_x2)^2+(_y1-_y2)^2)
end

--accelerate
function accel(_o,_dirx,_diry,_a,_max)
    if _dirx~=0 or _diry~=0 then
        local dirx,diry=norm(_dirx,_diry)
        _o.dx+=dirx*_a
        _o.dy+=diry*_a
        local speed=mag(_o.dx,_o.dy)
        if speed>_max then
            _o.dx*=_max/speed
            _o.dy*=_max/speed
        end
    end
end

--returns global position of 
--passed turret
function get_wpos(_t)
    local ox=_t.dist*cos(player.tur_ang+_t.num/#turret)
    local oy=_t.dist*sin(player.tur_ang+_t.num/#turret)
    return player.x+player.w/2+ox,player.y+player.h/2+oy
end

--aabb
function aabb(ax,ay,aw,ah,bx,by,bw,bh)
    if ax + aw >= bx and ax <= bx + bw and ay + ah >= by and ay <= by+bh then return true end
    return false
end

--rotating sprite function
--by jihem, revised by huulong 
function spr_r(i, j, x, y, w, h, flip_x, flip_y, pivot_x, pivot_y, angle, transparent_color)
 -- precompute pixel values from tile indices: sprite source top-left, sprite size
 local sx = 8 * i
 local sy = 8 * j
 local sw = 8 * w
 local sh = 8 * h

 -- precompute angle trigonometry
 local sa = sin(angle)
 local ca = cos(angle)

 -- in the operations below, 0.5 offsets represent pixel "inside"
 -- we let pico-8 functions floor coordinates at the last moment for more symmetrical results

 -- precompute "target disc": where we must draw pixels of the rotated sprite (relative to (x, y))
 -- the target disc ratio is the distance between the pivot the farthest corner of the sprite rectangle
 local max_dx = max(pivot_x, sw - pivot_x) - 0.5 
 local max_dy = max(pivot_y, sh - pivot_y) - 0.5
 local max_sqr_dist = max_dx * max_dx + max_dy * max_dy
 local max_dist_minus_half = ceil(sqrt(max_sqr_dist)) - 0.5

 -- iterate over disc's bounding box, then check if pixel is really in disc
 for dx = - max_dist_minus_half, max_dist_minus_half do
  for dy = - max_dist_minus_half, max_dist_minus_half do
   if dx * dx + dy * dy <= max_sqr_dist then
    -- prepare flip factors
    local sign_x = flip_x and -1 or 1
    local sign_y = flip_y and -1 or 1

    -- if you don't use luamin (which has a bracket-related bug),
    -- you don't need those intermediate vars, you can just inline them if you want
    local rotated_dx = sign_x * ( ca * dx + sa * dy)
    local rotated_dy = sign_y * (-sa * dx + ca * dy)

    local xx = pivot_x + rotated_dx
    local yy = pivot_y + rotated_dy

    -- make sure to never draw pixels from the spritesheet
    --  that are outside the source sprite
    if xx >= 0 and xx < sw and yy >= 0 and yy < sh then
     -- get source pixel
     local c = sget(sx + xx, sy + yy)
     -- ignore if transparent color
     if c ~= transparent_color then
      -- set target pixel color to source pixel color
      pset(x + dx, y + dy, c)
     end
    end
   end
  end
 end
end

--warped sprite
--by coffeebat
function warpspr(n,x,y,w,h,warp)
local w_t=w*8
local h_t=h*8
--use:
--warpspr(sprite_number,onscreen_x,onscreen_y,width,height,warp_intensity,flip_horizontally)
    local spx=(n%16)*8
    local spy=(n\16)*8
    for i=0,w_t-1 do
            local xw=2*sin(1.3*time()-(i/h_t))*warp+x
            sspr(spx,spy+i,w_t,1,xw,y+i,w_t,1)
        end
end


-->8
--particles! :d
--[[

particle types
 1 - point
 2 - smoke
 3 - digital
 4 - aura
 5 - oversnow
]]
function add_particle(_tpe,_x,_y,_dx,_dy,_mt,_pal,_r,_under)
    local p={
        tpe=_tpe,
        x=_x, y=_y,
        dx=_dx, dy=_dy,
        cpal=_pal,
        r=_r,
        t=0, mt=_mt,
    }
    if _under then
        add(uparticle,p)
    else
        add(particle,p)
    end
end

function mega_puff(_x,_y)
    for i=1,60 do
        local pdx=rnd(12)-6
        local pdy=rnd(12)-6
        local pl=30+rnd(45)
        add_particle(2,_x,_y,pdx,pdy,pl,{2,1},8)
    end
end

function large_puff(_x,_y)
    for i=1,15 do
        local pdx=rnd(6)-3
        local pdy=rnd(6)-3
        local pl=30+rnd(15)
        add_particle(2,_x,_y,pdx,pdy,pl,{2,1},6)
    end
end

function medium_puff(_x,_y,_pal,_s,_l)
    _s = _s or 3
    _pal = _pal or {2,1}
    for i=1,5 do
        local pdx=rnd(2)-1
        local pdy=rnd(2)-1
        local pl= _l or 10+rnd(5)
        add_particle(2,_x,_y,pdx,pdy,pl,_pal,_s)
    end
end


function small_puff(_x,_y,_pal)
    for i=1,3 do
        local pdx=rnd(2)-1
        local pdy=rnd(2)-1
        local pl=10+rnd(5)
        add_particle(1,_x,_y,pdx,pdy,pl,_pal)
    end
end

function digital_puff(_x,_y)
    for i=1,3 do
        local pdx=rnd(4)-2
        local pdy=rnd(4)-2
        local pl=15+rnd(20)
        add_particle(3,_x,_y,pdx,pdy,pl,{15},6)
    end
end

function update_particle()
    local part={}
    for p in all(particle) do
        part[#part+1]=p
    end
    for up in all(uparticle) do
        part[#part+1]=up
    end
    for p in all(part) do
        p.t+=1
       
        if p.tpe==2 or p.tpe==3 then
            p.dx*=.85
            p.dy*=.85
        end
       
        p.x+=p.dx
        p.y+=p.dy
       
        if p.t>=p.mt then
--        or p.y>200 then
            del(particle,p)
            del(uparticle,p)
        end
    end
end

function draw_particle(_under)
    local part
    if _under then
        part=uparticle
    else
        part=particle
    end
    for p in all(part) do
        local c=p.cpal[#p.cpal*p.t\p.mt+1]
        if p.tpe==1 then
            pset(p.x,p.y,c)
        elseif p.tpe==2 then
            local r=p.r*(1-p.t/p.mt)
            circfill(p.x,p.y,r,c)
        elseif p.tpe==3 then
            local l=p.r*(1-p.t/p.mt)
            rect(p.x-l/2,p.y-l/2,p.x+l/2,p.y+l/2,c)
        elseif p.tpe==4 
        and p.t>4 then
            local r=p.r*(1-p.t/p.mt)
            if p.t<60 then
                fillp(▒)
            else
                fillp(░)
            end
            circfill(p.x,p.y,r,c)
            fillp()
        elseif p.tpe==5 then
            circfill(p.x,p.y,p.r,c)
        end
    end
end
-->8
--procedural generation UWU
function ground_floor()
    obj={}
    partacle={}
    floormap={}
    clear={}
    floor=0
    for i=0,2 do
        floormap[i]=i
        clear[i]=true
    end
    startrn=0
    endrn=2
    local ex,ey=get_rpos(endrn)
    add_obj(ex*128+64,ey*128+58,1)
    player=new_player()
end

function new_floor()
    if (palsel==20) devskin=true
    obj={}
    particle={}
    floormap={}
    clear={}
    floor+=1
    floormap=set_tiles(world_gen(2+floor))
    player=new_player(player.hp)
    if (floor>=2) add_obj(player.x+player.w/2+dirx[sdir]*-26,player.y+player.h/2+diry[sdir]*-26,2)
    clear[startrn]=true
    update_player(player)
    camx,camy=camtx,camty
    local ex,ey=get_rpos(endrn)
    add_obj(ex*128+64,ey*128+58,1)
    add(turret,new_turret())
    shake=20
    if floor==1 then
        startt=time()
        if dc then
            dset(0,seed)
            attempt=dget(2)
            if seed~=dget(1) then
                attempt=1
                dset(1,seed)
            else
                attempt+=1
            end
            dset(2,attempt)
        end
    end
    music(2)
    show_sash("floor: "..floor,2,0)
end

function  get_rpos(_rn)
    return _rn%24,_rn\24
end

function get_rnum(_x,_y)
    return _x+_y*24
end

function world_gen(_nr)
    srand(seed+100*floor)
    startrn=0
    endrn=0
    local f_world={}
    local t_world={}
    local t_rpos={}
    t_world[get_rnum(12,12)]=1
    add(t_rpos,get_rnum(12,12))
    for i=1,_nr do
        local rx,ry,rn
        rn=set_room(t_rpos,t_world)
    end
   
    --start and end
    startrn,sdir=set_room(t_rpos,t_world)
    endrn,edir=set_room(t_rpos,t_world)
    --lable room types
    for rn in all(t_rpos) do
        local rt=0
        if rn==startrn then
            rt=15+sdir
        elseif rn==endrn then
            rt=19+edir
        else
            local rx,ry=get_rpos(rn)
            for d=1,4 do
                local trn=get_rnum(rx+dirx[d],ry+diry[d])
                if trn==startrn then
                    if (d==sdir) rt+=2^(d-1)
                elseif trn==endrn then
                    if (d==edir) rt+=2^(d-1)
                elseif t_world[trn] then
                    rt+=2^(d-1)
                end
            end
        end
        f_world[rn]=rt
    end
    return f_world
end
--roomtype to map

rtpe2m=split([[
8
9
10
11
12,28
13
14,23
15
16
17,29
18,24
19
20,25
21,26
22,27
6
7
30
31
2
3
4
5]],"\n")
--old_rtpe2m={
--"8",--1
--"9",--2
--"10",--3
--"11",--4
--"12,28",--5
--"13",--6
--"14,23",--7
--"15",--8
--"16",--9
--"17,29",--10
--"18,24",--11
--"19",--12
--"20,25",--13
--"21,26",--14
--"22,27",--15
--"6",--16
--"7",--17
--"30",--18
--"31",--19
--"2",--20
--"3",--21
--"4",--22
--"5"--23
--}

function set_tiles(_world)
    local t_world={}
    for rn,rtpe in pairs(_world) do
        t_world[rn]=rndt(split(rtpe2m[rtpe],",",true))
    end
    return t_world
end

function set_room(t_rpos,t_world)
    local d
    repeat
        d=ceil(rnd(4))
        local trn=t_rpos[ceil(rnd(#t_rpos))]
        rx,ry=get_rpos(trn)
        rx+=dirx[d]
        ry+=diry[d]
        rn=get_rnum(rx,ry)
    until not t_world[rn] and trn~=startrn
    t_world[rn]=1
    return add(t_rpos,rn),d
end

function rndt(_t)
    return _t[ceil(rnd(#_t))]
end
-->8
--sash
function show_sash(_t,_c,_tc)
    sash_w=0
    sash_tw=5
    sash_c=_c
    sash_t=_t
    sash_tc=_tc or 7
    sash_frames=0
    sash_vis=true
    sash_tx=-#sash_t*4
    sash_ttx=64-(#sash_t*2)
    sash_delay_w=0
    sash_delay_t=15
    if player.y%128>64 then
        sash_y=34
        sash_ty=34
        sash_down=false
    else
        sash_y=94
        sash_ty=94
        sash_down=true
    end
end

function update_sash()
    if sash_vis then
        sash_frames+=1
        --animate width
        if sash_delay_w>0 then
            sash_delay_w-=1
        else
            sash_w+=(sash_tw-sash_w)/5
            if abs(sash_w-sash_tw)<0.4 then
                sash_w=sash_tw
            end
        end
        --animate text
        if sash_delay_t>0 then
            sash_delay_t-=1
        else
            sash_tx+=(sash_ttx-sash_tx)/10
            if abs(sash_tx-sash_ttx)<0.3 then
                sash_tx=sash_ttx
            end
        end
        --animate y position
        if sash_down then
            if player.y%128>78 then
                sash_ty=34
                sash_down=false
            end
        else
            if player.y%128<50 then
                sash_ty=94
                sash_down=true
            end
        end
        sash_y+=(sash_ty-sash_y)/6
        --make sash go away
        if sash_frames==75 then
            sash_tw=0
            sash_ttx=160
            sash_delay_w=15
            sash_delay_t=0
        end
        if sash_frames>105 then
            sash_vis=false
            for x=0,127 do
                add_particle(1,x+camx,sash_y+camy,0,0,rnd(15),{sash_c})
            end
        end
    end
end

function draw_sash()
    camera(0,0)
    if sash_vis then
        rectfill(0,sash_y-sash_w,128,sash_y+sash_w,sash_c)
        local _tc=sash_tc
--        if sash_tc>15 then
--            _tc=blink_r
--        end
        print(sash_t,sash_tx,sash_y-2,_tc)
    end
    camera(camx,camy)
end
-->8
--unlock system
function unlockpal(_n)
    local u=_n+9
    if dget(u)==0 then
        dset(u,1)
        return 1
    end
    return 0
end

function resetunlocks()
    for i=1,20 do
        dset(i+9,1)
    end
end

function setunlockpal()
    palstrs=split(pallist,"\n")
    for i=1,#unlockstrs do
        local u=i+9
        if dget(u)>0 then
            add(palstrs,unlockstrs[i])
        end
    end
end

function checkunlock()
    local d=stat(92)
    local m=stat(91)
    local u=0
    if (floor>=1) u+=unlockpal(1)
    if (floor>=2) u+=unlockpal(2)
    if (floor>=3) u+=unlockpal(3)
    if (floor>=4) u+=unlockpal(4)
    if (floor>=5) u+=unlockpal(5)
    if (totalkills>=25)   u+=unlockpal(6)
    if (totalkills>=50)   u+=unlockpal(7)
    if (totalkills>=100)  u+=unlockpal(8)
    if (totalkills>=420)  u+=unlockpal(9)
    if (totalkills>=1000) u+=unlockpal(10)
    if (floor>=6) u+=unlockpal(11)
    if (kills>=100) u+=unlockpal(12)
    if (flr(hit/shot*100)==100) u+=unlockpal(13)
    if (flr(hit/shot*100)==69) u+=unlockpal(14)
    if (flr(hit/shot*100)==0) u+=unlockpal(15)
    if (m==12 and d>20) u+=unlockpal(16)
    if (m==7 and d==8) u+=unlockpal(17)
    return u
end