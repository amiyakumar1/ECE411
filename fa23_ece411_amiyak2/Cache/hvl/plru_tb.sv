module plru_tb;

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

    logic web0;
    logic [1:0] way_in;
    logic [1:0] way_out;
    logic [1:0] expected_way;
    int i;

    task do_reset();
        // Fill this out
        rst <= 1'b1;
        repeat (10) @(posedge clk);
        rst <= 1'b0;
    endtask : do_reset

    task loop_stuff();
        web0 <= 1'b0;
        way_in <= way_out;
        @(posedge clk);
        web0 <= 1'b1;
        $display(way_out);
        @(posedge clk);
    endtask

    task eviction_stuff(input counter);
        web0 <= 1'b0;
        case(way_out)
            2'b00 : begin
                case(counter)
                    2'b00 : begin
                        way_in <= 2'b00;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b1x;
                    end
                    2'b01 : begin
                        way_in <= 2'b01;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b1x;
                    end
                    2'b10 : begin
                        way_in <= 2'b10;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b00;
                    end
                    2'b11 : begin
                        way_in <= 2'b11;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b00;
                    end
                endcase
            end

            2'b01 : begin
                case(counter)
                    2'b00 : begin
                        way_in <= 2'b00;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b1x;
                    end
                    2'b01 : begin
                        way_in <= 2'b01;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b1x;
                    end
                    2'b10 : begin
                        way_in <= 2'b10;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b01;
                    end
                    2'b11 : begin
                        way_in <= 2'b11;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b01;
                    end
                endcase
            end

            2'b10 : begin
                case(counter)
                    2'b00 : begin
                        way_in <= 2'b00;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b10;
                    end
                    2'b01 : begin
                        way_in <= 2'b01;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b10;
                    end
                    2'b10 : begin
                        way_in <= 2'b10;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b0x;
                    end
                    2'b11 : begin
                        way_in <= 2'b11;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b0x;
                    end
                endcase
            end

            2'b11 : begin
                case(counter)
                    2'b00 : begin
                        way_in <= 2'b00;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b11;
                    end
                    2'b01 : begin
                        way_in <= 2'b01;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b11;
                    end
                    2'b10 : begin
                        way_in <= 2'b10;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b0x;
                    end
                    2'b11 : begin
                        way_in <= 2'b11;
                        @(posedge clk);
                        web0 <= 1'b1;
                        expected_way <= 2'b0x;
                    end
                endcase
            end

        endcase

        @(posedge clk);
        if (way_out !?= expected_way) begin
            $error("way mismatch");
        end


    endtask

    //----------------------------------------------------------------------
    // Instantiate your DUT here.
    //----------------------------------------------------------------------

    plru dut
    (
    .clk0(clk),
    .rst0(rst),
    .csb0(1'b0),
    .web0(web0),
    .din0(way_in),
    .dout0(way_out)
    );

    //----------------------------------------------------------------------
    // Write your tests and run them here!
    //----------------------------------------------------------------------
    // Recommended: package your tests into tasks.
    // logic [1:0] counter;
    initial begin
        $display("Hello from mp3_cache_dut!");

        do_reset();
        web0 <= 1'b1;
        // counter <= 2'b00;
        // basic looping test

        for (int i = 0; i < 50; ++i) begin
            loop_stuff();
        end

        // extensive eviction test

        // for (i = 0; i < 16; ++i) begin
        //     eviction_stuff(counter);
        //     counter = counter + 1;
        // end

        $finish;
    end


endmodule
