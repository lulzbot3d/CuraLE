$fn = 50;
x = 150;
y = 150;
plate_thickness = 11;

module washer_and_pillar(
x = 0,
y = 0,
z = 11,
inner_radius = 1.7, 
outer_radius = 11, 
washer_thickness = 1.5
) {
	//outer
	translate([x, y, z]){
		cylinder(
			h = washer_thickness,
			r1 = outer_radius,
			r2 = outer_radius,
			center = false);
	}

	//inner
	translate([x, y, 0]){
		cylinder(
			h = z,
			r1 = inner_radius,
			r2 = inner_radius,
			center = false);
	}
}

x_hole_dist = 178;
y_hole_dist = 178;
module all_washers() {
	x_offset = 11;
	y_offset = 11;

	washer_and_pillar(
		x_offset,
		y_offset
	);
	
	washer_and_pillar(
		x_offset,
		y_offset+y_hole_dist
	);
	
	washer_and_pillar(
		x_offset+x_hole_dist,
		y_offset
	);
	
	washer_and_pillar(
		x_offset+x_hole_dist,
		y_offset+y_hole_dist
	);
}


translate([0, 0, 0]){
	import("mini_bed_mount_plate_revC_simplified.stl");
}

module glass() {
	translate([15, 15, 7]){
		cube(size = [170, 170, 4], center = false);
	}
}

//Flexible bed corners
z_translation = 3.25;
module bed_corner(
x = 0,
y = 0,
angle = 0
) {
	translate([x, y, z_translation]){
		rotate(angle, v=[]){
			import("bed_corner_v2.7.stl");
		}
	}
}
module all_bed_corners() {
	bed_corner(0, 0, 0);
	bed_corner(x_hole_dist+22, 0, 90);
	bed_corner(x_hole_dist+22, y_hole_dist+22, 180);
	bed_corner(0, y_hole_dist+22, 270);
}

module wiper() {
	translate([50, 187, 3]){
		import("wiper_mount_v1.1.stl");
		translate([5, 5, 0]){
			cube(size = [90, 6.5, 13], center = false);
		}
	}
}

wiper();
all_bed_corners();
glass();
all_washers();