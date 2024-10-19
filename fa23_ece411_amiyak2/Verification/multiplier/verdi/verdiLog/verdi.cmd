simSetSimulator "-vcssv" -exec "/home/amiyak2/mp1/multiplier/sim/simv" -args
debImport "-dbdir" "/home/amiyak2/mp1/multiplier/sim/simv.daidir"
debLoadSimResult /home/amiyak2/mp1/multiplier/sim/dump.fsdb
wvCreateWindow
srcHBDrag -win $_nTrace1
wvAddSignal -win $_nWave2 "top/tb/itf/stu_errors"
wvRenameGroup -win $_nWave2 {G1} {tb}
wvAddSignal -win $_nWave2 "/top/tb/itf/rdy" "/top/tb/itf/product\[15:0\]" \
           "/top/tb/itf/reset_n" "/top/tb/itf/mult_op\[2:0\]" \
           "/top/tb/itf/done" "/top/tb/itf/multiplier\[7:0\]" \
           "/top/tb/itf/multiplicand\[7:0\]" "/top/tb/itf/start" \
           "/top/tb/itf/clk" "/top/tb/itf/timestamp\[63:0\]"
wvSetPosition -win $_nWave2 {("tb" 0)}
wvSetPosition -win $_nWave2 {("tb" 10)}
wvSetPosition -win $_nWave2 {("tb" 10)}
wvSetCursor -win $_nWave2 9012746.149351 -snap {("G2" 0)}
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvSetCursor -win $_nWave2 21944268.577717 -snap {("tb" 6)}
wvSetCursor -win $_nWave2 21929218.788695 -snap {("tb" 0)}
wvSetCursor -win $_nWave2 21919259.602703 -snap {("tb" 0)}
wvSetCursor -win $_nWave2 21919497.481349 -snap {("tb" 0)}
wvSetCursor -win $_nWave2 21919418.188467 -snap {("tb" 0)}
wvSetCursor -win $_nWave2 21918902.784733 -snap {("tb" 0)}
wvSetCursor -win $_nWave2 21914977.787070 -snap {("tb" 5)}
wvSetCursor -win $_nWave2 21920567.935257 -snap {("tb" 2)}
wvSetCursor -win $_nWave2 21921479.803401 -snap {("tb" 2)}
wvSetCursor -win $_nWave2 21922708.843073 -snap {("tb" 2)}
wvSetCursor -win $_nWave2 21923858.589864 -snap {("tb" 2)}
wvSetCursor -win $_nWave2 21926356.315649 -snap {("tb" 2)}
wvSetCursor -win $_nWave2 21934325.250299 -snap {("tb" 2)}
debExit
