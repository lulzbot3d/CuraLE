x = 150;
y = 150;
plate_thickness = 11;

radius = 11;
washer_thickness = 1.5;

cube(size = [x, y, plate_thickness], center = false);

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

translate([20, y, 0]){
	import("wiper_mount_v1.1.stl");
}