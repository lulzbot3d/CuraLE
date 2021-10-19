;This G-Code has been generated specifically for the LulzBot TAZ 6 with a HS+ Tool Head
M73 P0 ; clear GLCD progress bar
M75 ; start GLCD timer
G26 ; clear potential 'probe fail' condition
M107 ; disable fans
M420 S0 ; disable leveling matrix
G90 ; absolute positioning
M82 ; set extruder to absolute mode
G92 E0 ; set extruder position to 0
M140 S{material_bed_temperature_layer_0} ; start bed heating up
G28 XY ; home X and Y
G1 X-19 Y258 F1000 ; move to safe homing position
M109 R{material_soften_temperature} ; soften filament before homing Z
G28 Z ; home Z
G1 E-15 F100 ; retract filament
G12                         ; wiping sequence
M109 R{material_probe_temperature} ; wait for extruder to reach probe temp
G1 X-10 Y293 F4000 ; move above first probe point
M204 S100 ; set probing acceleration
G29       ; start auto-leveling sequence
M420 S1   ; enable leveling matrix
M425 Z    ; use measured Z backlash for compensation
M425 Z F0 ; turn off measured Z backlash compensation. (if activated in the quality settings, this command will automatically be ignored)
M204 S500 ; restore standard acceleration
G1 X0 Y0 Z15 F5000 ; move up off last probe point
G4 S1 ; pause
M400 ; wait for moves to finish
M117 Heating... ; progress indicator message on LCD
M109 R{material_print_temperature_layer_0} ; wait for extruder to reach printing temp
M190 R{material_bed_temperature_layer_0} ; wait for bed to reach printing temp
G1 Z2 E0 F75 ; prime tiny bit of filament into the nozzle
M117 TAZ 6 Printing... ; progress indicator message on LCD
