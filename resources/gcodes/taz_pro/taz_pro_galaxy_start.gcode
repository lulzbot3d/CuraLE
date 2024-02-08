;This G-Code has been generated specifically for the {machine_name}
;
;SETTINGS
;Nozzle diameter = {machine_nozzle_size}mm
;Filament name = {material_brand} {material_name}
;Filament type = {material_type} {material_diameter}
;Filament weight = {filament_weight}
;Extruder temp = M109 S{material_print_temperature}
;Bed temp = M190 S{material_bed_temperature}
;
;The following lines can be uncommented for printer specific fine tuning
;More information can be found at https://marlinfw.org/meta/gcode/
;
;M92 E420                                  ;Set Axis Steps-per-unit
;M906 E960                                 ;TMC Motor Current
;
G4 S1                                      ; delay for 1 seconds to display file name
M104 S{material_soften_temperature}        ; start soften filament before retraction
M140 S{material_bed_temperature_layer_0}   ; start bed heating up
M117 Homing for Engine Start...;           ; progress indicator message on LCD
G28O                                       ; home all axes
M73 P0                                     ; clear LCD progress bar
M75                                        ; Start LCD Print Timer
G26                                        ; clear potential 'probe fail' condition
M107                                       ; disable fans
M420 S0                                    ; disable leveling matrix
M900 K{linear_advance}                     ; set linear advance
G90                                        ; absolute positioning
M82                                        ; set extruder to absolute mode
G92 E0                                     ; set extruder position to 0
G0 X145 Y187 Z156 F3000                    ; move away from endstops
M117 Heating Phase Initiated...;           ; progress indicator message on LCD
M109 S{material_soften_temperature}        ; soften filament before retraction
M117 Retracting Hotend Filament...;        ; progress indicator message on LCD
G1 E-7 F75                                 ; retract filament
G92 E-12                                   ; set extruder position to -12 to account for 5mm retract at end of previous print
M109 R{material_wipe_temperature}          ; wait for extruder to reach wiping temp
M104 S{material_probe_temperature}         ; start cooling to probe temp during wipe
M106 S255                                  ; turn fan on to help drop temp
; Use M206 below to adjust nozzle wipe position (Replace "{machine_nozz1e_z_offset}" to adjust Z value)
; X ~ (+)left/(-)right, Y ~ (+)front/(-)back, Z ~ (+)down/(-)up
M206 X0 Y0 Z{machine_nozzle_z_offset}      ; restoring offsets and adjusting offset if AST285 is enabled
M117 Commencing Nozzle Wipe...;            ; progress indicator message on LCD
G12                                        ; wiping sequence
M206 X0 Y0 Z0                              ; reseting stock nozzle position ### CAUTION: changing this line can affect print quality ###
M107                                       ; turn off part cooling fan
M104 S{material_probe_temperature}         ; set probe temp
M117 Sending Space Probes...;              ; Progress indicator message on LCD
M204 S300                                  ; set probing acceleration
G29                                        ; start auto-leveling sequence
M104 S{material_print_temperature_layer_0} ; start extruder to reach initial printing temp
M420 S1                                    ; enable leveling matrix
M204 S2000                                 ; restore standard acceleration
G1 X5 Y15 Z10 F8000                        ; move up off last probe point
G4 S1                                      ; pause
M400                                       ; wait for moves to finish
M117 Reaching Mission Temp...;             ; progress indicator message on LCD
M109 S{material_bed_temperature_layer_0}   ; wait for bed heating up
M109 R{material_print_temperature_layer_0} ; wait for extruder to reach initial printing temp
G1 Z2 E0 F75                               ; prime tiny bit of filament into the nozzle
M300 T                                     ; play sound at start of first layer
M117 {print_job_name};                     ; progress indicator message on LCD
;Start G-Code End