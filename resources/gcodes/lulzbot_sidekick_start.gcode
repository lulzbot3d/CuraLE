;This G-Code has been generated specifically for the LulzBot Sidekick with a Universal Tool Head
G90 			            ; absolute coordinate
M82     	            	; set extruder to absolute mode
G92 E0     					; set extruder position to 0
M117 Heating...         	; progress indicator message on LCD
M140 S{material_bed_temperature_layer_0}     	; start bed heating up
M104 S{material_probe_temperature}     	        ; start extruder heating to probe temp
G28                         ; home all axes
M190 S{material_bed_temperature_layer_0}     	; wait for bed to reach printing temp
G29     					; start auto leveling
M109 R{material_print_temperature_layer_0}     	; wait for extruder to reach initial printing temp
M117 SideKick Printing...   ; progress indicator message on LCD