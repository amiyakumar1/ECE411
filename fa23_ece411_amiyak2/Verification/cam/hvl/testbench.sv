
module testbench(cam_itf itf);
import cam_types::*;

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, "+all");
end

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

task evict();
    // upon resetting, the CAM is empty so first we fill it with values
    for(int i = 0; i < camsize_p; ++i) begin
        @(tb_clk);
        itf.rw_n <= 1'b0;
        itf.valid_i <= 1'b1;
        itf.key <= i;
        itf.val_i <= i;
    end

    // now overwrite these values with new ones
    for(int i = 0; i < camsize_p; ++i) begin
        @(tb_clk);
        itf.rw_n <= 1'b0;
        itf.valid_i <= 1'b1;
        itf.key <= i + 10;
        itf.val_i <= i + 10;
    end
    
endtask

task read_hit();
    // populate CAM
    for(int i = 0; i < camsize_p; ++i) begin
        @(tb_clk);
        itf.rw_n <= 1'b0;
        itf.valid_i <= 1'b1;
        itf.key <= i;
        itf.val_i <= i;
    end

    // now read each value and verify they are correct
    @(tb_clk);
    itf.rw_n = 1'b1;
    itf.valid_i = 1'b1;

    for(int i = 0; i < camsize_p; ++i) begin
        itf.key = i;
        @(tb_clk);
        assert(itf.val_o == i)
        else begin
            itf.tb_report_dut_error(READ_ERROR);
            $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, i);
        end
    end

    @(tb_clk);
    itf.valid_i = 1'b0;
endtask

val_t a;
task multiple_write();
    for(int i = 0; i < 2; i++) begin
        @(tb_clk);
        itf.rw_n <= 1'b0;
        itf.valid_i <= 1'b1;
        itf.val_i <= i + 1'b1;
        itf.key <= 32;
    end
        
    @(tb_clk);
    itf.rw_n <= 1'b1;
    itf.key <= 32;

    read(32,a);

    @(tb_clk);
    assert(itf.val_o == 2)
    else begin
        itf.tb_report_dut_error(READ_ERROR);
        $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, a);
    end
    
    itf.valid_i = 1'b0;	
endtask

task write(input key_t key, input val_t val);
endtask

task read(input key_t key, output val_t val);
endtask

initial begin
    $display("Starting CAM Tests");

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv

    evict();

    read_hit();

	multiple_write();

    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
