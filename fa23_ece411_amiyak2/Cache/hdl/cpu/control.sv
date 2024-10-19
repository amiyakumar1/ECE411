
module control
import rv32i_types::*; /* Import types defined in rv32i_types.sv */
(
    input clk,
    input rst,
    input mem_resp,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,

    //coming from datapath
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    // added for cp2
    input rv32i_word mem_address,

    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output branch_funct3_t cmpop,                   // added by me
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,

    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable

);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;
/*****************************************************************************/

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = '0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = '1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'b0011 << mem_address[1:0];
                lb, lbu: rmask = 4'b0001 << mem_address[1:0];
                default: trap = '1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011 << mem_address[1:0];
                sb: wmask = 4'b0001 << mem_address[1:0];
                default: trap = '1;
            endcase
        end

        default: trap = '1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */

    // is idle state necessary ??
    FETCH1,
    FETCH2,
    FETCH3,
    DECODE,
    IMM,
    LUI,
    BR,
    AUIPC,
    CALC_ADDR,
    LD1,
    LD2,
    ST1,
    ST2,
    // for checkpoint 2 add states for jal and jalr and reg-reg ops
    JAL,
    JALR,
    REGREG

} state, next_states;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
    // first all the load signals
    load_pc = 1'b0;
    load_ir = 1'b0;
    load_regfile = 1'b0;
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_data_out = 1'b0;

    // now alu and cmp ops -- efault should just be whatever mux 0th signal corresponds to
    aluop = alu_add;
    cmpop = beq;

    // now the select signals
    pcmux_sel = pcmux::pc_plus4;
    alumux1_sel = alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
    regfilemux_sel = regfilemux::alu_out;
    marmux_sel = marmux::pc_out;
    cmpmux_sel = cmpmux::rs2_out;

    mem_read = 1'b0;
    mem_write = 1'b0;
    mem_byte_enable = 4'b0000;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    load_regfile = 1'b1;
    regfilemux_sel = sel;
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
    load_mar = 1'b1;
    marmux_sel = sel;
endfunction

function void loadMDR();
    load_mdr = 1'b1;
endfunction

function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop, alu_ops op);
    /* Student code here */
    // this is where i set the aluop stuff
    
    if (setop) begin
        aluop = op; // else default value
        alumux1_sel = sel1;
        alumux2_sel = sel2;
    end
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, logic setop, branch_funct3_t op);
    // likewise this is where i set the cmpop stuff
    if (setop) begin
        cmpmux_sel = sel;
        cmpop = op;
    end
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */


