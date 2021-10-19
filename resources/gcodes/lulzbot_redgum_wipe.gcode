;This G-Code has been generated specifically for the LulzBot TAZ Workhorse
M75 ; start GLCD timer
G26 ; clear potential 'probe fail' condition
M107 ; disable fans
M420 S0 ; disable previous leveling matrix
G90 ; absolute positioning
M82 ; set extruder to absolute mode
G92 E0 ; set extruder position to 0
M109 R{material_soften_temperature} ; soften filament before homing Z
G28 ; Home all axis
G1 E-30 F100 ; retract filament
G12                         ; wiping sequence
