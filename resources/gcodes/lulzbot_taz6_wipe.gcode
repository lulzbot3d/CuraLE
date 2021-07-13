;This G-Code has been generated specifically for the LulzBot TAZ 6 with standard extruder
G26 ; clear potential 'probe fail' condition
G21 ; set units to Millimetres
M107 ; disable fans
G90 ; absolute positioning
M82 ; set extruder to absolute mode
G92 E0 ; set extruder position to 0
M109 S{material_soften_temperature} ; start heating hot end
G28 XY ; home X and Y
G1 X-19 Y258 F1000 ; move to safe homing position
G28 Z ; home Z
M109 R{material_soften_temperature} ; soften filament before homing Z
G1 E-30 F100 ; retract filament
M109 R{material_wipe_temperature} ; wait for extruder to reach wiping temp
M117 Wiping Nozzle... ; message
G1 X-17 Y100 F3000 ; move above wiper pad
G1 Z1 ; push nozzle into wiper
G1 X-19 Y95 F1000 ; slow wipe
G1 X-19 Y90 F1000 ; slow wipe
G1 X-19 Y85 F1000 ; slow wipe
G1 X-17 Y90 F1000 ; slow wipe
G1 X-19 Y80 F1000 ; slow wipe
G1 X-17 Y95 F1000 ; slow wipe
G1 X-17 Y75 F2000 ; fast wipe
G1 X-17 Y65 F2000 ; fast wipe
G1 X-19 Y70 F2000 ; fast wipe
G1 X-17 Y60 F2000 ; fast wipe
G1 X-19 Y55 F2000 ; fast wipe
G1 X-17 Y50 F2000 ; fast wipe
G1 X-19 Y40 F2000 ; fast wipe
G1 X-17 Y45 F2000 ; fast wipe
G1 X-19 Y35 F2000 ; fast wipe
G1 X-17 Y40 F2000 ; fast wipe
G1 X-19 Y70 F2000 ; fast wipe
G1 X-17 Y30 Z2 F2000 ; fast wipe
G1 X-19 Y35 F2000 ; fast wipe
G1 X-17 Y25 F2000 ; fast wipe
G1 X-19 Y30 F2000 ; fast wipe
G1 X-17 Y25 Z1.5 F1000 ; slow wipe
G1 X-19 Y23 F1000 ; slow wipe
G1 Z10 ; raise extruder
M117 Wiping Complete. ; final message
