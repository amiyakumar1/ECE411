`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);
import mult_types::*;

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, "+all");
end

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
// initial $monitor("[student_testbench] dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

task verify_start();
	// after resetting, ready should be high so then i can assert start
    @(tb_clk);
    itf.start <= 1'b1;

    @(tb_clk);
    itf.start <= 1'b0;

    // while multiplication is occuing
    while (itf.rdy == 1'b0) begin
            @(tb_clk);
            itf.start <= 1'b1;
    end
endtask

task verify_reset_add();
    // while multiplication is occuing
    @(tb_clk);
    itf.start <= 1'b1;

    @(tb_clk);
    itf.start <= 1'b0;

    while (itf.rdy == 1'b0) begin
            @(tb_clk iff(itf.mult_op == ADD));
            // reset();
            itf.reset_n <= 1'b0;
            @(tb_clk);
            itf.reset_n <= 1'b1;
    end

endtask

task verify_reset_shift();
    // while multiplication is occuing
    @(tb_clk);
    itf.start <= 1'b1;

    @(tb_clk);
    itf.start <= 1'b0;

    while (itf.rdy == 1'b0) begin
            @(tb_clk iff(itf.mult_op == SHIFT));
            // reset();
            itf.reset_n <= 1'b0;
            @(tb_clk);
            itf.reset_n <= 1'b1;
    end

endtask

task verify_mult();

    // after resetting, ready should be high so then i can assert start
    @(tb_clk);
    itf.start <= 1'b1;

    @(tb_clk);
    itf.start <= 1'b0;

    // once the done signal is asserted i can verify the product 
    @(posedge itf.done);
    // if incorrect product
    assert (itf.product == (itf.multiplicand * itf.multiplier))
    else begin
        $error ("%0d: %0t: BAD_PRODUCT error detected", `__LINE__, $time);
        report_error (BAD_PRODUCT);
    end
    // if ready signal not asserted after product
    assert (itf.rdy == 1'b1)
    else begin
        $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
        report_error (NOT_READY);
    end

    // turn off the start signal
    itf.start <= 1'b0;
    
endtask

// after the rising edge of the reset (meaing the reset occured and we're on the next cycle) the ready should be asserted
always @ (posedge itf.reset_n) begin
      assert (itf.rdy == 1'b1)
      else begin
            $error("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
            report_error (NOT_READY);
      end
end



// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error

initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/

    for (int i = 0; i < 256; ++i) begin
        for (int j = 0; j < 256; ++j) begin
            itf.multiplicand <= i;
            itf.multiplier <= j;
            verify_mult();
        end
    end

    reset();
    // arbitrary values
    itf.multiplicand <= 63;
    itf.multiplier <= 127;
    verify_reset_add();

    reset();
    // arbitrary values
    itf.multiplicand <= 31;
    itf.multiplier <= 255;
    verify_reset_shift();

    reset();
    // arbitrary values
    itf.multiplicand <= 127;
    itf.multiplier <= 63;
    verify_start();

    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
