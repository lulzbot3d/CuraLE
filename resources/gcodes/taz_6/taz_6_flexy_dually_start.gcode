;This G-Code has been generated specifically for the {machine_name}

;SETTINGS
;Extruder 1
;Nozzle diameter = {machine_nozzle_size_0}mm
;Filament name = {material_brand_0} {material_name_0}
;Filament type = {material_type_0} {material_diameter_0}
;Filament weight = {filament_weight}
;Extruder temp = M109 S{material_print_temperature_0}

;Extruder 2
;Nozzle diameter = {machine_nozzle_size_1}mm
;Filament name = {material_brand_1} {material_name_1}
;Filament type = {material_type_1} {material_diameter_1}
;Filament weight = {filament_weight_1}
;Extruder temp = M109 S{material_print_temperature_1}

;Bed temp = M190 S{material_bed_temperature}

M73 P0                                            ;resetting progress bar on LCD
G26                                               ; clear potential 'probe fail' condition
M107                                              ; disable fans
M420 S0                                           ; disable leveling matrix
M900 K{linear_advance}                            ; set linear advance
G90                                               ; absolute positioning
T0                                                ; select this extruder first
M82                                               ; set extruder to absolute mode
G92 E0                                            ; set extruder position to 0
M140 S{material_bed_temperature_layer_0}          ; get bed heating up
M104 S{material_soften_temperature_0} T0          ; set T0 to soften temp
M109 S{material_soften_temperature_1} T1          ; soften filament and wait
M109 S{material_soften_temperature_0} T0          ; soften filament and wait
G28 X Y                                           ; home X and Y
G1 X-19 Y258                                      ; move over the Z_MIN switch
M104 S{material_wipe_temperature_0} T0            ; set T0 to wipe temp
M109 S{material_wipe_temperature_1} T1            ; wait for T1 to reach temp
M109 S{material_wipe_temperature_0} T0            ; wait for T0 to reach temp
G28 Z                                             ; home Z
G1 E-15 F100                                      ; suck up XXmm of filament
T1                                                ; switch extruders
M82                                               ; set extruder to absolute mode
G92 E0                                            ; set E to 0
G1 E-15 F100                                      ; suck up filament
T0                                                ; switch extruders
G92 E-15                                          ; adjust E value
G1 X-17 Y100 F3000                                ; move above wiper pad
G1 Z1                                             ; push nozzle into wiper
G1 X-19 Y95 F1000                                 ; slow wipe
G1 X-17 Y90 F1000                                 ; slow wipe
G1 X-19 Y85 F1000                                 ; slow wipe
G1 X-17 Y90 F1000                                 ; slow wipe
G1 X-19 Y80 F1000                                 ; slow wipe
G1 X-17 Y95 F1000                                 ; slow wipe
G1 X-19 Y75 F2000                                 ; fast wipe
G1 X-17 Y85 F2000                                 ; fast wipe
G1 X-19 Y80 F2000                                 ; fast wipe
G1 X-17 Y70 F2000                                 ; fast wipe
G1 X-19 Y75 F2000                                 ; fast wipe
G1 X-17 Y95 F1000                                 ; slow wipe
G1 X-19 Y90 F1000                                 ; slow wipe
G1 X-17 Y85 F1000                                 ; slow wipe
G1 X-19 Y90 F1000                                 ; slow wipe
G1 X-17 Y80 F1000                                 ; slow wipe
G1 X-19 Y95 F1000                                 ; slow wipe
G1 X-17 Y75 F2000                                 ; fast wipe
G1 X-19 Y85 F2000                                 ; fast wipe
G1 X-17 Y80 F2000                                 ; fast wipe
G1 X-19 Y90 F2000                                 ; fast wipe
G1 X-17 Y85 F2000                                 ; fast wipe
G1 Z10                                            ; raise extruder
M109 S{material_probe_temperature_0}              ; heat to probe temp
G1 X-9 Y-9                                        ; move above first probe point
M204 S100                                         ; set accel for probing
G29                                               ; probe sequence (for auto-leveling)
M204 S500                                         ; set accel back to normal
M420 S1                                           ; enable leveling matrix
G1 X0 Y0 Z15 F5000                                ; get out the way
M400                                              ; clear buffer
M104 S{material_print_temperature_layer_0_0} T0   ; set extruder temp
M109 S{material_print_temperature_layer_0_1} T1   ; set extruder temp
M109 S{material_print_temperature_layer_0_0} T0   ; set extruder temp and wait
T1                                                ; switch to second extruder
G1 E0 F100                                        ; prime nozzle from previous print
G1 F100 E-{retraction_amount}                     ;retract second nozzle before print
G92 E0                                            ; adjust to 1st nozzle e value
T0                                                ; switch back to first extruder
M190 R{material_bed_temperature_layer_0}          ; get bed temping up during first layer
G1 Z2 E0 F75                                      ; extrude filament back into nozzle
M117 TAZ Printing...                              ; LCD status message
