;This G-Code has been generated specifically for G - M175v2
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
M117 Q - M175v2 Heating Up...			; progress indicator message on LCD
M109 R{material_soften_temperature} 	; soften filament before retraction
M117 G - M175v2 Retracting Filament...			; progress indicator message on LCD
G1 E-15 F75 				; retract filament
M117 G - M175v2 Moving to Position...			; progress indicator message on LCD
G1 X295 Y100 Z10 F3000 ; move above wiper pad
G12                         ; wiping sequence
