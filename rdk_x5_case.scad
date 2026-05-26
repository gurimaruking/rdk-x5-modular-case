/*
 * RDK X5 Modular Case — for D-Robotics RDK X5 8GB Dev Kit
 *
 * Concept: One common base + interchangeable lids.
 *   - lid_default : closed lid with cooling slits (this file)
 *   - lid_camera  : MIPI CSI cable pass-through (planned)
 *   - lid_mount   : wall/frame mount with M3 inserts (planned)
 *   - lid_open    : ventilation cutout for stock heatsink (planned)
 *
 * Author      : Kazuki Murata / Robostadion
 * License     : CC-BY 4.0 (please credit when remixing)
 * Source data : Official D-Robotics DXF V1P0 (board outline 85x56 mm, C3 chamfered corners)
 *
 * Render hint : set $fn = 64 for final STL export
 */

// =============================================================================
// PARAMETERS (edit these to remix)
// =============================================================================

// --- PCB geometry (from official DXF) ---
PCB_W       = 85.0;    // PCB width  (X)
PCB_D       = 56.0;    // PCB depth  (Y)
PCB_CHAMFER = 3.0;     // corner chamfer cut
PCB_T       = 1.6;     // FR4 thickness

// --- Component clearance ---
TOP_CLEAR    = 18.0;   // height above PCB (heatsink + connectors)
BOTTOM_CLEAR = 3.0;    // gap below PCB for solder points / SD card

// --- Case wall ---
WALL         = 2.0;    // outer wall thickness
FLOOR        = 2.0;    // base floor thickness
LID_TOP      = 2.0;    // lid top plate thickness
PCB_FIT_GAP  = 0.4;    // gap around PCB for insertion (each side)

// --- Base/Lid join ---
JOIN_PIN_D   = 2.8;    // locating pin diameter on base
JOIN_PIN_H   = 3.0;    // locating pin height
JOIN_HOLE_D  = 3.2;    // matching hole diameter on lid
M3_HEAD_D    = 6.0;    // M3 cap head clearance
M3_SHANK_D   = 3.4;    // M3 shank clearance
M3_TAP_D     = 2.7;    // self-tap into PLA/PETG

// --- Cooling slits on Default Lid ---
SLIT_W       = 2.5;
SLIT_GAP     = 3.0;    // slit pitch = SLIT_W + SLIT_GAP
SLIT_LEN_FACTOR = 0.65;  // slit length as fraction of usable width

// --- Open Lid (frame only) ---
OPEN_FRAME_W = 6.0;    // outer frame width
OPEN_RIB_W   = 4.0;    // diagonal rib width
OPEN_USE_RIBS = true;  // X-shaped cross ribs for rigidity

// --- VESA Mount Lid ---
// VESA 75 = 75x75 mm M4 hole pattern (fits inside ~89x60 case footprint
// only when the rotated diagonal allows; we use 60x60 reduced pattern as
// fallback for boards smaller than 90mm. Both modes selectable.)
VESA_MODE    = 60;     // 75 = VESA-75, 60 = compact 60x60 (fits inside RDK X5 case)
VESA_HOLE_D  = 4.5;    // M4 clearance
VESA_BOSS_D  = 9.0;    // boss diameter around each hole
VESA_BOSS_H  = 4.0;    // boss height above lid surface
VESA_RECESS  = 2.0;    // recess for M4 head (cap or countersunk)

// --- Render selector ---
// 0 = assembly preview (base + default lid offset for clarity)
// 1 = base only (export as STL)
// 2 = lid_default only (export as STL)
// 3 = lid_open only (export as STL)
// 4 = lid_vesa only (export as STL)
// 5 = pcb outline 2D check (DXF cross-reference)
SHOW = 0;

$fn = $preview ? 32 : 64;

// =============================================================================
// DERIVED DIMENSIONS
// =============================================================================

CASE_W = PCB_W + 2 * (PCB_FIT_GAP + WALL);
CASE_D = PCB_D + 2 * (PCB_FIT_GAP + WALL);
CASE_H_BASE = FLOOR + BOTTOM_CLEAR + PCB_T + TOP_CLEAR;
CASE_CHAMFER = PCB_CHAMFER + WALL;  // align outer chamfer with PCB chamfer

// PCB origin inside case (relative to case bottom-left corner)
PCB_X = WALL + PCB_FIT_GAP;
PCB_Y = WALL + PCB_FIT_GAP;
PCB_Z = FLOOR + BOTTOM_CLEAR;

// Locating pin positions (4 corners, inside the wall, away from chamfer)
PIN_INSET = WALL + 1.0;
PIN_POS = [
    [PIN_INSET + 6,           PIN_INSET + 6],
    [CASE_W - PIN_INSET - 6,  PIN_INSET + 6],
    [PIN_INSET + 6,           CASE_D - PIN_INSET - 6],
    [CASE_W - PIN_INSET - 6,  CASE_D - PIN_INSET - 6],
];

// =============================================================================
// MODULES — PCB OUTLINE (from official DXF V1P0)
// =============================================================================

