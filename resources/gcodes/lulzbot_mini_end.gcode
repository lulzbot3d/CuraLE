M400                           ; wait for moves to finish
M104 S0                        ; hotend off
M140 S0                        ; bed heater off
M107                           ; fans off
G92 E5                         ; set extruder to 5mm for retract on print end
M117 Cooling please wait       ; progress indicator message
G1 X5 Y5 Z158 E0 F10000        ; move to cooling position
M190 R{material_part_removal_temperature}; wait for bed to cool
M140 S0                        ; set bed to cool off
G1 X145 F1000                  ; present finished print
G1 Y175 F1000                  ; present finished print
M84                            ; steppers off
G90                            ; absolute positioning
M117 Print complete            ; progress indicator message