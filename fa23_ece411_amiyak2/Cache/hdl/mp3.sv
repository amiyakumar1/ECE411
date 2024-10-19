module mp3
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    output  logic   [31:0]  bmem_address,
    output  logic           bmem_read,
    output  logic           bmem_write,
    input   logic   [63:0]  bmem_rdata,
    output  logic   [63:0]  bmem_wdata,
    input   logic           bmem_resp
);

    // this is the order of the data flow: cpu <--> bus_adaptor <--> cache <--> cacheline_adaptor
    // this module interfaces with the physical memory, so all other signals should be reconnected within themselves
    logic mem_resp; // cache to cpu
    rv32i_word mem_rdata; // bus adaptor to cpu
    logic mem_read; // cpu to cache
    logic mem_write; // cpu to cache
    logic [3:0] mem_byte_enable; // cpu to bus adaptor
    rv32i_word mem_address; // cpu to cache, cpu to bus adaptor
    rv32i_word mem_wdata; // cpu to bus adaptor
    logic [255:0] mem_wdata256; // bus adaptor to cache
    logic [255:0] mem_rdata256; // cache to bus adaptor
    logic [31:0] mem_byte_enable256; // bus adaptor to cache


    logic [31:0] pmem_address; // cache to cacheline adaptor
    logic pmem_read; // cache to cacheline adaptor
    logic pmem_write; // cache to cacheline adaptor
    logic [255:0] pmem_rdata; // cacheline adaptor to cache
    logic [255:0] pmem_wdata; // cache to cacheline adaptor
    logic pmem_resp; // cacheline adaptor to cache



    cpu cpu
    (
        .clk(clk),
        .rst(rst),
        .mem_resp(mem_resp), // coming from cache
        .mem_rdata(mem_rdata), // coming from bus adaptor
        .mem_read(mem_read), // going to cache
        .mem_write(mem_write), // going to cache
        .mem_byte_enable(mem_byte_enable), // going to bus adaptor
        .mem_address(mem_address), // going to cache and bus adaptor
        .mem_wdata(mem_wdata) // going to bus adaptor
    );

    bus_adapter bus_adapter
    (
        .address(mem_address), // coming from cpu
        .mem_wdata256(mem_wdata256), // going to cache
        .mem_rdata256(mem_rdata256), // coming from cache
        .mem_wdata(mem_wdata),  // coming from cpu
        .mem_rdata(mem_rdata), // going to cpu
        .mem_byte_enable(mem_byte_enable), // coming from cpu
        .mem_byte_enable256(mem_byte_enable256) // going to cache
    );

    cache cache
    (
        .clk(clk),
        .rst(rst),
        .mem_address(mem_address), // coming from cpu
        .mem_read(mem_read), // coming from cpu
        .mem_write(mem_write), // coming from cpu
        .mem_byte_enable(mem_byte_enable256), // coming from bus adaptor
        .mem_wdata(mem_wdata256), // coming from bus adaptor
        .mem_rdata(mem_rdata256), // going to bus adaptor
        .mem_resp(mem_resp), // going to cpu
        .pmem_address(pmem_address), // going to cacheline adaptor
        .pmem_read(pmem_read), // going to cacheline adaptor
        .pmem_write(pmem_write), // going to cacheline adaptor
        .pmem_rdata(pmem_rdata), // coming from cacheline adaptor
        .pmem_wdata(pmem_wdata), // going to cacheline adaptor
        .pmem_resp(pmem_resp) // coming from cacheline adaptor

    );

    cacheline_adaptor cacheline_adaptor
    (
        .clk(clk),
        .reset_n(~rst),
        .line_i(pmem_wdata), // coming from cache
        .line_o(pmem_rdata), // going to cache
        .address_i(pmem_address), // coming from cache
        .read_i(pmem_read), // coming from cache
        .write_i(pmem_write), // coming from cache
        .resp_o(pmem_resp), // going to cache
        .burst_i(bmem_rdata), // coming from pmem
        .burst_o(bmem_wdata), // going to pmem
        .address_o(bmem_address), // going to pmem
        .read_o(bmem_read), // going to pmem
        .write_o(bmem_write), // going to pmem
        .resp_i(bmem_resp) // coming from pmem
    );

endmodule : mp3
