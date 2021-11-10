;This G-Code has been generated specifically for the LulzBot Sidekick with a Universal Tool Head
G90 			            ; absolute coordinate
M82     	            	; set extruder to absolute mode
G92 E0     					; set extruder position to 0
M117 Heating...         	; progress indicator message on LCD
M109 R{material_soften_temperature} ; soften filament before homing Z
G28 ; Home all axis
G1 E-15 F100 ; retract filament
M140 S{material_bed_temperature_layer_0}     	; start bed heating up
M104 S{material_probe_temperature}     	        ; start extruder heating to probe temp
M190 S{material_bed_temperature_layer_0}     	; wait for bed to reach printing temp
G29     					; start auto leveling
G0 X0 Y0
M109 R{material_print_temperature_layer_0}     	; wait for extruder to reach initial printing temp
M117 SideKick Printing...   ; progress indicator message on LCD
G1 Z2 E0 F75 ; prime tiny bit of filament into the nozzle