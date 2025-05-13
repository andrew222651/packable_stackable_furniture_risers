// ---------------- User parameters ----------------------------
wall_thickness = 2;      // wall + top thickness  (mm)
height         = 20;     // total outside height  (mm)

top_x  = 90;             // outer size at z = height (mm)
top_y  = 100;

bottom_x = 100;           // outer size just above the lip (mm)
bottom_y = 110;

lip_h        = 1;        // vertical lip height (mm)

// --- Wheel trough -------------------------------------------
trough_len   = 72;       // length along Y (mm)
trough_w     = 29;       // chord width along X (mm)
trough_d     = 5;        // sagitta / depth (mm)
//--------------------------------------------------------------

// ------------- Derived dimensions ---------------------------
inner_top_x     = top_x  - 2*wall_thickness;
inner_top_y     = top_y  - 2*wall_thickness;

inner_bottom_x  = inner_top_x + (bottom_x - top_x);
inner_bottom_y  = inner_top_y + (bottom_y - top_y);

taper_h         = height - lip_h;   // height of the tapered section

groove_w     = wall_thickness * 1.1;        // groove width   (mm)
groove_d     = lip_h;        // groove depth   (mm)

outer_scale = [ top_x  / bottom_x,
                top_y  / bottom_y ];

inner_scale = [ inner_top_x / inner_bottom_x,
                inner_top_y / inner_bottom_y ];

// distance between centre-lines (mm)
groove_pitch = inner_bottom_x + 2*(1/2)*groove_w;
// Half distance from the Y-axis to each groove centre
groove_off = groove_pitch / 2;

// radius that gives the requested width & depth
trough_r     = (trough_d*trough_d +
                (trough_w/2)*(trough_w/2)) / (2*trough_d);
// vertical offset of the cylinder centre above the top plane
trough_off   = trough_r - trough_d;

// -------------- helper modules ------------------------------
module outer_shell() {
    // vertical lip
    translate([-bottom_x/2, -bottom_y/2, 0])
        cube([bottom_x, bottom_y, lip_h]);

    // tapered part above the lip
    translate([0, 0, lip_h])
        linear_extrude(height = taper_h,
                       scale   = outer_scale,
                       center  = false)
            square([bottom_x, bottom_y], center = true);
}

module inner_cavity() {
    // cavity under the lip
    translate([-inner_bottom_x/2, -inner_bottom_y/2, 0])
        cube([inner_bottom_x, inner_bottom_y, lip_h]);

    // tapered cavity, stops 2 mm below the top
    translate([0, 0, lip_h])
        linear_extrude(height = taper_h - wall_thickness,
                       scale   = inner_scale,
                       center  = false)
            square([inner_bottom_x, inner_bottom_y], center = true);
}

module top_grooves() {
    // a groove is simply a shallow rectangular cut
    groove_len = bottom_x + 10;               // long enough to overshoot
    for (y = [ -groove_off,  groove_off ])    // two positions, symmetric
        translate([ -groove_len/2, y - groove_w/2,
                    height - groove_d ])      // z position: 1 mm into top
            cube([ groove_len, groove_w, groove_d ]);
}

module wheel_trough() {
    // Cylinder axis along Y; length = trough_len
    translate([ 0, 0, height + trough_off ])
        rotate([90, 0, 0])            // z-axis → y-axis
            cylinder(r = trough_r,
                     h = trough_len,
                     center = true,
                     $fn = 128);      // fine enough for a smooth curve
}

module wheel_trough_outer() {
    translate([ 0, 0, height + trough_off ])
        rotate([90, 0, 0])            // z-axis → y-axis
            cylinder(r = trough_r + wall_thickness,
                     h = trough_len,
                     center = true,
                     $fn = 128);      // fine enough for a smooth curve
}

// --------------- main model ---------------------------------
union() {
    difference() {
        union() {
            outer_shell();
        }
        union() {
            inner_cavity();   // hollows the inside
            top_grooves();    // cuts the two alignment grooves
            wheel_trough();
        }
    }
    difference() {
        wheel_trough_outer();
        union() {
            wheel_trough();
            translate([ -bottom_x/2, -bottom_y/2, height ])
                cube([ 100, 100, 100 ]);
        }
    }
}