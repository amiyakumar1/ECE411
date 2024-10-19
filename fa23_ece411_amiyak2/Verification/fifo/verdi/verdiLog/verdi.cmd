simSetSimulator "-vcssv" -exec "/home/amiyak2/mp1/fifo/sim/simv" -args
debImport "-dbdir" "/home/amiyak2/mp1/fifo/sim/simv.daidir"
debLoadSimResult /home/amiyak2/mp1/fifo/sim/dump.fsdb
wvCreateWindow
debExit
