/*
 * RDK X5 Modular Case v2 — accurate, port-correct, simple functional design
 *
 * Connector positions extracted from the official STEP
 * (RDK_X5_LPDDR4_4266MHz_V1P0_pcb.stp) via FreeCAD bbox analysis.
 * See connector_map.md. Verified by overlaying the real board mesh.
 *
 * Frame: PCB bottom-left = origin. X 0..85, Y 0..56. Z=0 at floor bottom.
 * One base + three lids (closed / open / VESA). Aesthetic: chamfered top
 * edges + cooling slits. No screws — friction lip + optional M3 in corners.
 *
 * Author: Kazuki Murata / Robostadion     License: CC BY 4.0
 */

// ---------- core dimensions ----------
PCB_W=85; PCB_D=56; PCB_CH=3; PCB_T=1.6;
WALL=2.2; FLOOR=2.0; GAP=1.00;   // v5: 0.80→1.00 (実機印刷で基板がまだギチギチ・底まで座らない→さらに広げた)
BOTTOM_CLEAR=3.5;          // under PCB (pins, microSD)
TOP_CLEAR=20.0;            // above PCB top (tall USB ~16.5 + headroom for lip)
LEDGE=2.0;                 // perimeter ledge PCB rests on
LID_TOP=2.4;               // lid plate thickness
LIP_DEPTH=3.0;             // lid locating lip depth (in the clear zone)
LIP_W=1.8;
CHAM=1.4;                  // top outer edge chamfer
// --- press-fit (no screws) ---
//  per-side clearance between lid lip and base cavity wall.
//  0.10 = snug press fit (push to close, holds by friction).
//  v4: スリップフィット(0.10)に戻し、保持は下記のsnap bead/grooveで行う
//  → 蓋はスッと入って、最後にパチッと噛んで外れにくい
SNAP_CLEAR=0.02;   // v5.1: 0.05→0.02 (蓋がまだ気持ち緩い→さらに密着)
LEAD_IN=0.8;               // lip bottom lead-in chamfer height (eases insertion)
// --- snap-fit ring (base=凸リッジ / lid=凹溝, 一周) ---
//  ベース側キャビティ壁に一周のリッジ、蓋リップ外面に一周の溝。押し込むと
//  リップが少したわんでリッジを乗り越え、溝にカチッと落ちて保持する。
//  きつくて閉まらない→SNAP_BEAD下げる / 緩い→上げる
SNAP_BEAD=0.55;            // v5.1: 0.45→0.55 (まだ緩いのでカチッと更に強く). ridge protrusion = groove engagement depth

PCB_BOT=FLOOR+BOTTOM_CLEAR;
PCB_TOP=PCB_BOT+PCB_T;
WALL_TOP=PCB_TOP+TOP_CLEAR;
// NOTE: SNAP_Z depends on WALL_TOP, so it MUST be defined AFTER it. Defining it
// earlier left WALL_TOP undefined at that point -> SNAP_Z=undef -> snap_bead /
// snap_groove silently rendered empty (a likely cause of the loose-lid feel).
SNAP_Z=WALL_TOP-1.6;       // engagement height (within the lip zone)

$fn = $preview ? 40 : 110;

// ---------- PCB outline (chamfered) ----------
module pcb_poly(){
    polygon([[PCB_CH,0],[PCB_W-PCB_CH,0],[PCB_W,PCB_CH],
             [PCB_W,PCB_D-PCB_CH],[PCB_W-PCB_CH,PCB_D],
             [PCB_CH,PCB_D],[0,PCB_D-PCB_CH],[0,PCB_CH]]);
}
// NOTE: use offset(delta=) not offset(r=).  offset(r=negative) returns empty
// on this polygon in OpenSCAD 0.21, which silently broke every inward offset
// (lid lip ring, under-PCB recess, open-lid window). delta offsets reliably.
module pcb_off(d){ offset(delta=d) pcb_poly(); }
OUT = GAP+WALL;   // outer offset

