;This G-Code has been generated specifically for Q - SL
M73 P0                  ; clear LCD progress bar
M75 					; Start LCD Print Timer
G26 					; clear potential 'probe fail' condition
M107 					; disable fans
M420 S0                 ; disable leveling matrix
G90 					; absolute positioning
M82 					; set extruder to absolute mode
G92 E0 					; set extruder position to 0
G28 					; home all axes
G0 X145 Y187 Z156 F3000 			; move away from endstops
M117 Q - SL Heating Up...			; progress indicator message on LCD
M109 R{material_soften_temperature} 	; soften filament before retraction
M117 Q - SL Retracting Filament...			; progress indicator message on LCD
G1 E-15 F75 				; retract filament
M117 Q - SL Moving to Position...			; progress indicator message on LCD
G1 X300.5 Y100 Z10 F3000 ; move above wiper pad
M109 R{material_wipe_temperature} 	; wait for extruder to reach wiping temp
M117 Q - Wiping Nozzle...			; progress indicator message on LCD
G1 Z0.5              ; lower nozzle
G1 X302 Y95 F1000 ; slow wipe
G1 X300.5 Y90 F1000 ; slow wipe
G1 X302 Y85 F1000 ; slow wipe
G1 X300.5 Y90 F1000 ; slow wipe
G1 X302 Y80 F1000 ; slow wipe
G1 X300.5 Y95 F1000 ; slow wipe
G1 X302 Y75 F2000 ; fast wipe
G1 X300.5 Y65 F2000 ; fast wipe
G1 X302 Y70 F2000 ; fast wipe
G1 X300.5 Y60 F2000 ; fast wipe
G1 X302 Y55 F2000 ; fast wipe
G1 X300.5 Y50 F2000 ; fast wipe
G1 X302 Y40 F2000 ; fast wipe
G1 X300.5 Y45 F2000 ; fast wipe
G1 X302 Y35 F2000 ; fast wipe
G1 X300.5 Y40 F2000 ; fast wipe
G1 X302 Y70 F2000 ; fast wipe
G1 X300.5 Y30 Z2 F2000 ; fast wipe
G1 X302 Y35 F2000 ; fast wipe
G1 X300.5 Y25 F2000 ; fast wipe
G1 X302 Y30 F2000 ; fast wipe
G1 X300.5 Y25 Z1.5 F1000 ; slow wipe
G1 X302 Y23 F1000 ; slow wipe
G1 Z10 ; raise extruder
M117 Q - Wiping Complete.		; progress indicator message on LCD
