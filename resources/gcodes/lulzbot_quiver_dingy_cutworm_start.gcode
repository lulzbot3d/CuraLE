;This G-Code has been generated specifically for LulzBot TAZ Pro with HS+ Tool Head
M73 P0                  ; clear LCD progress bar
M75 					; Start LCD Print Timer
G26 					; clear potential 'probe fail' condition
M107 					; disable fans
M420 S0                 ; disable leveling matrix
G90 					; absolute positioning
M82 					; set extruder to absolute mode
G92 E0 					; set extruder position to 0
M140 S{material_bed_temperature_layer_0} ; start bed heating up
G28 					; home all axes
G0 X145 Y187 Z156 F3000 			; move away from endstops
M117 Q - HS+ Heating Up...			; progress indicator message on LCD
M109 R{material_soften_temperature} 	; soften filament before retraction
M117 Q - HS+ Retracting Filament...			; progress indicator message on LCD
G1 E-15 F75 				; retract filament
G12                         ; wiping sequence
G1 X0 Y0 F3000				; move toward first probe point
M109 R{material_probe_temperature}	; wait for extruder to reach probe temp
M204 S300				; set probing acceleration
G29       ; start auto-leveling sequence
M420 S1   ; enable leveling matrix
M425 Z	  ; use measured Z backlash for compensation
M425 Z F0 ; turn off measured Z backlash compensation. (if activated in the quality settings, this command will automatically be ignored)
M204 S2000				; restore standard acceleration
G1 X5 Y15 Z10 F5000			; move up off last probe point
G4 S1					; pause
M400					; wait for moves to finish
M117 Heating...				; progress indicator message on LCD
M109 R{material_print_temperature_layer_0}	; wait for extruder to reach initial printing temp
M190 R{material_bed_temperature_layer_0} ; wait for bed to reach printing temp
G1 Z2 E0 F75				; prime tiny bit of filment into the nozzle
M117 Q - HS+ Printing...		; progress indicator message on LCD