// ============================================================
// PORT MAP  [edge,a0,a1,zmin,zmax,openTop,"label"]
//  edge R(X+) L(X-) F(Y-) B(Y+); a along edge; z rel PCB top
// ============================================================
PORTS=[
 // right edge: spans tightened to the real connector bbox so the dividers
 // between RJ45 / USB1 / USB2 stay ~2 mm thick (conns are only ~3.4 mm apart)
 // v3: right openings tightened to the connectors so USB/RJ45 dividers reach ~2.8 mm
 ["R", 2.0,18.6,-4,14.0,1,"RJ45 LAN"],
 ["R",21.9,36.6,-3,16.5,1,"USB-A stack1"],
 ["R",39.8,54.5,-3,16.5,1,"USB-A stack2"],
 // v3: HDMI+Audio MERGED into one opening (the 1.2 mm wall between them was too
 // fragile to print). Covers Y23.5..50, tall enough for HDMI.
 ["L",23.0,50.0,-3, 6.8,0,"HDMI + Audio"],
 ["F", 5.7,16.7,-3, 3.7,0,"USB-C power"],
 ["F",20.3,31.3,-3, 3.7,0,"USB-C data"],
 // v5.1: UART debug connector on the front edge (silk label "UART" at X≈42.9 in
 // the official DXF, between the MIPI-DSI and CSI connectors). The front wall
 // had no opening here, so the debug serial cable couldn't be plugged in.
 ["F",40.8,47.5,-3, 5.0,0,"UART debug"],
 ["B", 6.0,59.0,-4,11.5,1,"40pin GPIO"],
 ["B",63.5,71.2,-3, 4.9,0,"Fan/PWR JST"],
];
CLR=0.25;  // per-side opening clearance (tighter -> thicker port dividers)

module port_cut(p){
    e=p[0]; a0=p[1]-CLR; a1=p[2]+CLR;
    z0=PCB_TOP+p[3]; z1 = p[5]==1 ? WALL_TOP+1 : PCB_TOP+p[4]+CLR;
    thru=WALL+GAP+2;
    if(e=="R") translate([PCB_W-2,a0,z0]) cube([thru,a1-a0,z1-z0]);
    else if(e=="L") translate([-(WALL+GAP)-1,a0,z0]) cube([thru,a1-a0,z1-z0]);
    else if(e=="F") translate([a0,-(WALL+GAP)-1,z0]) cube([a1-a0,thru,z1-z0]);
    else if(e=="B") translate([a0,PCB_D-2,z0]) cube([a1-a0,thru,z1-z0]);
}
module microsd_slot(){
    // v4: 拡大(取り出しやすく)+ 指がかりの半円スカラップ
    z0=PCB_TOP-4.0; z1=PCB_TOP-0.6;
    translate([-(WALL+GAP)-1,18.5,z0]) cube([WALL+GAP+4,15.0,z1-z0]);
    // finger scallop: 壁の縁に半円の切り欠き(爪でカードを摘まめる)
    translate([-(WALL+GAP)-1,26.0,z0+(z1-z0)/2]) rotate([0,90,0])
        cylinder(d=9, h=WALL+GAP+4, $fn=40);
}
module floor_vents(){ for(i=[0:6],j=[0:5]) translate([32+i*4,18+j*4,-1]) cylinder(d=2.4,h=FLOOR+2); }
module foot_recess(){ for(p=[[9,8],[76,8],[9,48],[76,48]]) translate([p[0],p[1],-0.1]) cylinder(d=8,h=0.8); }

// snap ridge on the base cavity wall (一周凸). Triangular-ish for easy ride-over.
// Clipped at the port openings (tall USB/GPIO notches have no wall to back it).
module snap_bead(){
    difference(){
        union(){
            translate([0,0,SNAP_Z-0.5]) linear_extrude(0.5)
                difference(){ pcb_off(GAP); pcb_off(GAP-SNAP_BEAD*0.5); }   // lower ramp
            translate([0,0,SNAP_Z]) linear_extrude(0.9)
                difference(){ pcb_off(GAP); pcb_off(GAP-SNAP_BEAD); }       // full ridge
            translate([0,0,SNAP_Z+0.9]) linear_extrude(0.45)
                difference(){ pcb_off(GAP); pcb_off(GAP-SNAP_BEAD*0.5); }   // upper ramp
        }
        for(p=PORTS) port_cut(p);   // no bead across the open-top port notches
    }
}
// matching groove cut into the lid lip outer face (一周凹)
module snap_groove(){
    translate([0,0,SNAP_Z-0.35]) linear_extrude(1.6)
        difference(){ pcb_off(GAP-SNAP_CLEAR+0.3); pcb_off(GAP-SNAP_CLEAR-SNAP_BEAD-0.15); }
}

