G26					; clear potential 'probe fail' condition
G21					; set units to Millimetres
M117 Heating Extruders ; update message
M104 S180 T0    ; set T0 temperature
M104 S180 T1    ; set T1 temperature
M109 R180 T0    ; wait for T0 to reach temp
M109 R180 T1    ; wait for T1 to reach temp
M107                                      ; turn off fan
M117 Wiping nozzles ; wiping message
G1 Z 1.0                                 ; push nozzle into wiper
G1 X -17 Y100 F1000                       ; slow wipe
G1 X -17 Y90 F1000                        ; slow wipe
G1 X -16 Y86 F2000                        ; fast wipe
G1 X -18 Y80 F2000                        ; fast wipe
G1 X -16 Y74 F2000                        ; fast wipe
G1 X -18 Y70 F2000                        ; fast wipe
G1 X -17 Y68 F1000                        ; slow wipe
G1 X -17 Y60 F1000                        ; slow wipe
G1 X -15 Y60 F1000                        ; slow wipe
G1 X -15 Y46 F1000                        ; slow wipe
G1 X -18 Y46 F1000                        ; slow wipe
G1 X -18 Y60 F1000                        ; slow wipe
G1 X -15 Y60 F1000                        ; slow wipe
G1 X -15 Y46 F1000                        ; slow wipe
G1 X -18 Y46 F1000                        ; slow wipe
G1 X -18 Y60 F1000                        ; slow wipe
G1 X -15 Y60 F1000                        ; slow wipe
G1 X -15 Y46 F1000                        ; slow wipe
G1 X -18 Y46 F1000                        ; slow wipe
G1 X -18 Y60 F1000                        ; slow wipe
G1 X -17 Y60 F1000                        ; slow wipe
G1 X -17 Y42 F1000                        ; slow wipe
G1 X -16 Y40 F2000                        ; fast wipe
G1 X -18 Y38 F2000                        ; fast wipe
G1 X -16 Y36 F2000                        ; fast wipe
G1 X -18 Y34 F2000                        ; fast wipe
G1 X -17 Y30 F1000                        ; slow wipe
G1 X -17 Y19 F1000                        ; slow wipe
G1 X -17 Y19 Z20 F1000			  ; raise extruder
M106 S255                                 ; turn on fan to blow away fuzzies
G4 S5                                     ; wait 5 seconds
M107                                      ; turn off fan
G0 X50 F1000                              ; move over to switch extruders
T1                                        ; switch to second extruder
G1 X297.5 Y100  F5000                     ; move E2 above second wiper pad
G1 Z 1.0                                 ; push nozzle into wiper
G1 X 294.5 Y100 F1000                     ; slow wipe
G1 X 294.5 Y90 F1000                      ; slow wipe
G1 X 295.5 Y86 F2000                      ; fast wipe
G1 X 293.5 Y80 F2000                      ; fast wipe
G1 X 295.5 Y74 F2000                      ; fast wipe
G1 X 293.5 Y70 F2000                      ; fast wipe
G1 X 294.5 Y68 F1000                      ; slow wipe
G1 X 294.5 Y60 F1000                      ; slow wipe
G1 X 296 Y60 F1000                        ; slow wipe
G1 X 296 Y46 F1000                        ; slow wipe
G1 X 293 Y46 F1000                        ; slow wipe
G1 X 293 Y60 F1000                        ; slow wipe
G1 X 296 Y60 F1000                        ; slow wipe
G1 X 296 Y46 F1000                        ; slow wipe
G1 X 293 Y46 F1000                        ; slow wipe
G1 X 293 Y60 F1000                        ; slow wipe
G1 X 296 Y60 F1000                        ; slow wipe
G1 X 296 Y46 F1000                        ; slow wipe
G1 X 293 Y46 F1000                        ; slow wipe
G1 X 293 Y60 F1000                        ; slow wipe
G1 X 294.5 Y60 F1000                      ; slow wipe
G1 X 294.5 Y42 F1000                      ; slow wipe
G1 X 295.5 Y40 F2000                      ; fast wipe
G1 X 293.5 Y38 F2000                      ; fast wipe
G1 X 295.5 Y36 F2000                      ; fast wipe
G1 X 293.5 Y34 F2000                      ; fast wipe
G1 X 295.5 Y30 F1000                      ; slow wipe
G1 X 294.5 Y19 F1000                      ; slow wipe
G1 X 294.5 Y19 Z20 F1000                  ; raise extruder
M106 S255                                 ; turn on fan to blow away fuzzies
G4 S5                                     ; wait 5 seconds
M107                                      ; turn off fan
G28                                       ; home all axis
