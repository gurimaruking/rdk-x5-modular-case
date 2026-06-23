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
WALL=2.2; FLOOR=2.0; GAP=0.45;
BOTTOM_CLEAR=3.5;          // under PCB (pins, microSD)
TOP_CLEAR=20.0;            // above PCB top (tall USB ~16.5 + headroom for lip)
LEDGE=2.0;                 // perimeter ledge PCB rests on
LID_TOP=2.4;               // lid plate thickness
LIP_DEPTH=3.0;             // lid locating lip depth (in the clear zone)
LIP_W=1.8;
CHAM=1.4;                  // top outer edge chamfer

PCB_BOT=FLOOR+BOTTOM_CLEAR;
PCB_TOP=PCB_BOT+PCB_T;
WALL_TOP=PCB_TOP+TOP_CLEAR;

$fn = $preview ? 40 : 110;

// ---------- PCB outline (chamfered) ----------
module pcb_poly(){
    polygon([[PCB_CH,0],[PCB_W-PCB_CH,0],[PCB_W,PCB_CH],
             [PCB_W,PCB_D-PCB_CH],[PCB_W-PCB_CH,PCB_D],
             [PCB_CH,PCB_D],[0,PCB_D-PCB_CH],[0,PCB_CH]]);
}
module pcb_off(d){ offset(r=d) pcb_poly(); }
OUT = GAP+WALL;   // outer offset

// ============================================================
// PORT MAP  [edge,a0,a1,zmin,zmax,openTop,"label"]
//  edge R(X+) L(X-) F(Y-) B(Y+); a along edge; z rel PCB top
// ============================================================
PORTS=[
 ["R", 1.0,19.3,-4,14.0,1,"RJ45 LAN"],
 ["R",21.0,37.5,-3,16.5,1,"USB-A stack1"],
 ["R",38.9,55.4,-3,16.5,1,"USB-A stack2"],
 ["L",33.0,50.0,-3, 6.6,0,"HDMI"],
 ["L",23.5,31.8,-3, 5.3,0,"Audio 3.5mm"],
 ["F", 5.7,16.7,-3, 3.7,0,"USB-C power"],
 ["F",20.3,31.3,-3, 3.7,0,"USB-C data"],
 ["B", 6.0,59.0,-4,11.5,1,"40pin GPIO"],
 ["B",63.5,71.2,-3, 4.9,0,"Fan/PWR JST"],
];
CLR=0.6;

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
    z0=PCB_TOP-3.6; z1=PCB_TOP-1.0;
    translate([-(WALL+GAP)-1,19.5,z0]) cube([WALL+GAP+4,13.0,z1-z0]);
}
module floor_vents(){ for(i=[0:6],j=[0:5]) translate([32+i*4,18+j*4,-1]) cylinder(d=2.4,h=FLOOR+2); }
module foot_recess(){ for(p=[[9,8],[76,8],[9,48],[76,48]]) translate([p[0],p[1],-0.1]) cylinder(d=8,h=0.8); }

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
}

// ============================================================
// LID common: top plate + locating lip + top chamfer
// ============================================================
module lid_plate_2d(){ pcb_off(OUT); }
module lid_lip(){
    // sits in the clear zone (top LIP_DEPTH below WALL_TOP, above all conns)
    translate([0,0,WALL_TOP-LIP_DEPTH])
        linear_extrude(LIP_DEPTH)
            difference(){ pcb_off(GAP-0.3); pcb_off(GAP-0.3-LIP_W); }
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
// GPIO ribbon relief notch in the lid back edge (so a ribbon can exit up/back)
module gpio_relief(){
    translate([6,PCB_D-3,WALL_TOP-0.1]) cube([53,OUT+4,LID_TOP+1]);
}

module lid_closed(){ difference(){ lid_body(); slits(); gpio_relief(); } }

module lid_open(){
    difference(){
        union(){
            // outer frame only
            difference(){
                translate([0,0,WALL_TOP]) linear_extrude(LID_TOP-CHAM) lid_plate_2d();
                translate([0,0,WALL_TOP-0.1]) linear_extrude(LID_TOP+1) pcb_off(OUT-7);
            }
            lid_chamfer_frame();
            lid_lip();
            // two cross ribs
            for(a=[atan2(PCB_D,PCB_W),-atan2(PCB_D,PCB_W)])
                translate([PCB_W/2,PCB_D/2,WALL_TOP])
                    rotate([0,0,a]) translate([-PCB_W*0.62,-2,0]) cube([PCB_W*1.24,4,LID_TOP-CHAM]);
        }
        gpio_relief();
    }
}
module lid_chamfer_frame(){
    z=WALL_TOP+LID_TOP;
    difference(){
        hull(){
            translate([0,0,z-CHAM]) linear_extrude(0.01) pcb_off(OUT);
            translate([0,0,z-0.01]) linear_extrude(0.01) pcb_off(OUT-CHAM);
        }
        translate([0,0,WALL_TOP-1]) linear_extrude(LID_TOP+2) pcb_off(OUT-7);
    }
}

VESA=60; VHOLE=4.5; VBOSS=9; VBOSS_H=4;
module lid_vesa(){
    pts=[[PCB_W/2-VESA/2,PCB_D/2-VESA/2],[PCB_W/2+VESA/2,PCB_D/2-VESA/2],
         [PCB_W/2-VESA/2,PCB_D/2+VESA/2],[PCB_W/2+VESA/2,PCB_D/2+VESA/2]];
    difference(){
        union(){
            lid_body();
            for(p=pts) translate([p[0],p[1],WALL_TOP+LID_TOP-0.01]) cylinder(d=VBOSS,h=VBOSS_H);
        }
        for(p=pts) translate([p[0],p[1],WALL_TOP-1]) cylinder(d=VHOLE,h=LID_TOP+VBOSS_H+2);
        gpio_relief();
        // light slits front & back strips
        for(i=[0:6]){ translate([14+i*5,6,WALL_TOP-0.1]) cube([2.4,6,LID_TOP+1]);
                      translate([14+i*5,PCB_D-12,WALL_TOP-0.1]) cube([2.4,6,LID_TOP+1]); }
    }
}

// ============================================================
// RENDER SWITCH
// 0 base+board verify | 1 base | 2 closed | 3 open | 4 vesa
// 5 assembly(base+closed floated) | 6 board only
// ============================================================
SHOW=5;
module board_overlay(){ translate([0,0,PCB_TOP]) import("reference/rdk_x5_board.stl"); }

if(SHOW==0){ color([0.8,0.82,0.85,0.45]) case_base(); color([0.2,0.55,0.3]) board_overlay(); }
else if(SHOW==1) color([0.82,0.84,0.87]) case_base();
else if(SHOW==2) color([0.30,0.50,0.78]) lid_closed();
else if(SHOW==3) color([0.30,0.62,0.40]) lid_open();
else if(SHOW==4) color([0.85,0.70,0.25]) lid_vesa();
else if(SHOW==5){
    color([0.82,0.84,0.87]) case_base();
    translate([0,0,14]) color([0.30,0.50,0.78,0.92]) lid_closed();
}
else if(SHOW==6) board_overlay();