// chamfered top rim helper (outer top edge bevel)
module top_chamfer(offv){
    hull(){
        translate([0,0,WALL_TOP-CHAM]) linear_extrude(0.01) pcb_off(offv);
        translate([0,0,WALL_TOP-0.01]) linear_extrude(0.01) pcb_off(offv-CHAM);
    }
}

// ============================================================
// BASE
// ============================================================
module case_base(){
    union(){
        difference(){
            union(){
                linear_extrude(WALL_TOP-CHAM) pcb_off(OUT);
                top_chamfer(OUT);
            }
            // cavity for PCB + components
            translate([0,0,PCB_BOT]) linear_extrude(WALL_TOP) pcb_off(GAP);
            // under-PCB recess (PCB rests on LEDGE ring)
            translate([0,0,FLOOR]) linear_extrude(BOTTOM_CLEAR+0.01) pcb_off(GAP-LEDGE);
            // accurate ports
            for(p=PORTS) port_cut(p);
            microsd_slot();
            floor_vents();
            foot_recess();
        }
        // snap ridge inside the cavity (engages the lid groove). Clipped so it
        // doesn't grow into the port openings region too aggressively.
        snap_bead();
    }
}

// ============================================================
// LID common: top plate + locating lip + top chamfer
// ============================================================
module lid_plate_2d(){ pcb_off(OUT); }
module lid_lip(){
    // press-fit lip in the clear zone (above all connectors).
    // IMPORTANT: stays a RING at every level. (Never hull() a ring — the convex
    // hull of an annulus is a solid disk, which would plug the open lid.)
    lo = GAP - SNAP_CLEAR;        // outer offset -> press fit against cavity (pcb_off(GAP))
    li = lo - LIP_W;             // inner offset
    translate([0,0,WALL_TOP-LIP_DEPTH]){
        // lead-in: bottom ring inset on the OUTER face only (eases insertion)
        linear_extrude(LEAD_IN) difference(){ pcb_off(lo-0.4); pcb_off(li); }
        // main grip ring
        translate([0,0,LEAD_IN])
            linear_extrude(LIP_DEPTH-LEAD_IN) difference(){ pcb_off(lo); pcb_off(li); }
    }
}
module lid_chamfer_top(){
    // chamfer the lid's own top outer edge
    z=WALL_TOP+LID_TOP;
    hull(){
        translate([0,0,z-CHAM]) linear_extrude(0.01) pcb_off(OUT);
        translate([0,0,z-0.01]) linear_extrude(0.01) pcb_off(OUT-CHAM);
    }
}
module lid_body(){
    // plate from WALL_TOP up
    union(){
        translate([0,0,WALL_TOP]) linear_extrude(LID_TOP-CHAM) lid_plate_2d();
        lid_chamfer_top();
        lid_lip();
    }
}

// cooling slits (through the plate)
module slits(){
    sw=2.6; sp=5.0; len=PCB_D*0.62;
    n=floor((PCB_W-22)/sp);
    translate([12,(PCB_D-len)/2,WALL_TOP-0.1])
        for(i=[0:n-1]) translate([i*sp,0,0]) cube([sw,len,LID_TOP+1]);
}
// GPIO ribbon relief notch in the lid back edge (so a ribbon can exit up/back).
// IMPORTANT: cut through the locating LIP too (not just the top plate). The lip
// is a downward ring; over the GPIO the base port is open-top (no wall), so the
// lip there grips nothing and the leftover bar just blocks the ribbon. Extend
// the cut down past the lip bottom to fully clear the GPIO area.
module gpio_relief(){
    translate([6,PCB_D-3,WALL_TOP-LIP_DEPTH-0.1])
        cube([53,OUT+4,LIP_DEPTH+LID_TOP+1]);
}

module lid_closed(){ difference(){ lid_body(); slits(); gpio_relief(); snap_groove(); } }

