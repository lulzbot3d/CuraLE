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

G4 S1                                              ; delay for 1 seconds to display file name
T0
M82                                                ; absolute extrusion mode
M73 P0                                             ; clear GLCD progress bar
M75			     	                               ; start GLCD timer
M107                                               ; disable fans
G90                                                ; absolute positioning
M140 S{material_bed_temperature_layer_0}           ; begin bed temping up
M104 S{material_soften_temperature_0} T0           ; soften filament
M104 S{material_soften_temperature_1} T1           ; soften filament
G28 O                                              ; home all axes
G0 X145 Y187 Z156 F3000                            ; move away from endstops
M280 P1 S125                                       ; raise extruders for cleaner probing
M117 Tramming X Axis...;                           ; Progress indicator message on LCD
G30 X150 Y150                                      ; probe to locate bed
G34                                                ; tram X-axis
M117 Leveling Print Bed...;                        ; Progress indicator message on LCD
G29                                                ; start auto-leveling sequence
M280 P1 S75                                        ; bring extruder 1 back down
M420 S1                                            ; enable leveling matrix
T{second_extruder_nr}                              ; ensure we're using the SECOND extruder
G0 {purge_start_location_sec} Z5 F6000             ; move to initial extruder purge start location
M400                                               ; clear buffer
M117 Final Heating... Please Wait.;                ; progress indicator message on LCD
M190 R{material_bed_temperature_layer_0}           ; get bed temping up during first layer
M104 S{material_print_temperature_layer_0_0} T0    ; set extruder temps
M104 S{material_print_temperature_layer_0_1} T1    ; set extruder temps
M109 R{material_print_temperature_layer_0_sec}     ; set extruder temp and wait
M400                                               ; clear buffer
M117 Purging...;
M300 T                                             ; play sound at start of first layer
G92 E0                                             ; set extruder to zero
G0 Z{layer_height_0} F1500                         ; move to initial layer height
G91                                                ; relative positioning
M82                                                ; set extruder to absolute mode
G1 X10 E10 F400                                    ; purge 10mm in a short move to the left
G1 Y1 E10.5 F300                                   ; purge 0.5mm in a short move forward
G1 X-10 E13 F250                                   ; purge 2.5mm in a short move to the right
M8100 M{purge_pattern_sec} N{machine_nozzle_size_sec} F{material_diameter_sec} ; purge material line if selected
G90                                                ; set movement position to absolute
M83                                                ; set extruder to relative mode
G0 E-1 F1800                                       ; retract 1mm
G92 E0                                             ; set extruder position to 0
M82                                                ; set extruder to absolute mode
G0 Z10 F1500                                       ; raise extruder
M104 S{material_standby_temperature_sec}           ; set second extruder to standby temperature
M117 Heating...;
T{initial_extruder_nr}                             ; swap to INITIAL extruder
G0 {purge_start_location_init} Z5 F6000            ; move to initial extruder purge start location
M109 R{material_print_temperature_layer_0_init}    ; set extruder temp and wait
M117 Purging...;
G0 Z{layer_height_0} F6000                         ; move to initial layer height
G91                                                ; relative positioning
M82                                                ; set extruder to absolute mode
G92 E0                                             ; set extruder position to 0
G1 X10 E10 F400                                    ; purge 10mm in a short move to the left
G1 Y1 E10.5 F300                                   ; purge 0.5mm in a short move forward
G1 X-10 E13 F250                                   ; purge 2.5mm in a short move to the right
M8100 M{purge_pattern_1} N{machine_nozzle_size_1} F{material_diameter_1} ; purge material line if selected
G90                                                ; set movement position to absolute
M83                                                ; set extruder to relative mode
G0 E-1 F1800                                       ; retract 1mm
G92 E0                                             ; set extruder position to 0
M82                                                ; set extruder to absolute mode
M117 {jobname}...
;Start G-Code End