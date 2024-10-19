simSetSimulator "-vcssv" -exec "/home/amiyak2/mp1/cacheline_adaptor/sim/simv" \
           -args
debImport "-dbdir" "/home/amiyak2/mp1/cacheline_adaptor/sim/simv.daidir"
debLoadSimResult /home/amiyak2/mp1/cacheline_adaptor/sim/dump.fsdb
wvCreateWindow
srcHBDrag -win $_nTrace1
wvRenameGroup -win $_nWave2 {G1} {dut}
wvAddSignal -win $_nWave2 "/testbench/dut/clk" "/testbench/dut/reset_n" \
           "/testbench/dut/line_i\[255:0\]" "/testbench/dut/line_o\[255:0\]" \
           "/testbench/dut/address_i\[31:0\]" "/testbench/dut/read_i" \
           "/testbench/dut/write_i" "/testbench/dut/resp_o" \
           "/testbench/dut/burst_i\[63:0\]" "/testbench/dut/burst_o\[63:0\]" \
           "/testbench/dut/address_o\[31:0\]" "/testbench/dut/read_o" \
           "/testbench/dut/write_o" "/testbench/dut/resp_i"
wvSetPosition -win $_nWave2 {("dut" 0)}
wvSetPosition -win $_nWave2 {("dut" 14)}
wvSetPosition -win $_nWave2 {("dut" 14)}
wvSetCursor -win $_nWave2 1909940.247698 -snap {("G2" 0)}
debExit
