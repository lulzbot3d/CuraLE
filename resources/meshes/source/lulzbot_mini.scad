use <lulzbot_generic_components.scad>;

$fn = 50;
x = 150;
y = 150;
plate_thickness = 11;

module bed_plate() {
	translate([0, 0, 0]){
		import("mini_bed_mount_plate_revC_simplified.stl");
	}
}

module glass() {
	translate([15, 15, 7]){
		cube(size = [170, 170, 4], center = false);
	}
}

all_bed_corners(x = x, y = y, offset = 50);
wiper(x = 50, y = 187, z = 3);
bed_plate();
glass();
//probe_points();