// this is the state machine
always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    case(state)
        FETCH1 : begin
            loadMAR(marmux::pc_out);
        end

        FETCH2 : begin
            load_mdr = 1'b1;
            mem_read = 1'b1;
        end

        FETCH3  : begin
            load_ir = 1'b1;
        end

        DECODE : begin
            // do nothing here i think, just wait for next state logic
        end

        // i type
        IMM : begin
            loadPC(pcmux::pc_plus4);
            case(arith_funct3)
            //includes these instructions: ADDi, SLTi, SLTiu, XORi, ORi, ANDi, SLLi, SRLi, SRAi
            // x[rd] is rd_in, x[rs1] is rs1_out, immediate is i_imm which is already sexted

            // ADDi
            //    -> x[rd] = x[rs1] + sext(immediate)
            add : begin
                loadRegfile(regfilemux::alu_out);
                setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(funct3));
            end
            
            // SLTi
            //   -> x[rd] = x[rs1] <s sext(immediate)
            // use comparator between rs1 and i_imm (cmpmux::i_imm)
            slt : begin
                loadRegfile(regfilemux::br_en);
                setCMP(cmpmux::i_imm,1'b1,blt);
            end

            // SLTiu
            //    -> x[rd] = x[rs1] <u sext(immediate)
            sltu : begin
                loadRegfile(regfilemux::br_en);
                setCMP(cmpmux::i_imm,1'b1,bltu);
            end

            // XORi
            //    -> x[rd] = x[rs1] ^ sext(immediate)
            axor : begin
                loadRegfile(regfilemux::alu_out);
                setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(funct3));
            end

            // ORi
            //    -> x[rd] = x[rs1] | sext(immediate)
            aor : begin
                loadRegfile(regfilemux::alu_out);
                setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(funct3));
            end

            // ANDi
            //    -> x[rd] = x[rs1] & sext(immediate)
            aand : begin
                loadRegfile(regfilemux::alu_out);
                setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(funct3));
            end

            // SLLi
            //    -> x[rd] = x[rs1] << shamt
            sll : begin
                loadRegfile(regfilemux::alu_out);
                setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(funct3));
            end

            /*
            // SRLi
            //    -> x[rd] = x[rs1] >>u shamt

            // SRAi
            //    -> x[rd] = x[rs1] >>s shamt
            */
            sr : begin
                // differenitniate with bit 30 - if its 0 go to srl otherwise sra
                loadRegfile(regfilemux::alu_out);
                if(funct7[5] == 0) begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
                end
                else begin
                    setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
                end
            end

            endcase
        end

        // u-type
        LUI : begin
            // x[rd] = sext(immediate[31:12] << 12)
            //u_imm already formatted correctly in ir.sv
            loadPC(pcmux::pc_plus4);
            loadRegfile(regfilemux::u_imm);
        end

        BR : begin
            // compare rs1 and rs2, add offset, then branch depending on result
            setCMP(cmpmux::rs2_out, 1'b1, branch_funct3);
            case(br_en)
                1'b0 : begin
                    loadPC(pcmux::pc_plus4);
                end
                1'b1 : begin
                    setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
                    loadPC(pcmux::alu_out);
                end
            endcase

        end

        AUIPC : begin
            loadRegfile(regfilemux::alu_out);
            setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
            loadPC(pcmux::pc_plus4);
        end

        CALC_ADDR : begin
            loadMAR(marmux::alu_out);
            case(opcode)
                op_load : begin
					setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
                end

                op_store : begin
                    setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
                    load_data_out = 1'b1;
                end
            endcase
        end

        LD1 : begin
            loadMDR();
            mem_read = 1'b1;
        end

        // load that value into regfile
        LD2 : begin
            case(load_funct3)
                lb : begin
                    loadRegfile(regfilemux::lb);
                end

                lh : begin
                    loadRegfile(regfilemux::lh);
                end

                lw : begin
                    loadRegfile(regfilemux::lw);
                end

                lbu : begin
                    loadRegfile(regfilemux::lbu);
                end

                lhu : begin
                    loadRegfile(regfilemux::lhu);
                end
            endcase  
            loadPC(pcmux::pc_plus4);
        end

        ST1 : begin
            mem_write = 1'b1;
            // for checkpoint 2 do something with mem_byte_enable here -- similar to the load stuff
            // keep in mind the 32-bit alignment, so: 
            //    for sb, i can store at any address (ending in 0 or 1), so we can be writing to any byte
            //    for sh, i can store at addresses divisible by 2 (ending in 0), so we can be writing to either 1100 or 0011
            //    for sw i can store at addresses divisible by 4 (ending in 00) -- only fully aligned addresses (1111)
            // i need to get the address we're writing to (output of mar) as an input to this sv file 
            // the two bottom bits of mar output should be the amount we shift by, ie, if for sb mar_out[1:0] = 10, we should make mem_byte_enable = 0100

            // moving the shift logic up to where wmask and rmask is set, so now all i have to do is set mem_byte_enable = wmask because i already set the mask
            // this way i don't need an intermediate variable for loads, and i can just set wmask and rmask directly -- probably better this way
            mem_byte_enable = wmask;
            
            setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_ops'(alu_add));
        end

        ST2 : begin
            setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_ops'(alu_add));
            loadPC(pcmux::pc_plus4);
        end

        // x[rd] = pc + 4; pc += sext(offset)
        // offset is j-imm, alu inputs are pc and j_imm, alu adds and goes to pc
        JAL : begin
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_ops'(alu_add));
            loadPC(pcmux::alu_out);
        end

        //  t = pc+4, pc = (x[rs1] + sext(offset))&~1; x[rd]=t
        JALR : begin
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(alu_add));
            // mask low bit for alignment, as explained in spec sheet
            loadPC(pcmux::alu_mod2);
        end

        // similar to imm, have a case statement for different reg reg ops
        // but now instead, i set the second alumux input to rs2_out
        REGREG : begin
            loadPC(pcmux::pc_plus4);
            case(arith_funct3)
            //includes these instructions: ADD, SUB, SLL, SLT, SLTu, XOR, SRL, SRA, OR, AND
            // x[rd] is rd_in, x[rs1] is rs1_out, immediate is i_imm which is already sexted

            // ADD/SUB -- check bit30 to determine which one
            //    -> x[rd] = x[rs1] + sext(immediate)
            add : begin
                // add
                loadRegfile(regfilemux::alu_out);
                if(funct7[5] == 0) begin
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(funct3));
                end
                // sub
                else begin
                    // dont need to worry about 2's complement and inverse for subtraction, sub is already implemented in alu
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(alu_sub));
                end
            end
            
            // SLL
            //   -> x[rd] = x[rs1] << x[rs2]
            // use comparator between rs1 and i_imm (cmpmux::i_imm)
            sll : begin
                loadRegfile(regfilemux::alu_out);
                setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(funct3));
            end

            // SLT
            //    -> x[rd] = x[rs1] <s x[rs2]
            slt : begin
                loadRegfile(regfilemux::br_en);
                setCMP(cmpmux::rs2_out,1'b1,blt);            
            end

            // SLTu
            //    -> x[rd] = x[rs1] <u x[rs2]
            sltu : begin
                loadRegfile(regfilemux::br_en);
                setCMP(cmpmux::rs2_out,1'b1,bltu);            
            end

            // XOR
            //    -> x[rd] = x[rs1] ^ x[rs2]
            axor : begin
                loadRegfile(regfilemux::alu_out);
                setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(funct3));
            end

            /*
            // SRL
            //    -> x[rd] = x[rs1] >>u x[rs2]

            // SRA
            //    -> x[rd] = x[rs1] >>s x[rs2]
            */
            sr : begin
                // differenitniate with bit 30 - if its 0 go to srl otherwise sra
                loadRegfile(regfilemux::alu_out);
                if(funct7[5] == 0) begin
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
                end
                else begin
                    setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
                end
            end

            // OR
            //    -> x[rd] = x[rs1] | x[rs2]
            aor : begin
                loadRegfile(regfilemux::alu_out);
                setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(funct3));
            end

            // AND
            //    -> x[rd] = x[rs1] & x[rs2]
            aand : begin
                loadRegfile(regfilemux::alu_out);
                setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(funct3));
            end

            endcase
        end

    endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
    next_states = FETCH1;
    unique case(state)
        FETCH1 : begin
            next_states = FETCH2;
        end

        FETCH2 : begin
            if(mem_resp == 0) begin
                next_states = FETCH2;
            end
            else begin
                next_states = FETCH3;
            end
        end

        FETCH3  : begin
            next_states = DECODE;
        end

        DECODE : begin
            case(opcode)
                op_lui : begin
                    next_states = LUI;
                end

                op_auipc : begin
                    next_states = AUIPC;
                end

                op_jal : begin
                    next_states = JAL;
                end

                op_jalr : begin
                    next_states = JALR;
                end

                op_br : begin
                    next_states = BR;
                end

                op_load : begin
                    next_states = CALC_ADDR;
                end

                op_store : begin
                    next_states = CALC_ADDR;
                end

                op_imm : begin
                    next_states = IMM;
                end

                op_reg : begin
                    next_states = REGREG;
                end

                op_csr : begin
                    // do nothing? i dont think csr instructions are handled in this mp
                end
            endcase
        end

        IMM : begin
            next_states = FETCH1;
        end

        LUI : begin
            next_states = FETCH1;
        end

        BR : begin
            next_states = FETCH1;
        end

        AUIPC : begin
            next_states = FETCH1;
        end

        CALC_ADDR : begin
            case(opcode)
                op_load : begin
                    next_states = LD1;
                end

                op_store : begin
                    next_states = ST1;
                end
            endcase
        end

        LD1 : begin
            if(mem_resp == 0) begin
                next_states = LD1;
            end
            else begin
                next_states = LD2;
            end
        end

        LD2 : begin
            next_states = FETCH1;
        end

        ST1 : begin
            if(mem_resp == 0) begin
                next_states = ST1;
            end
            else begin
                next_states = ST2;
            end
        end

        ST2 : begin
            next_states = FETCH1;
        end

        JAL : begin
            next_states = FETCH1;
        end

        JALR : begin
            next_states = FETCH1;
        end

        REGREG : begin
            next_states = FETCH1;
        end
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment;

    if(rst) begin
        state <= FETCH1;
    end
    else begin
    /* Assignment of next state on clock edge */
    // here all i do is just set current state to next state i think, its just the transition on the clock edge.
        state <= next_states;
    end
end

endmodule : control
