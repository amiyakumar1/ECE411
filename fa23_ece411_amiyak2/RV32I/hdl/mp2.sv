
module mp2
import rv32i_types::*;
(
    input clk,
    input rst,
    input mem_resp,
    input rv32i_word mem_rdata,
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
    output rv32i_word mem_address,
    output rv32i_word mem_wdata
);

/******************* Signals Needed for RVFI Monitor *************************/
logic load_pc;
logic load_regfile;
logic load_mdr;
logic load_mar;
/*****************************************************************************/

/**************************** Control Signals ********************************/
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
marmux::marmux_sel_t marmux_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;

/*****************************************************************************/

//wires between control and datapath
logic br_en;
rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic [4:0] rs2;
logic [4:0] rs1;

alu_ops aluop;
branch_funct3_t cmpop;
logic load_ir;
logic load_data_out;

/* Instantiate MP 1 top level blocks here */

// Keep control named `control` for RVFI Monitor
control control(// need to wire
    // inputs
    .clk(clk), //
    .rst(rst), //
    .mem_resp(mem_resp), // 

    // coming from datapath
    // inputs
    .opcode(opcode), // need to wire
    .funct3(funct3), // need to wire
    .funct7(funct7), // need to wire
    .br_en(br_en), // need to wire

    // coming from datapath - register stuff
    // inputs
    .rs1(rs1), // need to wire
    .rs2(rs2), // need to wire
    .mem_address(mem_address),

    // going to datapath - mux selects
    // outputs
    .pcmux_sel(pcmux_sel), 
    .alumux1_sel(alumux1_sel),
    .alumux2_sel(alumux2_sel),
    .regfilemux_sel(regfilemux_sel),
    .marmux_sel(marmux_sel),
    .cmpmux_sel(cmpmux_sel),

    // going to datapath - op signals
    // outuputs
    .aluop(aluop), // need to wire
    .cmpop(cmpop),  // need to wire

    // going to datapath - load signals
    // outputs
    .load_pc(load_pc),
    .load_ir(load_ir), // need to wire
    .load_regfile(load_regfile),
    .load_mar(load_mar),
    .load_mdr(load_mdr),
    .load_data_out(load_data_out), // need to wire

    // outputs
    .mem_read(mem_read), // need to wire
    .mem_write(mem_write),
    .mem_byte_enable(mem_byte_enable)
);

// Keep datapath named `datapath` for RVFI Monitor
datapath datapath(
    
    // inputs
    .clk(clk),
    .rst(rst),

     // going to control
     // outputs
    .br_en(br_en), // need to wire
    .opcode(opcode), // need to wire
    .funct3(funct3), // need to wire
    .funct7(funct7), // need to wire

     // going to control - register stuff
     // outputs
    .rs2(rs2), // need to wire
    .rs1(rs1), // need to wire

    // coming from control - mux selects
    // inputs
    .pcmux_sel(pcmux_sel),
    .alumux1_sel(alumux1_sel),
    .alumux2_sel(alumux2_sel),
    .regfilemux_sel(regfilemux_sel),
    .marmux_sel(marmux_sel),
    .cmpmux_sel(cmpmux_sel),

    // coming from control - op signals
    // inputs
    .aluop(aluop), // need to wire
    .cmpop(cmpop), // need to wire

    // going to control - register stuff
    // outputs
    .load_ir(load_ir), // need to wire
    .load_mdr(load_mdr),
    .load_mar(load_mar),
    .load_pc(load_pc),
    .load_data_out(load_data_out), // need to wire
    .load_regfile(load_regfile),
    
    // mp2 top signals
    // input
    .mem_rdata(mem_rdata),

    // outputs
    .mem_wdata(mem_wdata),
    .mem_address(mem_address)
);

endmodule : mp2