// 2D outline of the actual RDK X5 PCB (origin = PCB's own (0,0))
module pcb_outline_2d() {
    polygon(points = [
        [3,         PCB_D],     // top edge left start
        [PCB_W - 3, PCB_D],     // top edge right
        [PCB_W,     PCB_D - 3], // top-right chamfer
        [PCB_W,     3],         // right edge bottom
        [PCB_W - 3, 0],         // bottom-right chamfer
        [3,         0],         // bottom edge left
        [0,         3],         // bottom-left chamfer
        [0,         PCB_D - 3], // left edge top
    ]);
}

// Same outline expanded by `gap` for fit clearance
module pcb_outline_2d_expanded(gap = 0) {
    offset(r = gap) pcb_outline_2d();
}

// Case outer footprint (PCB outline + wall + fit gap, with chamfered corners
// that follow the PCB shape — looks "designed-for" rather than generic)
module case_outer_2d() {
    pcb_outline_2d_expanded(gap = PCB_FIT_GAP + WALL);
}

// =============================================================================
// MODULES — BASE
// =============================================================================

module base_locating_pins() {
    for (p = PIN_POS) {
        translate([p[0], p[1], FLOOR + BOTTOM_CLEAR + PCB_T + TOP_CLEAR - LID_TOP])
            cylinder(d = JOIN_PIN_D, h = JOIN_PIN_H);
    }
}

module case_base() {
    difference() {
        union() {
            // Outer shell
            linear_extrude(CASE_H_BASE - LID_TOP)
                case_outer_2d();
        }
        // Inner cavity for PCB + components
        translate([WALL, WALL, FLOOR])
            linear_extrude(CASE_H_BASE)
                pcb_outline_2d_expanded(gap = PCB_FIT_GAP);

        // Below-PCB cavity (slightly narrower for PCB to rest on a lip)
        translate([WALL + 2, WALL + 2, FLOOR - 0.01])
            linear_extrude(BOTTOM_CLEAR + 0.02)
                pcb_outline_2d_expanded(gap = PCB_FIT_GAP - 2);

        // ---- Connector cutouts (TODO: refine after measuring on actual board) ----
        // For now, a wide cutout on the RIGHT edge (where USB-C/USB/HDMI/Eth usually go)
        // and a smaller cutout on the FRONT edge (where 40-pin header / SD card sit).
        // These are deliberately generous placeholders.

        // Right edge — main I/O ports
        translate([CASE_W - WALL - 0.1,
                   WALL + 8,
                   FLOOR + BOTTOM_CLEAR + 1])
            cube([WALL + 1, CASE_D - 2 * (WALL + 8), TOP_CLEAR - 4]);

        // Front edge — GPIO and SD card (placeholder)
        translate([WALL + 10,
                   -0.1,
                   FLOOR + BOTTOM_CLEAR + 1])
            cube([CASE_W - 2 * (WALL + 10), WALL + 1, TOP_CLEAR - 6]);

        // Bottom ventilation (small grid under SoC area)
        translate([PCB_X + 30, PCB_Y + 20, -0.01])
            linear_extrude(FLOOR + 0.02)
                for (i = [0:3], j = [0:3])
                    translate([i * 4, j * 4, 0]) circle(d = 2);
    }

    // Add locating pins on top edge for lid alignment
    base_locating_pins();
}

// =============================================================================
// MODULES — DEFAULT LID
// =============================================================================

module lid_cooling_slits() {
    slit_pitch = SLIT_W + SLIT_GAP;
    usable_w = CASE_W - 2 * (WALL + 4);
    usable_d = CASE_D - 2 * (WALL + 6);
    slit_count = floor(usable_w / slit_pitch);
    slit_len = usable_d * SLIT_LEN_FACTOR;

    translate([WALL + 4, (CASE_D - slit_len) / 2, -0.01]) {
        for (i = [0:slit_count - 1]) {
            translate([i * slit_pitch, 0, 0])
                cube([SLIT_W, slit_len, LID_TOP + 0.02]);
        }
    }
}

module lid_default() {
    difference() {
        // Top plate
        linear_extrude(LID_TOP) case_outer_2d();

        // Cooling slits
        lid_cooling_slits();

        // Locating pin holes
        for (p = PIN_POS) {
            translate([p[0], p[1], -0.01])
                cylinder(d = JOIN_HOLE_D, h = LID_TOP + 0.02);
        }
    }

    // Inner lip — drops into the base cavity to prevent rattle
    translate([0, 0, -1.5])
        difference() {
            linear_extrude(1.5)
                pcb_outline_2d_expanded(gap = PCB_FIT_GAP + WALL - 1.0);
            linear_extrude(1.5)
                pcb_outline_2d_expanded(gap = PCB_FIT_GAP + WALL - 2.5);
        }
}

// =============================================================================
// MODULES — OPEN LID (frame with central cutout, max airflow)
// =============================================================================

