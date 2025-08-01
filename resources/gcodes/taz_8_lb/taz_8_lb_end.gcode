M400                                              ; wait for moves to finish
M140 S{material_part_removal_temperature}         ; start bed cooling
M104 S0                                           ; disable hotend
M107                                              ; disable fans
G92 E14                                           ; set extruder to 14mm for retract on print end
M117 Cooling please wait                          ; progress indicator message on LCD
G91                                               ; relative positioning
G0 Z50                                            ; move up 50mm
G90                                               ; absolute positioning
G1 X145 Y0 F3000                                  ; move to cooling position
M83                                               ; relative extrude
G0 E-14                                           ; retract 14mm
M82                                               ; absolute extrude
M190 R{material_part_removal_temperature}         ; wait for bed to cool down to removal temp
G1 Y610 F2000                                     ; present finished print
M140 S{material_keep_part_removal_temperature_t}  ; keep temperature or cool down
M77                                               ; End LCD Print Timer
G90                                               ; absolute positioning
M18 E                                             ; turn off x and e axis
M117 Print Complete.;                               progress indicator message
M2 R                                              ; bring up end of print screen