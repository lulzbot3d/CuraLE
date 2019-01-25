G28 ;home all axes
M400
M121 ;hardware endstops off
M400
M211 S0 ;software endstops off
M400
M906 Z725 ;current 725
M400
G1 Z312 ;move past top
M400
M906 Z960 ;current 960
M400
M211 S1 ;soft endstops on
M400
M120 ;hardware endstops on
M400 
G1 X100 Z250 F2000 ;park toolhead