OPEN_FRAME = 7;     // open-lid border frame width (mm)
HEX_R      = 4.8;   // honeycomb hex circumradius
HEX_WALL   = 1.6;   // wall thickness between hexes
// 2D honeycomb hole field (pointy-top hex grid)
module honeycomb_2d(W,H,R,wall){
    hx = R*sqrt(3); hy = R*1.5; rh = R - wall/sqrt(3);
    for(j=[0:ceil(H/hy)+1], i=[0:ceil(W/hx)+1])
        translate([i*hx + (j%2)*hx/2, j*hy]) circle(r=rh, $fn=6);
}
// Stylish ventilated lid: solid plate with a honeycomb vent field in the centre.
module lid_open(){
    b = OPEN_FRAME;
    difference(){
        lid_body();                       // full solid lid (plate + chamfer + clean lip ring)
        // honeycomb holes, clipped to the central area inside the border
        translate([0,0,WALL_TOP-1]) linear_extrude(LID_TOP+CHAM+3)
            intersection(){
                translate([b,b]) square([PCB_W-2*b, PCB_D-2*b]);
                translate([b,b]) honeycomb_2d(PCB_W-2*b, PCB_D-2*b, HEX_R, HEX_WALL);
            }
        gpio_relief();
        snap_groove();
    }
}

// Mount pattern. NOTE: the board is only 56 mm deep, so a real VESA-75/100
// monitor pattern does NOT fit. We use a 50 mm 4-hole pattern (M4) that sits
// FULLY on the lid (bosses never overhang the edge). For true VESA-75/100,
// print a separate adapter plate (roadmap).
VESA=50; VHOLE=4.5; VBOSS=9; VBOSS_H=4;
// safety: half-pattern + boss radius must stay inside the lid outline
LID_HALF_Y = PCB_D/2 + (GAP+WALL);   // lid reaches this far from center in Y
assert(VESA/2 + VBOSS/2 <= LID_HALF_Y,
       "VESA pattern too large: front/back bosses would overhang the lid edge");

module lid_vesa(){
    pts=[[PCB_W/2-VESA/2,PCB_D/2-VESA/2],[PCB_W/2+VESA/2,PCB_D/2-VESA/2],
         [PCB_W/2-VESA/2,PCB_D/2+VESA/2],[PCB_W/2+VESA/2,PCB_D/2+VESA/2]];
    difference(){
        union(){
            lid_body();
            // bosses on the UNDERSIDE (inside the case) so the lid still prints
            // top-face-down flat. They sit in the clear zone, away from tall ports.
            for(p=pts) translate([p[0],p[1],WALL_TOP-VBOSS_H]) cylinder(d=VBOSS,h=VBOSS_H+0.01);
        }
        // M4 clearance + countersink from the top (visible) face, through plate + boss
        for(p=pts) translate([p[0],p[1],WALL_TOP-VBOSS_H-1]) cylinder(d=VHOLE,h=LID_TOP+VBOSS_H+3);
        gpio_relief();
        // a few cooling slits down the centre line, clear of the bosses
        for(i=[0:4]) translate([PCB_W/2-12+i*6, PCB_D/2-7, WALL_TOP-0.1])
            cube([2.4,14,LID_TOP+1]);
        snap_groove();
    }
}

// ============================================================
// FAN LID — 40 mm fan mount (e.g. 4010: 40x40x10, 5V, 0.12A)
//  Central honeycomb intake grille (guard + airflow, matches lid_open style)
//  + 4x M3 holes at the 40 mm-fan 32 mm square pattern, with underside bosses
//  for thread engagement so the lid still prints top-face-down flat.
//  Fan sits on the TOP face and blows down onto the heatsink. Power the fan
//  from the 40-pin header 5V (pin 4) + GND (pin 6) — RDK X5's onboard J15 is a
//  JST-SH 1.0 mm 2-pin, which this fan's 2.5 mm plug does not fit.
// ============================================================
FAN_SIZE   = 40;     // fan body (40 mm fan)
FAN_HOLE   = 32;     // screw-hole spacing (standard 40 mm fan)
FAN_BORE   = 37;     // central airflow opening diameter (≈ blade sweep)
FAN_SCREW  = 2.75;   // M3 self-tap pilot hole through the boss
FAN_BOSS   = 6.0;    // boss outer diameter
FAN_BOSS_H = 3.0;    // boss height below the lid plate (adds thread depth)
module lid_fan(){
    cx=PCB_W/2; cy=PCB_D/2;
    pts=[[cx-FAN_HOLE/2,cy-FAN_HOLE/2],[cx+FAN_HOLE/2,cy-FAN_HOLE/2],
         [cx-FAN_HOLE/2,cy+FAN_HOLE/2],[cx+FAN_HOLE/2,cy+FAN_HOLE/2]];
    // safety: fan body must sit on the lid without overhanging the (56 mm-deep) edge
    assert(FAN_SIZE/2 <= PCB_D/2 + (GAP+WALL),
           "Fan too large: body would overhang the lid edge");
    difference(){
        union(){
            lid_body();
            // thread bosses on the UNDERSIDE (clear zone, above the heatsink),
            // so the lid prints top-face-down flat like the VESA lid.
            for(p=pts) translate([p[0],p[1],WALL_TOP-FAN_BOSS_H])
                cylinder(d=FAN_BOSS,h=FAN_BOSS_H+0.01);
        }
        // honeycomb intake grille, clipped to a circle under the fan
        translate([0,0,WALL_TOP-1]) linear_extrude(LID_TOP+CHAM+3)
            intersection(){
                translate([cx,cy]) circle(d=FAN_BORE);
                honeycomb_2d(PCB_W, PCB_D, HEX_R*0.8, HEX_WALL);
            }
        // M3 pilot holes through plate + boss
        for(p=pts) translate([p[0],p[1],WALL_TOP-FAN_BOSS_H-1])
            cylinder(d=FAN_SCREW,h=LID_TOP+FAN_BOSS_H+3);
        gpio_relief();
        snap_groove();
    }
}