module lid_open() {
    difference() {
        // Outer ring frame
        linear_extrude(LID_TOP) {
            difference() {
                case_outer_2d();
                // central cutout
                offset(r = -OPEN_FRAME_W) case_outer_2d();
            }
        }
        // Locating pin holes
        for (p = PIN_POS) {
            translate([p[0], p[1], -0.01])
                cylinder(d = JOIN_HOLE_D, h = LID_TOP + 0.02);
        }
    }

    // Optional X-cross ribs for rigidity (do not block heatsink airflow much)
    if (OPEN_USE_RIBS) {
        center = [CASE_W / 2, CASE_D / 2];
        rib_len = sqrt(CASE_W*CASE_W + CASE_D*CASE_D) - 2 * OPEN_FRAME_W;
        rib_angle = atan2(CASE_D, CASE_W);

        // Two ribs forming an X, but skip the very center so heatsink is fully exposed
        for (a = [rib_angle, -rib_angle]) {
            translate([center[0], center[1], 0])
                rotate([0, 0, a])
                    difference() {
                        translate([-rib_len/2, -OPEN_RIB_W/2, 0])
                            cube([rib_len, OPEN_RIB_W, LID_TOP]);
                        // central clear zone (50x40 over SoC)
                        rotate([0, 0, -a])
                            translate([-25, -20, -0.1])
                                cube([50, 40, LID_TOP + 0.2]);
                    }
        }
    }

    // Inner lip (same as default for fit)
    translate([0, 0, -1.5])
        difference() {
            linear_extrude(1.5)
                pcb_outline_2d_expanded(gap = PCB_FIT_GAP + WALL - 1.0);
            linear_extrude(1.5)
                pcb_outline_2d_expanded(gap = PCB_FIT_GAP + WALL - 2.5);
        }
}

// =============================================================================
// MODULES — VESA MOUNT LID
// =============================================================================

module lid_vesa() {
    half = VESA_MODE / 2;
    vesa_points = [
        [CASE_W / 2 - half, CASE_D / 2 - half],
        [CASE_W / 2 + half, CASE_D / 2 - half],
        [CASE_W / 2 - half, CASE_D / 2 + half],
        [CASE_W / 2 + half, CASE_D / 2 + half],
    ];

    // Verify VESA holes fit inside the case footprint
    margin_check = (CASE_W / 2 - half) >= 4 && (CASE_D / 2 - half) >= 4;
    if (!margin_check) {
        echo("WARNING: VESA pattern too large for case footprint. Reduce VESA_MODE.");
    }

    difference() {
        union() {
            // Top plate
            linear_extrude(LID_TOP) case_outer_2d();
            // Reinforcement bosses around VESA holes
            for (p = vesa_points)
                translate([p[0], p[1], LID_TOP - 0.01])
                    cylinder(d = VESA_BOSS_D, h = VESA_BOSS_H);
        }

        // VESA through-holes
        for (p = vesa_points)
            translate([p[0], p[1], -0.01])
                cylinder(d = VESA_HOLE_D, h = LID_TOP + VESA_BOSS_H + 0.02);

        // Recesses for M4 cap heads (on the outer/visible side)
        for (p = vesa_points)
            translate([p[0], p[1], LID_TOP + VESA_BOSS_H - VESA_RECESS])
                cylinder(d = VESA_BOSS_D - 1.0,
                         h = VESA_RECESS + 0.01);

        // Locating pin holes
        for (p = PIN_POS) {
            translate([p[0], p[1], -0.01])
                cylinder(d = JOIN_HOLE_D, h = LID_TOP + 0.02);
        }

        // Small cooling slits in the unused area (between VESA bosses and edge)
        slit_pitch = SLIT_W + SLIT_GAP;
        // Front strip
        for (i = [0:6]) {
            translate([WALL + 6 + i * slit_pitch, WALL + 3, -0.01])
                cube([SLIT_W, 5, LID_TOP + 0.02]);
            translate([WALL + 6 + i * slit_pitch, CASE_D - WALL - 8, -0.01])
                cube([SLIT_W, 5, LID_TOP + 0.02]);
        }
    }

    // Inner lip
    translate([0, 0, -1.5])
        difference() {
            linear_extrude(1.5)
                pcb_outline_2d_expanded(gap = PCB_FIT_GAP + WALL - 1.0);
            linear_extrude(1.5)
                pcb_outline_2d_expanded(gap = PCB_FIT_GAP + WALL - 2.5);
        }
}

// =============================================================================
// MAIN RENDER SWITCH
// =============================================================================

if (SHOW == 0) {
    // Assembly preview — lid floated above for clarity
    case_base();
    translate([0, 0, CASE_H_BASE - LID_TOP + 8])
        color([0.3, 0.5, 0.8, 0.9]) lid_default();
    // Reference PCB
    translate([PCB_X, PCB_Y, PCB_Z])
        color([0.2, 0.6, 0.2, 0.6])
            linear_extrude(PCB_T) pcb_outline_2d();
}
else if (SHOW == 1) {
    case_base();
}
else if (SHOW == 2) {
    lid_default();
}
else if (SHOW == 3) {
    lid_open();
}
else if (SHOW == 4) {
    lid_vesa();
}
else if (SHOW == 5) {
    pcb_outline_2d();
}
