use <lulzbot_taz_components.scad>;
use <lulzbot_generic_components.scad>;
// use a / for sub-directory pathing

x = 280;
y = 280;
plate_thickness = 11;
print_surface(x, y, plate_thickness);

radius = 11;
offset = 22;
translate([-radius, -radius]) {
	all_bed_corners(x = x, y = y, offset = offset);
}

//Wiper
rotate(a = [0, 0, 90]) {
	translate([20, 0, 0]) {
		wiper(x = 20, y = 0, z = 0);
	}
}