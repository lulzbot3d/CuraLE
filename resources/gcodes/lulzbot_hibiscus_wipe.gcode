;This G-Code has been generated specifically for the LulzBot Mini 2
G26					; clear potential 'probe fail' condition
G21					; set units to Millimetres
M107					; disable fans
G90					; absolute positioning
M82					; set extruder to absolute mode
G92 E0					; set extruder position to 0
G28					; home all axes
G0 X0 Y187 Z156 F200			; move away from endstops
M109 R{material_wipe_temperature}	; wait for extruder to reach wiping temp
G1 E-15 F75				; retract filament
G1 X45 Y176 F11520			; move above wiper pad
G1 Z0 F1200				; push nozzle into wiper
G1 X45 Y178 Z-.5 F4000		; wiping
G1 X55 Y176 Z-.5 F4000		; wiping
G1 X45 Y177 Z0 F4000		; wiping
G1 X55 Y176 F4000		; wiping
G1 X45 Y178 F4000		; wiping
G1 X55 Y176 F4000		; wiping
G1 X45 Y178 F4000		; wiping
G1 X55 Y176 F4000		; wiping
G1 X60 Y178 F4000		; wiping
G1 X80 Y176 F4000		; wiping
G1 X60 Y178 F4000		; wiping
G1 X80 Y176 F4000		; wiping
G1 X60 Y178 F4000		; wiping
G1 X90 Y176 F4000		; wiping
G1 X80 Y178 F4000		; wiping
G1 X100 Y176 F4000		; wiping
G1 X80 Y178 F4000		; wiping
G1 X100 Y176 F4000		; wiping
G1 X80 Y178 F4000		; wiping
G1 X100 Y176 F4000		; wiping
G1 X110 Y178 F4000		; wiping
G1 X100 Y176 F4000		; wiping
G1 X110 Y178 F4000		; wiping
G1 X100 Y176 F4000		; wiping
G1 X110 Y178 F4000		; wiping
G1 X115 Y176 Z-0.5 F1000	; wiping
G1 Z10					; raise extruder
G28 X0 Y0				; re-home to account for build variance of earlier mini builds
G0 X0 Y187 F200				; move away from endstops
G0 Y152 F4000				; move in front of wiper pad
G4 S1					; pause
M400					; wait for moves to finish
G1 E0 F75				; prime tiny bit of filament into the nozzle
M400					; wait for moves to finish
