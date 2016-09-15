;This Gcode has been generated specifically for the LulzBot Mini
G26                          ; clear potential 'probe fail' condition
G21                          ; metric values
G90                          ; absolute positioning
M82                          ; set extruder to absolute mode
M107                         ; start with the fan off
G92 E0                       ; set extruder position to 0
M140 S{material_bed_temperature}; get bed heating up
G28                          ; home all
M109 R{material_wipe_temperature}; set to cleaning temp and wait
G1 Z150 E-30 F75             ; suck up XXmm of filament
M109 R140                    ; heat up rest of way
G1 X45 Y174 F11520           ; move behind scraper
G1 Z0  F1200                 ; CRITICAL: set Z to height of top of scraper
G1 X45 Y174 Z-.5 F4000       ; plunge into wipe pad
G1 X55 Y172 Z-.5 F4000       ; wiping
G1 X45 Y174 Z0 F4000         ; wiping
G1 X55 Y172 F4000            ; wiping
G1 X45 Y174 F4000            ; wiping
G1 X55 Y172 F4000            ; wiping
G1 X45 Y174 F4000            ; wiping
G1 X55 Y172 F4000            ; wiping
G1 X60 Y174 F4000            ; wiping
G1 X80 Y172 F4000            ; wiping
G1 X60 Y174 F4000            ; wiping
G1 X80 Y172 F4000            ; wiping
G1 X60 Y174 F4000            ; wiping
G1 X90 Y172 F4000            ; wiping
G1 X80 Y174 F4000            ; wiping
G1 X100 Y172 F4000           ; wiping
G1 X80 Y174 F4000            ; wiping
G1 X100 Y172 F4000           ; wiping
G1 X80 Y174 F4000            ; wiping
G1 X100 Y172 F4000           ; wiping
G1 X110 Y174 F4000           ; wiping
G1 X100 Y172 F4000           ; wiping
G1 X110 Y174 F4000           ; wiping
G1 X100 Y172 F4000           ; wiping
G1 X110 Y174 F4000           ; wiping
G1 X115 Y172 Z-0.5 F1000     ; wipe slower and bury noz in cleanish area
G1 Z10                       ; raise z
G28 X0 Y0                    ; home x and y
M109 R{material_probe_temperature}; set to probing temp
M204 S300                    ; Set probing acceleration
G29                          ; Probe
M204 S2000                   ; Restore standard acceleration
G1 X5 Y15 Z10 F5000          ; get out the way
G4 S1                        ; pause
M400                         ; clear buffer
M109 R{material_print_temperature}; set extruder temp and wait
G4 S15                       ; wait for bed to temp up
G1 Z2 E0 F75                 ; extrude filament back into nozzle
M140 S{material_bed_temperature}; get bed temping up during first layer
