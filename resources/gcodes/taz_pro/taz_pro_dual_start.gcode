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

T0
M82                                                ;absolute extrusion mode
M73 P0                                             ; clear GLCD progress bar
M75			     	                               ; start GLCD timer
M107                                               ; disable fans
G90                                                ; absolute positioning
M420 S0                                            ; disable previous leveling matrix
M140 S{material_bed_temperature_layer_0}           ; begin bed temping up
M104 S{material_soften_temperature_0} T0           ; soften filament
M104 S{material_soften_temperature_1} T1           ; soften filament
G28                                                ; home
M117 Heating...                                    ; LCD status message
M109 R{material_soften_temperature_0} T0           ; wait for temp
M109 R{material_soften_temperature_1} T1           ; wait for temp
T0                                                 ; select this extruder first
M82                                                ; set extruder to absolute mode
G92 E0                                             ; set extruder to zero
G1 E-10 F100                                       ; retract 10mm of filament on first extruder
G0 X50 F1000                                       ; move over to switch extruders
T1                                                 ; switch extruders
M82                                                ; set extruder to absolute mode
G92 E0                                             ; set extruder to zero
G1  E-10 F100                                      ; retract 10mm of filament on second extruder
M104 S{material_wipe_temperature_0} T0             ; set to wipe temp
M104 S{material_wipe_temperature_1} T1             ; set to wipe temp
M106                                               ; turn on fans to speed cooling
T0                                                 ; select first extruder for probing
M117 Cooling...                                    ; LCD status message
M109 R{material_wipe_temperature_0} T0             ; wait for T0 to reach temp
M109 R{material_wipe_temperature_1} T1             ; wait for T1 to reach temp
G12                                                ; wipe sequence
M107                                               ; turn off fan
G0 X247 F1000                                      ; move over to switch extruders
T0                                                 ; switch to first extruder
M109 R{material_probe_temperature_0}               ; heat to probe temp
M204 S100                                          ; set accel for probing
G29                                                ; probe sequence (for auto-leveling)
M420 S1                                            ; enable leveling matrix
M204 S500                                          ; set accel back to normal
M104 S{material_print_temperature_layer_0_0}  T0   ; set extruder temp
M104 S{material_print_temperature_layer_0_1}  T1   ; set extruder temp
G1 X120 Y-29 Z10 F3000                             ; move to open space
M400                                               ; clear buffer
M117 Heating...                                    ; LCD status message
M109 R{material_print_temperature_layer_0_0}  T0   ; set extruder temp and wait
M109 R{material_print_temperature_layer_0_1}  T1   ; set extruder temp and wait
M117 Purging...                                    ; LCD status message
T0                                                 ; select this extruder first
G1 E0 F100		    	                           ; undo retraction
G92 E-30				                           ; set extruder negative amount to purge
G1 E0 F100				                           ; purge XXmm of filament
G1 E-3 F200                                        ; purge retraction
G1 Z1.00                                           ; clear bed (barely)
G1 X120 Y5.45 F4000                                ; move above bed to shear off filament
M106 S255                                          ; turn on fan
G4 S7                                              ; wait 7 seconds
M107                                               ; turn off fan
G1 X120 Y-29 Z5.45 F3000                           ; move to open space
T1                                                 ; set extruder
G1 E0 F100                                         ; undo retraction
G92 E-30                                           ; set extruder negative amount to purge
G1 E0 F100                                         ; purge XXmm of filament
G1 E-4 F200                                        ; purge retraction
G1 Z1.00                                           ; clear bed (barely)
G1 X120 Y10 F4000                                  ; move above bed to shear off filament
G0 Z5.45
T0                                                 ; set extruder
M190 R{material_bed_temperature_layer_0}           ; get bed temping up during first layer
G1 Z2 E0 F75                                       ; raise head and 0 extruder
M82					                               ; set to absolute mode
M400                                               ; clear buffer
M300 T                                             ; play sound at startr of first layer
M117 Printing {print_job_name}...                           ; LCD status message
;Start G-Code End
