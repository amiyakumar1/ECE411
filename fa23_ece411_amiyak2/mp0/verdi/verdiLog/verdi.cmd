simSetSimulator "-vcssv" -exec "/home/amiyak2/mp0/sim/simv" -args
debImport "-dbdir" "/home/amiyak2/mp0/sim/simv.daidir"
debLoadSimResult /home/amiyak2/mp0/sim/dump.fsdb
wvCreateWindow
srcHBSelect "mp0_tb.mp0.rf" -win $_nTrace1
srcSetScope "mp0_tb.mp0.rf" -delim "." -win $_nTrace1
srcHBSelect "mp0_tb.mp0.rf" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcHBAddObjectToWave -clipboard
wvDrop -win $_nWave2
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
srcHBSelect "mp0_tb.mp0.rf.unnamed\$\$_0" -win $_nTrace1
srcHBSelect "mp0_tb.mp0.rf" -win $_nTrace1
debExit