// ============================================================
// RENDER SWITCH
// 0 base+board verify | 1 base | 2 closed | 3 open | 4 vesa | 15 fan
// 5 assembly(base+closed floated) | 6 board only
// print-ready: 11 base | 12 closed | 13 open | 14 vesa | 25 fan
// 99 ALL-ON-ONE-PLATE (base + 4 lids, print-oriented, for MakerWorld upload)
// ============================================================
SHOW=5;
module board_overlay(){ translate([0,0,PCB_TOP]) import("reference/rdk_x5_board.stl"); }

if(SHOW==0){ color([0.8,0.82,0.85,0.45]) case_base(); color([0.2,0.55,0.3]) board_overlay(); }
else if(SHOW==1) color([0.82,0.84,0.87]) case_base();
else if(SHOW==2) color([0.30,0.50,0.78]) lid_closed();
else if(SHOW==3) color([0.30,0.62,0.40]) lid_open();
else if(SHOW==4) color([0.85,0.70,0.25]) lid_vesa();
else if(SHOW==15) color([0.55,0.45,0.80]) lid_fan();
else if(SHOW==5){
    color([0.82,0.84,0.87]) case_base();
    translate([0,0,14]) color([0.30,0.50,0.78,0.92]) lid_closed();
}
else if(SHOW==6) board_overlay();
// ---- PRINT-READY orientations (flat on Z=0, optimal face down, no support) ----
// base: floor already down. lids: flipped top-face-down (lip points up).
else if(SHOW==11) translate([0,0,0]) case_base();
else if(SHOW==12) translate([0,0,WALL_TOP+LID_TOP]) rotate([180,0,0]) lid_closed();
else if(SHOW==13) translate([0,0,WALL_TOP+LID_TOP]) rotate([180,0,0]) lid_open();
else if(SHOW==14) translate([0,0,WALL_TOP+LID_TOP]) rotate([180,0,0]) lid_vesa();
else if(SHOW==25) translate([0,0,WALL_TOP+LID_TOP]) rotate([180,0,0]) lid_fan();
// ---- ALL PARTS ON ONE PLATE (print-oriented; min corner normalized to a 2x3 grid) ----
else if(SHOW==99){
    PX=96; PY=68; O=GAP+WALL;        // cell pitch + outer-offset normalizer
    // base (already floor-down): min corner (-O,-O) -> cell origin
    translate([0*PX+O, 0*PY+O, 0]) color([0.82,0.84,0.87]) case_base();
    // lids: print-oriented (flip top-face-down). After rotate([180]) the Y min
    // is -(PCB_D+O), so shift by (PCB_D+O) to land the min corner on the cell.
    translate([1*PX+O, 0*PY+(PCB_D+O), WALL_TOP+LID_TOP]) rotate([180,0,0]) color([0.30,0.50,0.78]) lid_closed();
    translate([0*PX+O, 1*PY+(PCB_D+O), WALL_TOP+LID_TOP]) rotate([180,0,0]) color([0.30,0.62,0.40]) lid_open();
    translate([1*PX+O, 1*PY+(PCB_D+O), WALL_TOP+LID_TOP]) rotate([180,0,0]) color([0.85,0.70,0.25]) lid_vesa();
    translate([0*PX+O, 2*PY+(PCB_D+O), WALL_TOP+LID_TOP]) rotate([180,0,0]) color([0.55,0.45,0.80]) lid_fan();
}
