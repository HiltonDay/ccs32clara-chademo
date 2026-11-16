// ============================================================================
// Parametric 3D Model with Dynamic Rear Cylindrical Arc & Cable Pass-Through
// ============================================================================

// --- User-Adjustable Parameters ---
height      = 46.2;  // Total extrusion height of the part (Z-axis, in mm)
cable_d     = 15.0;  // Diameter of the cylindrical cable channel (15 mm)
cut_depth   = 10.5;  // Depth of the cable cut into the arc
tip_width_x = 11.0; // Width/thickness of the angled front tip in +X direction (default = 10.92 mm)

// --- Rear Cylindrical Arc Settings (Adjust freely; geometry updates automatically) ---
cyl_arc_x = 15.40; // X-coordinate of the rear arc cylinder center
cyl_arc_y = 58.00; // Y-center to make plateau height difference 3.95 mm
arc_d     = 25.0;  // Outer diameter of the rear cylindrical arc (ؘ 25 mm)
arc_r     = arc_d / 2.0; // Radius of the rear cylindrical arc (12.5 mm)

// --- Cable Channel Orientation ---
arc_angle = 90;    // Angular position of the cable channel along the arc (degrees)

// ============================================================================
// Automatic Geometry Calculations (Do not edit below unless changing base shape)
// ============================================================================

// Front tip +X offset relative to baseline (10.92 mm).
// Positive values widen the angled tip in +X direction; negative values narrow it.
tip_dx = tip_width_x - 10.92;

// Reference corner where the tapered front transitions into the right main wall (shifts in +X)
p3_x = 20.58 + tip_dx;
p3_y = 23.94;

// 1. Calculate the exact tangent point from P3 onto the rear arc cylinder.
//    This prevents any bump or step regardless of cylinder position, diameter, or tip width.
dx        = cyl_arc_x - p3_x;
dy        = cyl_arc_y - p3_y;
dist_p3_c = sqrt(dx * dx + dy * dy);     // Distance from P3 to cylinder center
base_ang  = atan2(dy, dx);               // Angle from P3 to cylinder center
alpha     = asin(arc_r / dist_p3_c);     // Tangent offset angle
tang_ang  = (base_ang - alpha) - 90;     // Normal angle to the tangent point

tan_x = cyl_arc_x + arc_r * cos(tang_ang); // X-coordinate of tangent point
tan_y = cyl_arc_y + arc_r * sin(tang_ang); // Y-coordinate of tangent point

// 2. Calculate the exact intersection between the arc cylinder and the rear plateau line.
//    Plateau line equation: y = m_plat * x + b_plat
m_plat = -0.06024;
b_plat = 66.55;

// Quadratic coefficients (A_q * x^2 + B_q * x + C_q = 0) for line-circle intersection
A_q = 1 + m_plat * m_plat;
B_q = 2 * (m_plat * (b_plat - cyl_arc_y) - cyl_arc_x);
C_q = cyl_arc_x * cyl_arc_x + pow(b_plat - cyl_arc_y, 2) - arc_r * arc_r;

// Leftmost intersection point where the plateau cleanly meets the cylinder
plat_meet_x = (-B_q - sqrt(max(0, B_q * B_q - 4 * A_q * C_q))) / (2 * A_q);
plat_meet_y = m_plat * plat_meet_x + b_plat;

// 3. Calculate the center coordinates for the cable pass-through cylinder
arc_mid_x = cyl_arc_x + arc_r * cos(arc_angle); // Outer surface point on the arc
arc_mid_y = cyl_arc_y + arc_r * sin(arc_angle);
offset_in = cut_depth - (cable_d / 2.0);        // Radial offset to achieve cut_depth
cable_x   = arc_mid_x - offset_in * cos(arc_angle);
cable_y   = arc_mid_y - offset_in * sin(arc_angle);

// ============================================================================
// 3D Solid Construction
// ============================================================================

difference() {
    // Combine the extruded main body with the true cylindrical rear arc
    union() {
        linear_extrude(height = height) {
            polygon(points = [
                [19.59,          0.00],       // P1: Front-left corner of the tapered tip
                [30.51 + tip_dx, 5.11],       // P2: Front-right corner of the tapered tip (grows in +X)
                [p3_x,           p3_y],       // P3: Inner corner transitioning to right wall (grows in +X)
                [tan_x,          tan_y],      // Auto-calculated tangent point into rear cylinder
                [cyl_arc_x,      cyl_arc_y],  // Cylinder center (anchors polygon inside circle)
                [plat_meet_x,    plat_meet_y], // Auto-calculated junction with the rear plateau
                [ 0.00,         66.55],       // Rear-left corner of the plateau
                [ 1.18,         17.01],       // Left wall corner meeting the front step-in
                [ 9.17,         17.96]        // Inner step-in corner leading to the tapered tip
            ]);
        }

        // True cylinder forming the smooth rear arc (d = 25 mm)
        translate([cyl_arc_x, cyl_arc_y, 0])
            cylinder(h = height, d = arc_d, $fn = 96);
    }

    // Subtract the horizontal cable channel at mid-height (Z = height / 2, d = 15 mm)
    translate([cable_x, cable_y, height / 2])
        rotate([0, 0, arc_angle])           // Align radially with the chosen arc angle
        rotate([90, 0, 0])                  // Lay cylinder horizontally across the arc
        cylinder(h = 100, d = cable_d, center = true, $fn = 64);
}
