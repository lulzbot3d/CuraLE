G28                       ; Home Axis
G0 Z5 F6000               ; Move to bottom of printer
G91                       ; Set relative motion mode
M400                      ; Finish moves
M906 Z450                 ; Lower current to 500mA
G0 Z-15 F500              ; Skip steppers against lower Z mounts
G90                       ; Return to absolute mode
M400                      ; Finish moves
M906 Z960                 ; Restore default current
M400                      ; Finish moves
G28                       ; Rehome
M117 Homed
