; This profile is designed specifically for LulzBot TAZ Workhorse 3D Printer with the Dual Extruder v3
M73 P0 ; clear GLCD progress bar
M75 ; start GLCD timer
G26 ; clear potential 'probe fail' condition
M107 ; disable fans
M420 S0 ; disable leveling matrix
G90 ; absolute positioning
M104 S{material_soften_temperature_0} T0 ; soften filament
M104 S{material_soften_temperature_1} T1 ; soften filament
M140 S{material_bed_temperature}; get bed heating up
G28 X Y ; home X and Y
G1 X-26 F3000 ; clear X endstop
G1 Y19 F3000 ; move over the Z_MIN switch
M117 Heating... ; LCD status message
M109 R{material_soften_temperature_0} T0 ; wait for temp
M109 R{material_soften_temperature_1} T1 ; wait for temp
G1 X0 F3000
T0 ; return to first extruder
G28 Z ; home Z
T0 ; select this extruder first
M82 ; set extruder to absolute mode
G92 E0 ; set extruder to zero
G1 E-15 F100 ; suck up XXmm of filament
T1 ; switch extruders
M82 ; set extruder to absolute mode
G92 E0 ; set extruder to zero
G1 E-15 F100 ; suck up XXmm of filament
M104 S{material_wipe_temperature_0} T0 ; set to wipe temp
M104 S{material_wipe_temperature_1} T1 ; set to wipe temp
M106 ; Turn on fans to speed cooling
T0 ; switch extruder
G28 X ; Home X
G1 X-26 Y100 F3000 ; move above wiper pad
M104
M117 Cooling... ; LCD status message
M109 R{material_wipe_temperature_0} T0 ; wait for T0 to reach temp
M109 R{material_wipe_temperature_1} T1 ; wait for T1 to reach temp
M107 ; Turn off fan
T0 ; switch extruders
G1 Z1 ; push nozzle into wiper
G1 X -26 Y95 F1000 ; slow wipe
G1 X -26 Y90 F1000 ; slow wipe
G1 X -26 Y85 F1000 ; slow wipe
G1 X -25 Y90 F1000 ; slow wipe
G1 X -26 Y80 F1000 ; slow wipe
G1 X -25 Y95 F1000 ; slow wipe
G1 X -26 Y75 F2000 ; fast wipe
G1 X -25 Y65 F2000 ; fast wipe
G1 X -26 Y70 F2000 ; fast wipe
G1 X -25 Y60 F2000 ; fast wipe
G1 X -26 Y55 F2000 ; fast wipe
G1 X -25 Y50 F2000 ; fast wipe
G1 X -26 Y40 F2000 ; fast wipe
G1 X -25 Y45 F2000 ; fast wipe
G1 X -26 Y35 F2000 ; fast wipe
G1 X -25 Y40 F2000 ; fast wipe
G1 X -26 Y70 F2000 ; fast wipe
G1 X -25 Y30 Z2 F2000 ; fast wipe
G1 X -26 Y35 F2000 ; fast wipe
G1 X -25 Y25 F2000 ; fast wipe
G1 X -26 Y30 F2000 ; fast wipe
G1 X -25 Y25 Z1.5 F1000 ; slow wipe
G1 X -26 Y23 F1000 ; slow wipe
G1 X -25 Z15 ; raise extruder
M109 R{material_probe_temperature_0} ; heat to probe temp
M204 S100 ; set accel for probing
G29 ; probe sequence (for auto-leveling)
M420 S1 ; enable leveling matrix
M425 Z ; use measured Z backlash for compensation
M425 Z F0 ; turn off measured Z backlash compensation. (if activated in the quality settings, this command will automatically be ignored)
M204 S500 ; set accel back to normal
M104 S{material_print_temperature_0} T0 ; set extruder temp
M104 S{material_print_temperature_1} T1; set extruder temp
G1 X100 Y-25 Z0.5 F3000 ; move to open space
M400 ; clear buffer
M117 Heating... ; LCD status message
M109 R{material_print_temperature_0} T0 ; set extruder temp and wait
M109 R{material_print_temperature_1} T1; set extruder temp and wait
M117 Purging... ; LCD status message
T0 ; select this extruder first
G1 E0 F100 ; undo retraction
G92 E-15 ; set extruder negative amount to purge
G1 E0 F100 ; purge XXmm of filament
T1 ; switch to second extruder
G92 E-15 ; set extruder negative amount to purge
G1 E0 F100 ; undo retraction
G92 E-15 ; set extruder negative amount to purge
G1 E0 F100 ; purge XXmm of filament
G1 Z0.5 ; clear bed (barely)
G1 X100 Y0 F5000 ; move above bed to shear off filament
T0 ; switch to first extruder
M190 R{material_bed_temperature_layer_0}; get bed temping up during first layer
G1 Z2 E0 F75
M400 ; clear buffer
M117 TAZ Workhorse Printing... ; LCD status message
