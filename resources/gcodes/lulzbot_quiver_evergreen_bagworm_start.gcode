; This profile is designed specifically for the Q 3D Printer
M75			     ; start GLCD timer
G26                          ; clear potential 'probe fail' condition
G21                          ; set units to Millimetres
M107                         ; disable fans
G90                          ; absolute positioning
M420 S0                      ; disable previous leveling matrix
M104 S{material_soften_temperature_0} T0               ; soften filament
M104 S{material_soften_temperature_1} T1               ; soften filament
M140 S{material_bed_temperature}; get bed heating up
G28 X Y                      ; home X and Y
M117 Heating...              ; LCD status message
M109 R{material_soften_temperature_0} T0               ; wait for temp
M109 R{material_soften_temperature_1} T1               ; wait for temp
T0                           ; return to first extruder
G28 Z                        ; home Z
T0                           ; select this extruder first
M82                          ; set extruder to absolute mode
G92 E0                       ; set extruder to zero
G1  E-15 F100                ; suck up XXmm of filament
G0 X50 F1000                 ; move over to switch extruders
T1                           ; switch extruders
M82                          ; set extruder to absolute mode
G92 E0                       ; set extruder to zero
G1  E-15 F100                ; suck up XXmm of filament
M104 S{material_wipe_temperature_0} T0                 ; set to wipe temp
M104 S{material_wipe_temperature_1} T1                 ; set to wipe temp
M106                         ; Turn on fans to speed cooling
T0                           ; select first extruder for probing
G1 X-13 Y100 F2000           ; move above wiper pad
M104
M117 Cooling...              ; LCD status message
M109 R{material_wipe_temperature_0} T0                 ; wait for T0 to reach temp
M109 R{material_wipe_temperature_1} T1                 ; wait for T1 to reach temp
M107                         ; Turn off fan
T0                           ; switch extruders
G1 Z 2                     ; push nozzle into wiper
G1 X -14 Y105 F1000          ; slow wipe
G1 X -13 Y100 F1000          ; slow wipe
G1 X -14 Y95 F1000           ; slow wipe
G1 X -13 Y100 F1000          ; slow wipe
G1 X -14 Y90 F1000           ; slow wipe
G1 X -13 Y105 F1000          ; slow wipe
G1 X -14 Y85 F2000           ; fast wipe
G1 X -13 Y75 F2000           ; fast wipe
G1 X -14 Y80 F2000           ; fast wipe
G1 X -13 Y70 F2000           ; fast wipe
G1 X -14 Y65 F2000           ; fast wipe
G1 X -13 Y60 F2000           ; fast wipe
G1 X -14 Y50 F2000           ; fast wipe
G1 X -13 Y55 F2000           ; fast wipe
G1 X -14 Y45 F2000           ; fast wipe
G1 X -13 Y50 F2000           ; fast wipe
G1 X -14 Y80 F2000           ; fast wipe
G1 X -13 Y40 Z 1 F2000      ; fast wipe
G1 X -14 Y45 F2000           ; fast wipe
G1 X -13 Y35 F2000           ; fast wipe
G1 X -14 Y40 F2000           ; fast wipe
G1 X -13 Y35 Z 2 F1000      ; slow wipe
G1 X -14 Y33 F1000           ; slow wipe
G1 X -13 Z15  F2000          ; raise extruder
G0 X50 F1000                 ; move over to switch extruders
T1                           ; switch to second extruder
G1 X300 Y100  F5000          ; move E2 above second wiper pad
G1 Z 2                      ; push nozzle into wiper
G1 X301 Y105 F1000           ; slow wipe
G1 X300 Y100 F1000           ; slow wipe
G1 X301 Y95 F1000            ; slow wipe
G1 X300 Y100 F1000           ; slow wipe
G1 X301 Y90 F1000            ; slow wipe
G1 X300 Y105 F1000           ; slow wipe
G1 X301 Y85 F2000            ; fast wipe
G1 X300 Y75 F2000            ; fast wipe
G1 X301 Y80 F2000            ; fast wipe
G1 X300 Y70 F2000            ; fast wipe
G1 X301 Y65 F2000            ; fast wipe
G1 X300 Y60 F2000            ; fast wipe
G1 X301 Y50 F2000            ; fast wipe
G1 X300 Y55 F2000            ; fast wipe
G1 X301 Y45 F2000            ; fast wipe
G1 X300 Y50 F2000            ; fast wipe
G1 X301 Y80 F2000            ; fast wipe
G1 X300 Y40 Z 1 F2000       ; fast wipe
G1 X301 Y45 F2000            ; fast wipe
G1 X300 Y35 F2000            ; fast wipe
G1 X301 Y40 F2000            ; fast wipe
G1 X300 Y35 Z 2 F1000       ; slow wipe
G1 X301 Y33 F1000            ; slow wipe
G1 X300 Z15  F2000           ; raise extruder
G0 X250 F1000                ; move over to switch extruders
T0                           ; switch to first extruder
M109 R{material_probe_temperature_0} ; heat to probe temp
M204 S100                    ; set accel for probing
G29                          ; probe sequence (for auto-leveling)
M420 S1                      ; enable leveling matrix
M204 S500                    ; set accel back to normal
M104 S{material_print_temperature_0} T0 ; set extruder temp
M104 S{material_print_temperature_1} T1; set extruder temp

G1 X100 Y-19 Z0.5 F3000      ; move to open space
M400                         ; clear buffer
M117 Heating...              ; LCD status message
M109 R{material_print_temperature_0} T0 ; set extruder temp and wait
M109 R{material_print_temperature_1} T1; set extruder temp and wait
M117 Purging...              ; LCD status message
T0                           ; select this extruder first
G1  E0 F100                  ; undo retraction
G92 E-15                     ; set extruder negative amount to purge
G1  E0 F100                  ; purge XXmm of filament
T1                           ; switch to second extruder
G1  E0 F100                  ; undo retraction
G92 E-15                     ; set extruder negative amount to purge
G1  E0 F100                  ; purge XXmm of filament
G1 Z0.5                      ; clear bed (barely)
G1 X100 Y0 F5000             ; move above bed to shear off filament
T0                           ; switch to first extruder
M190 S{material_bed_temperature_layer_0}; get bed temping up during first layer
G1 Z2 E0 F75                 ; raise head and 0 extruder
M400                         ; clear buffer
M117 TAZ Printing...         ; LCD status message
