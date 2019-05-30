; This profile is designed specifically for the LulzBot TAZ Pro with Dual Extruder Tool Head
M73 P0                                    ; clear GLCD progress bar
M75			     	          ; start GLCD timer
M107                                      ; disable fans
G90                                       ; absolute positioning
M420 S0                                   ; disable previous leveling matrix
M140 S{material_bed_temperature_layer_0}  ; begin bed temping up
M104 S{material_soften_temperature_0} T0  ; soften filament
M104 S{material_soften_temperature_1} T1  ; soften filament
G28                                       ; home
M117 Heating...                           ; LCD status message
M109 R{material_soften_temperature_0} T0  ; wait for temp
M109 R{material_soften_temperature_1} T1  ; wait for temp
T0                                        ; select this extruder first
M82                                       ; set extruder to absolute mode
G92 E0                                    ; set extruder to zero
G1 E-10 F100                              ; retract 10mm of filament on first extruder
G0 X50 F1000                              ; move over to switch extruders
T1                                        ; switch extruders
M82                                       ; set extruder to absolute mode
G92 E0                                    ; set extruder to zero
G1  E-10 F100                             ; retract 10mm of filament on second extruder
M104 S{material_wipe_temperature_0} T0    ; set to wipe temp
M104 S{material_wipe_temperature_1} T1    ; set to wipe temp
M106                                      ; turn on fans to speed cooling
T0                                        ; select first extruder for probing
G1 X-16.5 Y100 F2000                      ; move above wiper pad
M117 Cooling...                           ; LCD status message
M109 R{material_wipe_temperature_0} T0    ; wait for T0 to reach temp
M109 R{material_wipe_temperature_1} T1    ; wait for T1 to reach temp
M107                                      ; turn off fan
G1 Z 1.0                                  ; push nozzle into wiper
G1 X -16.5 Y100 F1000                     ; slow wipe
G1 X -16.5 Y90 F1000                      ; slow wipe
G1 X -15.5 Y86 F2000                      ; fast wipe
G1 X -17.5 Y80 F2000                      ; fast wipe
G1 X -15.5 Y74 F2000                      ; fast wipe
G1 X -17.5 Y70 F2000                      ; fast wipe
G1 X -16.5 Y68 F1000                      ; slow wipe
G1 X -16.5 Y60 F1000                      ; slow wipe
G1 X -14.5 Y60 F1000                      ; slow wipe
G1 X -14.5 Y46 F1000                      ; slow wipe
G1 X -17.5 Y46 F1000                      ; slow wipe
G1 X -17.5 Y60 F1000                      ; slow wipe
G1 X -14.5 Y60 F1000                      ; slow wipe
G1 X -14.5 Y46 F1000                      ; slow wipe
G1 X -17.5 Y46 F1000                      ; slow wipe
G1 X -17.5 Y60 F1000                      ; slow wipe
G1 X -14.5 Y60 F1000                      ; slow wipe
G1 X -14.5 Y46 F1000                      ; slow wipe
G1 X -17.5 Y46 F1000                      ; slow wipe
G1 X -17.5 Y60 F1000                      ; slow wipe
G1 X -16.5 Y60 F1000                      ; slow wipe
G1 X -16.5 Y42 F1000                      ; slow wipe
G1 X -15.5 Y40 F2000                      ; fast wipe
G1 X -17.5 Y38 F2000                      ; fast wipe
G1 X -15.5 Y36 F2000                      ; fast wipe
G1 X -17.5 Y34 F2000                      ; fast wipe
G1 X -16.5 Y30 F1000                      ; slow wipe
G1 X -16.5 Y19 F1000                      ; slow wipe
G1 X -16.5 Y19 Z20 F1000                  ; raise extruder
M106 S255                                 ; turn on fan to blow away fuzzies
G4 S5                                     ; wait 5 seconds
M107                                      ; turn off fan
G0 X50 F1000                              ; move over to switch extruders
T1                                        ; switch to second extruder
G1 X296.5 Y100  F5000                     ; move E2 above second wiper pad
G1 Z 1.0                                  ; push nozzle into wiper
G1 X 296.5 Y100 F1000                     ; slow wipe
G1 X 296.5 Y90 F1000                      ; slow wipe
G1 X 297.5 Y86 F2000                      ; fast wipe
G1 X 295.5 Y80 F2000                      ; fast wipe
G1 X 297.5 Y74 F2000                      ; fast wipe
G1 X 295.5 Y70 F2000                      ; fast wipe
G1 X 296.5 Y68 F1000                      ; slow wipe
G1 X 296.5 Y60 F1000                      ; slow wipe
G1 X 298 Y60 F1000                        ; slow wipe
G1 X 298 Y46 F1000                        ; slow wipe
G1 X 295 Y46 F1000                        ; slow wipe
G1 X 295 Y60 F1000                        ; slow wipe
G1 X 298 Y60 F1000                        ; slow wipe
G1 X 298 Y46 F1000                        ; slow wipe
G1 X 295 Y46 F1000                        ; slow wipe
G1 X 295 Y60 F1000                        ; slow wipe
G1 X 298 Y60 F1000                        ; slow wipe
G1 X 298 Y46 F1000                        ; slow wipe
G1 X 295 Y46 F1000                        ; slow wipe
G1 X 295 Y60 F1000                        ; slow wipe
G1 X 296.5 Y60 F1000                      ; slow wipe
G1 X 296.5 Y42 F1000                      ; slow wipe
G1 X 297.5 Y40 F2000                      ; fast wipe
G1 X 295.5 Y38 F2000                      ; fast wipe
G1 X 297.5 Y36 F2000                      ; fast wipe
G1 X 295.5 Y34 F2000                      ; fast wipe
G1 X 297.5 Y30 F1000                      ; slow wipe
G1 X 296.5 Y19 F1000                      ; slow wipe
G1 X 296.5 Y19 Z20 F1000                  ; raise extruder
M106 S255                                 ; turn on fan to blow away fuzzies
G4 S5                                     ; wait 5 seconds
M107                                      ; turn off fan
G0 X247 F1000                             ; move over to switch extruders
T0                                        ; switch to first extruder
M109 R{material_probe_temperature_0}      ; heat to probe temp
M204 S100                                 ; set accel for probing
G29                                       ; probe sequence (for auto-leveling)
M420 S1                                   ; enable leveling matrix
M204 S500                                 ; set accel back to normal
M104 S{material_print_temperature_layer_0_0}  T0  ; set extruder temp
M104 S{material_print_temperature_layer_0_1}  T1  ; set extruder temp
G1 X100 Y-29 Z0.5 F3000                   ; move to open space
M400                                      ; clear buffer
M117 Heating...                           ; LCD status message
M109 R{material_print_temperature_layer_0_0}  T0  ; set extruder temp and wait
M109 R{material_print_temperature_layer_0_1}  T1  ; set extruder temp and wait
M117 Purging...                           ; LCD status message
T0                                        ; select this extruder first
G1 E0 F100		    	          ; undo retraction
G92 E-30				  ; set extruder negative amount to purge
G1 E0 F100				  ; purge XXmm of filament
G1 E-3 F200                               ; purge retraction
G1 Z0.45                                  ; clear bed (barely)
G1 X100 Y10 F4000                         ; move above bed to shear off filament
M106 S255                                 ; turn on fan
G4 S7                                     ; wait 7 seconds
M107                                      ; turn off fan
G1 X180 Y-29 Z0.45 F3000                  ; move to open space
T1                                        ; set extruder
G1 E0 F100                                ; undo retraction
G92 E-30                                  ; set extruder negative amount to purge
G1 E0 F100                                ; purge XXmm of filament
G1 E-4 F200                               ; purge retraction
G1 Z0.35                                  ; clear bed (barely)
G1 X180 Y10 F4000                         ; move above bed to shear off filament
T0                                        : set extruder
M190 R{material_bed_temperature_layer_0}  ; get bed temping up during first layer
G1 Z2 E0 F75                              ; raise head and 0 extruder
M82					  ; set to absolute mode
M400                                      ; clear buffer
M117 TAZ Printing...                      ; LCD status message
