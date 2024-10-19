
module cmp
import rv32i_types::*;
(
    input branch_funct3_t cmpop, // idk
    input [31:0] rs1_out,
    input [31:0] cmpmux_out,
    output logic br_en
);

always_comb
begin
    unique case (cmpop)
        beq:  br_en = (rs1_out == cmpmux_out); // branch equal
        bne:  br_en = (rs1_out != cmpmux_out); // branch not equal
        blt:  br_en = ($signed(rs1_out) < $signed(cmpmux_out)); // branch less than
        bge:  br_en = ($signed(rs1_out) >= $signed(cmpmux_out)); // branch greater than equal
        bltu: br_en = (rs1_out < cmpmux_out); // branch less than unsigned
        bgeu: br_en = (rs1_out >= cmpmux_out); //branch greater equal to unsigned
    endcase
end

endmodule : cmp