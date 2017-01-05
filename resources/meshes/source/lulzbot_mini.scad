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

//Flexible bed corners

module bed_corner(
	x = 0,
	y = 0,
	angle = 0
) {
	z_translation = 3.25;
	translate([x, y, z_translation]){
		rotate(angle, v=[]){
			import("bed_corner_v2.7.stl");
		}
	}
}

module auto_leveling_bed_corner(
	x = 0,
	y = 0,
	z = 11,
	inner_radius = 1.7, 
	outer_radius = 11, 
	washer_thickness = 1.5,
	angle = 0
) {
	z_translation = 3.25;
	translate([x, y, 0]) {
		rotate(angle, v=[]) {
	
			//Washer
			translate([outer_radius, outer_radius, z]) {
				cylinder(
					h = washer_thickness,
					r1 = outer_radius,
					r2 = outer_radius,
					center = false);
			}
		
			//Pillar
			%translate([outer_radius, outer_radius, 0]) {
				cylinder(
					h = z,
					r1 = inner_radius,
					r2 = inner_radius,
					center = false);
			}
			
			//Flexible bed corners
			translate([0, 0, z_translation]) {
				import("bed_corner_v2.7.stl", center = false);
			}
		}
	}
}

module all_bed_corners(
	x = x,
	y = y
) {
	offset = 50;
	auto_leveling_bed_corner(0, 0, angle = 0);
	auto_leveling_bed_corner(x+offset, 0, angle = 90);
	auto_leveling_bed_corner(x+offset, y+offset, angle = 180);
	auto_leveling_bed_corner(0, y+offset, angle = 270);
}

all_bed_corners();
wiper(x = 50, y = 187, z = 3);
bed_plate();
glass();
//probe_points();