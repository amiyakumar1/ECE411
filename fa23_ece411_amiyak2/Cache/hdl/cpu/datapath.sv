module datapath
import rv32i_types::*;
(
    input clk,                  
    input rst,

    //cmp output
    output logic br_en,                                     // added by me
    // IR outputs
    output rv32i_opcode opcode,                             // added by me
    output logic [2:0] funct3,                              // added by me
    output logic [6:0] funct7,                              // added by me

    // added by me
    output logic [4:0] rs2,            // rs1, rs2, and rd are set by the IR (output of IR and so output of datapath)
    output logic [4:0] rs1,

    // select signals coming from control
    input pcmux::pcmux_sel_t pcmux_sel,                     // added by me
    input alumux::alumux1_sel_t alumux1_sel,                // added by me
    input alumux::alumux2_sel_t alumux2_sel,                // added by me
    input regfilemux::regfilemux_sel_t regfilemux_sel,      // added by me
    input marmux::marmux_sel_t marmux_sel,                  // added by me
    input cmpmux::cmpmux_sel_t cmpmux_sel,                  // added by me

    // alu and cmp inputs
    input alu_ops aluop,                                    // added by me
    input branch_funct3_t cmpop,                            // added by me

    input load_ir,                                          // added by me
    input load_mdr,
    input load_mar,                                         // added by me
    input load_pc,                                          // added by me
    input load_data_out,                                    // added by me
    input load_regfile,                                     // added by me

    input rv32i_word mem_rdata,
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
    // use for cp2
    output rv32i_word mem_address                           
    /* You will need to connect more signals to your datapath module*/
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word mdrreg_out;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word marmux_out;
rv32i_word cmpmux_out;

rv32i_word i_imm;
rv32i_word s_imm;
rv32i_word b_imm;
rv32i_word u_imm;
rv32i_word j_imm;

rv32i_word pc_out;
rv32i_word alu_out;

rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word regfilemux_out;
logic [4:0] rd;

/*****************************************************************************/


/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor

ir IR(
    //Fill in the wires
    .clk(clk),
    .rst(rst),
    .load(load_ir),
    .in(mdrreg_out),
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd)
);


regfile RF(
    .clk(clk),
    .rst(rst),
    .load(load_regfile), 
    .in(regfilemux_out),
    .src_a(rs1),
    .src_b(rs2),
    .dest(rd),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
);


/*
logic [31:0] mdr;
always_ff @( posedge clk ) begin : mdr_ff
    if (rst) begin
        mdr <= '0;
    end else if (load_mdr) begin
        mdr <= mem_rdata;
    end
end : mdr_ff
assign mdrreg_out = mdr;
*/

// register MDR
always_ff @(posedge clk)
begin
    if(rst)
    begin
        mdrreg_out <= 32'b0;
    end
    else if(load_mdr)
    begin
        mdrreg_out <= mem_rdata;
    end
end

// register MAR
always_ff @(posedge clk)
begin
    if(rst)
    begin
        mem_address <= 32'b0;
    end
    else if(load_mar)
    begin
        mem_address <= marmux_out;
    end
end

// register PC
always_ff @(posedge clk)
begin
    if(rst)
    begin
        pc_out <= 32'h40000000;
    end
    else if(load_pc)
    begin
        pc_out <= pcmux_out;
    end
end

// register MEM_DATA_OUT
rv32i_word mem_temp;
always_ff @(posedge clk)
begin
    if(rst)
    begin
        mem_temp <= 32'b0;
    end
    else if(load_data_out)
    begin
        mem_temp <= rs2_out;
    end
end
assign mem_wdata = mem_temp << (8*mem_address[1:0]);

/*****************************************************************************/

/******************************* ALU and CMP *********************************/

alu ALU(
    .aluop(aluop),
    .a(alumux1_out), 
    .b(alumux2_out),
    .f(alu_out)
);

cmp CMP(
    .cmpop(cmpop),
    .rs1_out(rs1_out),
    .cmpmux_out(cmpmux_out),
    .br_en(br_en)
);

/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog. 
    unique case (marmux_sel)
        marmux::pc_out : marmux_out = pc_out;
        marmux::alu_out : marmux_out = alu_out;
    endcase

    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: pcmux_out  = alu_out;
        pcmux::alu_mod2: pcmux_out = {alu_out[31:1], 1'b0};
    endcase

    unique case (alumux1_sel)
        alumux::rs1_out : alumux1_out = rs1_out;
        alumux::pc_out : alumux1_out = pc_out;
    endcase

    unique case (cmpmux_sel)
        cmpmux::rs2_out : cmpmux_out = rs2_out;
        cmpmux::i_imm : cmpmux_out = i_imm;
    endcase

    unique case (alumux2_sel)
        alumux::i_imm : alumux2_out = i_imm;
        alumux::u_imm : alumux2_out = u_imm;
        alumux::b_imm : alumux2_out = b_imm;
        alumux::s_imm : alumux2_out = s_imm;
        alumux::j_imm : alumux2_out = j_imm;
        alumux::rs2_out : alumux2_out = rs2_out;
    endcase    

    unique case (regfilemux_sel)
        regfilemux::alu_out : regfilemux_out = alu_out;
        regfilemux::br_en : regfilemux_out = {31'b0, br_en};
        regfilemux::u_imm : regfilemux_out = u_imm;
        regfilemux::lw : regfilemux_out = mdrreg_out;
        regfilemux::pc_plus4 : regfilemux_out = pc_out + 4;
        // signed, so sign extend the MSB
        regfilemux::lb : begin
            case(mem_address[1:0])
                2'b00: begin
                    regfilemux_out = {{24{mdrreg_out[7]}}, mdrreg_out[7:0]};
                end
                2'b01: begin
                    regfilemux_out = {{24{mdrreg_out[15]}}, mdrreg_out[15:8]};
                end
                2'b10: begin
                    regfilemux_out = {{24{mdrreg_out[23]}}, mdrreg_out[23:16]};
                end
                2'b11: begin
                    regfilemux_out = {{24{mdrreg_out[31]}}, mdrreg_out[31:24]};
                end
            endcase
        end
        // unsigned so 0 extend the MSB
        regfilemux::lbu : begin
            case(mem_address[1:0])
                2'b00: begin
                    regfilemux_out = {24'b0, mdrreg_out[7:0]};
                end
                2'b01: begin
                    regfilemux_out = {24'b0, mdrreg_out[15:8]};
                end
                2'b10: begin
                    regfilemux_out = {24'b0, mdrreg_out[23:16]};
                end
                2'b11: begin
                    regfilemux_out = {24'b0, mdrreg_out[31:24]};
                end
            endcase
        end
        regfilemux::lh : begin
            case(mem_address[1:0])
                2'b10: begin
                    regfilemux_out = {{16{mdrreg_out[31]}}, mdrreg_out[31:16]};
                end
                default: begin
                    regfilemux_out = {{16{mdrreg_out[15]}}, mdrreg_out[15:0]};
                end
            endcase
        end
        regfilemux::lhu : begin
            case(mem_address[1:0])
                2'b10: begin
                    regfilemux_out = {16'b0, mdrreg_out[31:16]};
                end
                default: begin
                    regfilemux_out = {16'b0, mdrreg_out[15:0]};
                end
            endcase
        end
    endcase
end
/*****************************************************************************/
endmodule : datapath
