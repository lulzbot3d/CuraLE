;This G-Code has been generated specifically for the LulzBot TAZ Workhorse with SE Tool Head
M73 P0 ; clear GLCD progress bar
M75 ; start GLCD timer
G26 ; clear potential 'probe fail' condition
M107 ; disable fans
M420 S0 ; disable previous leveling matrix
G90 ; absolute positioning
M82 ; set extruder to absolute mode
G92 E0 ; set extruder position to 0
M140 S{material_bed_temperature_layer_0} ; start bed heating up
M109 R{material_soften_temperature} ; soften filament before homing Z
G28 ; Home all axis
G1 E-15 F100 ; retract filament
M109 R{material_wipe_temperature}                  ; wait for extruder to reach wiping temp
G12                         ; wiping sequence
M109 R{material_probe_temperature} ; wait for extruder to reach probe temp
G1 X288 Y-10 F4000; move above first probe point
M204 S100 ; set probing acceleration
G29       ; start auto-leveling sequence
M420 S1   ; activate bed level matrix
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
M117 TAZ Workhorse Printing... ; progress indicator message on LCD
