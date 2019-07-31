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
M109 R{material_wipe_temperature} ; wait for extruder to reach wiping temp
G1 X-15 Y100 F3000 ; move above wiper pad
G1 Z1 ; push nozzle into wiper
G1 X-17 Y95 F1000 ; slow wipe
G1 X-17 Y90 F1000 ; slow wipe
G1 X-17 Y85 F1000 ; slow wipe
G1 X-15 Y90 F1000 ; slow wipe
G1 X-17 Y80 F1000 ; slow wipe
G1 X-15 Y95 F1000 ; slow wipe
G1 X-17 Y75 F2000 ; fast wipe
G1 X-15 Y65 F2000 ; fast wipe
G1 X-17 Y70 F2000 ; fast wipe
G1 X-15 Y60 F2000 ; fast wipe
G1 X-17 Y55 F2000 ; fast wipe
G1 X-15 Y50 F2000 ; fast wipe
G1 X-17 Y40 F2000 ; fast wipe
G1 X-15 Y45 F2000 ; fast wipe
G1 X-17 Y35 F2000 ; fast wipe
G1 X-15 Y40 F2000 ; fast wipe
G1 X-17 Y70 F2000 ; fast wipe
G1 X-15 Y30 Z2 F2000 ; fast wipe
G1 X-17 Y35 F2000 ; fast wipe
G1 X-15 Y25 F2000 ; fast wipe
G1 X-17 Y30 F2000 ; fast wipe
G1 X-15 Y25 Z1.5 F1000 ; slow wipe
G1 X-17 Y23 F1000 ; slow wipe
G1 Z50 ; raise extruder
G1 X140 ; move head to center of travel
M104 S0 ; turn off hot end
M117 Wiping Complete ; finish message
