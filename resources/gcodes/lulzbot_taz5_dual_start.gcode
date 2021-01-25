; This gcode was specifically sliced for a TAZ 5 with Dual Extruder v2
M73 P0 ; clear GLCD progress bar
M75	   ; Start GLCD Timer
M140 S{material_bed_temperature_layer_0}    ; start bed heating up
G90        ;absolute positioning
M107       ;start with the fan off
G28 X0 Y0  ;move X/Y to min endstops
G28 Z0     ;move Z to min endstops
M117 Heating...                     ; progress indicator message on LCD
M140 S{material_bed_temperature_layer_0}   ; start bed heating up
M104 S{material_print_temperature_layer_0_1} T1 ; set extruder temp
M109 S{material_print_temperature_layer_0_0} T0 ; set extruder temp and wait
M109 R{material_print_temperature_layer_0_1} T1 ; set extruder temp and wait
G1 Z15.0 F{speed_travel} ;move the platform down 15mm
T1                      ;Switch to the 2nd extruder
G92 E0                  ;zero the extruded length
G1 F100 E10             ;extrude 10mm of feed stock
G92 E0                  ;zero the extruded length again
G1 F200 E-{retraction_amount}
T0                      ;Switch to the first extruder
G92 E0                  ;zero the extruded length
G1 F100 E10             ;extrude 10mm of feed stock
G92 E0                  ;zero the extruded length again
G1 F{speed_travel}
M190 R{material_bed_temperature_layer_0}  ; wait for bed temperature
;Put printing message on LCD screen
M117 Printing...
