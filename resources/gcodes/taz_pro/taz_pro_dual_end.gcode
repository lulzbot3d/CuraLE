M400                                              ; wait for moves to finish
M140 S{material_part_removal_temperature}         ; start cooling bed
M107                                              ; fans off
G91                                               ; relative positioning
G1 E-1 F300                                       ; retract the filament a bit before lifting the nozzle, to release some of the pressure
G1 Z20 E-1 X-20 Y-20 F2000                        ; move Z up a bit and retract filament even more
M109 S{material_print_temperature_0} T0           ; T0 to print temp
M109 S{material_print_temperature_1} T1           ; T1 to print temp
G90                                               ; absolute positioning
G0 X0 Y0 F3000                                    ; move to cooling position
G91                                               ; relative positioning
M117 Purging for next print;                        progress indicator message
T0
G92 E-30                                          ; set extruder position to purge amount
G1 E0 F100                                        ; purge
G1 E-3 F200                                       ; retract slightly to prevent ooze
M104 S0 T0                                        ; T0 hotend off
T1
G92 E-30                                          ; set extruder position to purge amount
G1 E0 F100                                        ; purge
G1 E-3 F200                                       ; retract slightly to prevent ooze
M104 S0 T1                                        ; T1 hotend off
M117 Cooling, please wait;                          progress indicator message
M190 R{material_part_removal_temperature}         ; wait for bed to cool off
G0 Y280 F3000                                     ; present finished print
M140 S{material_keep_part_removal_temperature_t}  ; keep temperature or cool downs
M77			                                      ; stop GLCD timer
M18 X E				                              ; turn off x y and e axis
G90                                               ; absolute positioning
M117 Print complete;                                progress indicator message

