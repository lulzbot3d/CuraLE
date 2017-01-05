module wiper(
x = 10,
y = 10,
z = 3
) {
	translate([x, y, z]){
		import("wiper_mount_v1.1.stl");

		//wiper pad itself
		translate([5, 5, 0]){
			cube(size = [90, 6.5, 12.5], center = false);
		}
	}
}

wiper();