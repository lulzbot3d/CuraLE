;This G-Code has been generated specifically for the {machine_name}

;SETTINGS
;Nozzle diameter = {machine_nozzle_size}mm
;Filament name = {material_brand} {material_name}
;Filament type = {material_type} {material_diameter}
;Filament weight = {filament_weight}
;Extruder temp = M109 S{material_print_temperature}
;Bed temp = M190 S{material_bed_temperature}

;The following lines can be uncommented for printer specific fine tuning
;More information can be found at https://marlinfw.org/meta/gcode/ (Note: current values are based on SE Tool Head)
;
;M92 E420                                   ;Set Axis Steps-per-unit
;M906 E960                                  ;TMC Motor Current
;
G90                                        ; absolute coordinate
M117 Starting {print_job_name}             ; progress indicator message on LCD
M140 S{material_bed_temperature_layer_0}   ; start bed heating up
M104 S{material_soften_temperature}        ; start extruder heating to probe temp
G28 O                                      ; Home all axis
M117 Heating...;                           ; progress indicator message on LCD
M190 S{material_bed_temperature_layer_0}   ; wait for bed to reach printing temp
M117 Probing...;                           ; progress indicator message on LCD
G29 O                                      ; start auto leveling
M420 S1                                    ; enable leveling matrix
M117 Heating...;                           ; progress indicator message on LCD
G0 X0 Y0 F5000
M109 R{material_print_temperature_layer_0} ; wait for extruder to reach initial printing temp
M117 Purging...;                           ; progress indicator message on LCD
G0 Z{layer_height_0} F1500                 ; move to initial layer height and bring extruder to 0
M82                                        ; set extruder to absolute mode
G92 E0                                     ; set extruder position to 0
G1 X10 E10 F400                            ; purge 10mm in a short move to the right
G1 Y1 E10.5 F300                           ; purge 0.5mm in a short move forward
G1 X0 E12.5 F250                           ; purge 2mm in a short move to the left
M8100 M{purge_pattern} N{machine_nozzle_size} F{material_diameter} ; purge material line if selected
G90                                        ; set movement position to absolute
M83                                        ; set extruder to relative mode
G0 E-1 F1800                               ; retract 1mm
G92 E0                                     ; set extruder position to 0
M82                                        ; set extruder to absolute mode
M117 {print_job_name};                     ; progress indicator message on LCD
;Start G-Code End