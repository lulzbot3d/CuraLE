M400                                              ; wait for moves to finish
M140 S{material_part_removal_temperature}         ; start cooling bed
M107                                              ; fans off
M106 S255 P1                                      ; turn on bed fan
G91                                               ; relative positioning
G0 Z50                                            ; move up 50mm
G90                                               ; absolute positioning
G1 X145 Y0 F3000                                  ; move to cooling position
M83                                               ; relative extrude
T0
G0 E-14                                           ; retract 14mm
T1
G0 E-14                                           ; retract 14mm
T0
M82                                               ; absolute extrude
M104 S0 T0                                        ; T0 hotend off
M104 S0 T1                                        ; T1 hotend off
M117 Active Cooling in Progress, Please Wait;       progress indicator message
M190 R{material_part_removal_temperature}         ; wait for bed to cool off
M107 P1                                           ; turn off bed fan
G0 Y280 F3000                                     ; present finished print
M140 S{material_keep_part_removal_temperature_t}  ; keep temperature or cool downs
M77			                                      ; stop GLCD timer
M18 E				                              ; turn off x y and e axis
G90                                               ; absolute positioning
M117 Print Complete.;                               progress indicator message
M2 R                                              ; bring up end of print screen
