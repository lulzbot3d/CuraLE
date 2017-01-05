	M400                           ; wait for buffer to clear
	M104 S0                        ; hotend off
	M140 S0                        ; heated bed heater off (if you have it)
	M107                           ; fans off
	G91                            ; relative positioning
	G1 E-1 F300                    ; retract the filament a bit before lifting the nozzle, to release some of the pressure
	G1 Z+0.5 E-5 X-20 Y-20 F3000   ; move Z up a bit and retract filament even more
	G90                            ; absolute positioning
	G1 X0 Y250                     ; move to cooling position
	M84                            ; steppers off
	G90                            ; absolute positioning
