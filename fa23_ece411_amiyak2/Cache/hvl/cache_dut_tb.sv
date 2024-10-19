module cache_dut_tb;

    timeunit 1ns;
    timeprecision 1ns;

    //----------------------------------------------------------------------
    // Waveforms.
    //----------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end

    //----------------------------------------------------------------------
    // Generate the clock.
    //----------------------------------------------------------------------
    bit clk;
    initial clk = 1'b1;
    always #1 clk = ~clk;

    //----------------------------------------------------------------------
    // Generate the reset.
    //----------------------------------------------------------------------
    bit rst;
    task do_reset();
        // Fill this out
        
        rst <= 1'b1;
        repeat (10) @(posedge clk);
        rst <= 1'b0;

    endtask : do_reset

    //----------------------------------------------------------------------
    // Collect coverage here:
    //----------------------------------------------------------------------
    // covergroup cache_cg with function sample(...)
    //     // Fill this out!

    // endgroup
    // Note that you will need the covergroup to get `make covrep_dut` working.

    //----------------------------------------------------------------------
    // Want constrained random classes? Do that here:
    //----------------------------------------------------------------------
    // class RandAddr;
    //     rand bit [31:0] addr;
    //     // Fill this out!
    // endclass : RandAddr

    //----------------------------------------------------------------------
    // Instantiate your DUT here.
    //----------------------------------------------------------------------
    logic [31:0] mem_address;
    logic mem_read;
    logic mem_write;
    logic [31:0] mem_byte_enable;
    logic [255:0] mem_rdata;
    logic [255:0] mem_wdata;
    logic mem_resp;
    logic [31:0] pmem_address;
    logic pmem_read;
    logic pmem_write;
    logic [255:0] pmem_rdata;
    logic [255:0] pmem_wdata;
    logic pmem_resp;

    // associative array for pmem
    logic [255:0] pmem [bit [31:0]];
    logic [255:0] write_0;

    cache dut
    (
        .clk(clk),
        .rst(rst),
        .mem_address(mem_address),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_byte_enable(),
        .mem_rdata(mem_rdata),
        .mem_wdata(mem_wdata),
        .mem_resp(mem_resp),
        .pmem_address(pmem_address),
        .pmem_read(pmem_read),
        .pmem_write(pmem_write),
        .pmem_rdata(pmem_rdata),
        .pmem_wdata(pmem_wdata),
        .pmem_resp(pmem_resp)
    );

    //----------------------------------------------------------------------
    // Write your tests and run them here!
    //----------------------------------------------------------------------
    // Recommended: package your tests into tasks.
    // bit[31:0] addr_0;

    task do_a_read();
    // read from pmem, miss clean
        mem_read <= 1'b1;
        mem_write <= 1'b0;
        mem_address <= 32'hffffffe0;
        @(posedge clk iff mem_resp);
        mem_read <= 1'b0;
        $display(mem_rdata);
    endtask

    task do_a_read_2();
    // read from pmem, miss clean
        mem_read <= 1'b1;
        mem_write <= 1'b0;
        mem_address <= 32'heeeeeee0;
        @(posedge clk iff mem_resp);
        mem_read <= 1'b0;
        $display(mem_rdata);
    endtask

    task do_a_read_3();
    // read from pmem, miss clean
        mem_read <= 1'b1;
        mem_write <= 1'b0;
        mem_address <= 32'hfffffde0;
        @(posedge clk iff mem_resp);
        mem_read <= 1'b0;
        $display(mem_rdata);
    endtask

    task do_a_read_4();
    // read from pmem, miss clean
        mem_read <= 1'b1;
        mem_write <= 1'b0;
        mem_address <= 32'hcccccce0;
        @(posedge clk iff mem_resp);
        mem_read <= 1'b0;
        $display(mem_rdata);
    endtask


    task do_a_write();
    // write to pmem, miss clean
        mem_read <= 1'b0;
        mem_write <= 1'b1;
        mem_wdata <= 256'h999999e0;
        mem_address <= 32'h999999e0;
        @(posedge clk iff mem_resp);
        mem_write <= 1'b0;
    endtask

    task do_hit_read();
        mem_read <= 1'b1;
        mem_write <= 1'b0;
        mem_address <= 32'hffffffe0;
        repeat (2) @(posedge clk);
        mem_read <= 1'b0;
        if (mem_rdata != 256'hffffffe0) begin
            $error();
        end
        $display(mem_rdata);
    endtask

    bit[31:0] addr_0;
    // int i;
    initial begin
        do_reset();
        $display("Hello from mp3_cache_dut!");
        // for (int i = 0; i < 16; ++i) begin
        //     pmem[i] <= (256'habcdbeef);
        // end

        // addr_0 <= 32'hffffffe0;
        // @(posedge clk);
        // // pmem[addr_0] <= 256'habcdbeef;
        @(posedge clk);
        do_a_read();
        repeat (2) @(posedge clk);
        do_a_read_2();
        repeat (2) @(posedge clk);
        do_a_read_4();
        repeat (2) @(posedge clk);
        do_a_read_3();
        repeat (2) @(posedge clk);
        do_hit_read();
        repeat (4) @(posedge clk);
        do_a_write();
        repeat (2) @(posedge clk);
        $finish;
    end


    //----------------------------------------------------------------------
    // You likely want a process for pmem responses, like this:
    //----------------------------------------------------------------------
    logic [2:0] counter;
    logic [255:0] pmem_out;
    always @(posedge clk) begin
        // Set pmem signals here to behaviorally model physical memory.
        if (pmem_read) begin
            pmem_rdata <= pmem_out;
            pmem_resp <= 1'b1;
        end

        else if (pmem_write) begin
            write_0 <= pmem_wdata;
            pmem_resp <= 1'b1;
        end
        else begin
            pmem_resp <= 1'b0;
        end
    end

    // memory model
    always_comb begin
        case (pmem_address)
            // setting these addresses up for reads
            32'hffffffe0 : pmem_out <= 256'hffffffe0;
            32'hfffffde0 : pmem_out <= 256'hfffffde0;
            32'hfffff9e0 : pmem_out <= 256'hfffff9e0;
            32'hfffffbe0 : pmem_out <= 256'hfffffbe0;
            32'hfffff1e0 : pmem_out <= 256'hfffff1e0;
            32'heeeeeee0 : pmem_out <= 256'heeeeeee0;
            32'hdddddde0 : pmem_out <= 256'hdddddde0;
            32'hcccccce0 : pmem_out <= 256'hcccccce0;
            32'hbbbbbbe0 : pmem_out <= 256'hbbbbbbe0;
            32'haaaaaae0 : pmem_out <= 256'haaaaaae0;

            // setting these addresses up for writes
            32'h999999e0 : pmem_out <= write_0;
            default : pmem_out <= 256'hdeadbeef;
        endcase
    end


endmodule
