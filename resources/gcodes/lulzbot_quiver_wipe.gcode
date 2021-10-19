G26					; clear potential 'probe fail' condition
G21					; set units to Millimetres
M117 Heating Extruders ; update message
M104 S180 T0    ; set T0 temperature
M104 S180 T1    ; set T1 temperature
M109 R180 T0    ; wait for T0 to reach temp
M109 R180 T1    ; wait for T1 to reach temp
M107                                      ; turn off fan
G12                         ; wiping sequence
G28                                       ; home all axis
