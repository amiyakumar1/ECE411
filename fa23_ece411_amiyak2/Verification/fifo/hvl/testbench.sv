`ifndef testbench
`define testbench


module testbench(fifo_itf itf);
import fifo_types::*;

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, "+all");
end

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE


task verify_reset();
    // make sure that the reset is working properly, and raise the error accordingly
    assert(itf.rdy == 1'b1)
    else begin
        $error("%0d: %0t: RESET_DOES_NOT_CAUSE_READY_O error detected", `__LINE__, $time);
        report_error(RESET_DOES_NOT_CAUSE_READY_O);
    end
endtask

task enqueue();
    // ready_o should be high, then assert valid_i and sent data_i
    // capacity of fifo is 1<<8 or 256
    @(tb_clk);
    itf.valid_i <= 1'b1;

    for(int i = 0; i < CAP_P; ++i) begin
        itf.data_i <= i;
        @(tb_clk);
    end
    
    itf.valid_i <= 1'b0;
endtask

task dequeue();
    // essentially the opposite of enquue, just verify values as i dequeue them

    @(tb_clk);
    itf.yumi <= 1'b1;

    for(int i = 0; i < CAP_P; ++i) begin
        assert(itf.data_o == i)
        else begin
            $error("%0d: %0t: INCORRECT_DATA_O_ON_YUMI_I error detected", `__LINE__, $time);
            report_error(INCORRECT_DATA_O_ON_YUMI_I);
        end
        @(tb_clk);
    end

    itf.yumi <= 1'b0;
endtask : dequeue


task enqueue_dequeue();
    for(int i = 0; i < CAP_P; ++i) begin
        itf.valid_i <= 1'b1;
        itf.data_i <= i;

        itf.yumi <= 1'b0;
        @(tb_clk);
        itf.yumi <= 1'b1;
        @(tb_clk);
	end
	
	itf.valid_i <= 1'b0;
	itf.yumi <= 1'b0;
endtask

initial begin  
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.

    // intermediate resets not necessary bc dequeue undos enqueue???
    assert (itf.rdy)
	else begin
		$error ("%0d: %0t: %s error detected", `__LINE__, $time, RESET_DOES_NOT_CAUSE_READY_O);
		report_error (RESET_DOES_NOT_CAUSE_READY_O);
	end
    enqueue();

    dequeue();

    enqueue_dequeue();
    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif

