use <lulzbot_taz_components.scad>;
use <lulzbot_generic_components.scad>;
// use a / for sub-directory pathing

x = 280;
y = 280;
plate_thickness = 11;
print_surface(x, y, plate_thickness);

radius = 11;
washer_thickness = 1.5;
//Washers
translate([0, 0, plate_thickness]){
	cylinder(h = washer_thickness, r1 = radius, r2 = radius, center = false);
}

translate([x, 0, plate_thickness]){
	cylinder(h = washer_thickness, r1 = radius, r2 = radius, center = false);
}

translate([0, y, plate_thickness]){
	cylinder(h = washer_thickness, r1 = radius, r2 = radius, center = false);
}

translate([x, y, plate_thickness]){
	cylinder(h = washer_thickness, r1 = radius, r2 = radius, center = false);
}

//Wiper
rotate(a = [0, 0, 90]) {
	translate([20, 0, 0]) {
		wiper(x = 20, y = 0, z = 0);
	}
}