module print_surface(
x = 10,
y = 10,
plate_thickness = 2
) {
	cube(size = [x, y, plate_thickness], center = false);
}

print_surface();