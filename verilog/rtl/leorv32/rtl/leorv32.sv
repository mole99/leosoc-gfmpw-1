// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none

module leorv32_PC #(
    parameter int RESET_ADDR = 32'h00000000,
    parameter int ADDR_WIDTH = 24
)(
    input logic clk,
    input logic reset,

    input logic next_word,
    input logic jump,
    input logic [ADDR_WIDTH-1:0] jump_addr,
    
    output logic [ADDR_WIDTH-1:0] PC,
    output logic [ADDR_WIDTH-1:0] PCplus4
);

    assign PCplus4 = PC + 4;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            PC <= RESET_ADDR;
        end else begin
            if (next_word) begin
                PC <= PCplus4;
            end
            
            if (jump) begin
                PC <= jump_addr;
            end
        end
    end

endmodule

module leorv32_instr (
    input  logic clk,
    input  logic reset,

    input  logic [31:0] instr_rdata,
    input  logic instr_done,
    
    output logic [31:0] cur_instr
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            cur_instr <= '0;
        end else begin
            if (instr_done) begin
                cur_instr <= instr_rdata;
            end
        end
    end

endmodule

module leorv32_decode #(
    parameter int RV_C = 0 // TODO
)(
    input  logic [31: 0] instr,
    
    // Control signals
    output logic [ 6: 0] opcode,
    output logic [ 4: 0] rd,
    output logic [ 4: 0] rs1,
    output logic [ 4: 0] rs2,
    output logic [ 2: 0] funct3,
    output logic [ 6: 0] funct7,
    
    // Immediates
    output logic [31: 0] I_type_imm,
    output logic [31: 0] S_type_imm,
    output logic [31: 0] B_type_imm,
    output logic [31: 0] U_type_imm,
    output logic [31: 0] J_type_imm
);

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    assign I_type_imm = {{21{instr[31]}}, instr[30:20]};
    assign S_type_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
    assign B_type_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    assign U_type_imm = {instr[31:12], {12{1'b0}}};
    assign J_type_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    // Debug
    logic is_nop;
    assign is_nop = instr === {{12{1'b0}}, {5{1'b0}}, leorv32_pkg::FUNC_ADDI, {5{1'b0}}, leorv32_pkg::OP_IMM};

endmodule

module leorv32_barrel_shifter (
    input        [31:0] data_in,
    input        [ 4:0] shift,
    input               arith,
    output logic [31:0] data_out
);

    logic [32:0] tmp;

    always_comb begin
        tmp = {arith && data_in[31], data_in};
        if (shift[4]) tmp = $signed(tmp) >>> 16;
        if (shift[3]) tmp = $signed(tmp) >>> 8;
        if (shift[2]) tmp = $signed(tmp) >>> 4;
        if (shift[1]) tmp = $signed(tmp) >>> 2;
        if (shift[0]) tmp = $signed(tmp) >>> 1;
        data_out = tmp[31:0];
    end

endmodule

module leorv32_alu (
    input [31:0] operand_a,
    input [31:0] operand_b,

    output wire [31:0] result_add,
    output wire [31:0] result_subtract,

    output wire [31:0] result_and,
    output wire [31:0] result_or,
    output wire [31:0] result_xor,

    output wire result_lt,
    output wire result_ltu,
    output wire result_eq
);

    assign result_add       = operand_a + operand_b;
    assign result_subtract  = operand_a - operand_b;

    assign result_and   = operand_a & operand_b;
    assign result_or    = operand_a | operand_b;
    assign result_xor   = operand_a ^ operand_b;

    assign result_lt    = $signed(operand_a) < $signed(operand_b);
    assign result_ltu   = operand_a < operand_b;
    assign result_eq    = (result_subtract == 0);

endmodule

module leorv32_csr (
    input  logic [11: 0] csr_address,

    // Performance counter
    input  logic [63:0] cycles,
    input  logic [63:0] instret,
    
    // MHARTID
    input  logic [31:0] mhartid,

    // Output
    output logic [31:0] csr_data
);
    always_comb begin
        case (csr_address)
            leorv32_pkg::CSR_RDCYCLE:     csr_data = cycles[31: 0];
            leorv32_pkg::CSR_RDCYCLEH:    csr_data = cycles[63:32];
            leorv32_pkg::CSR_RDTIME:      csr_data = cycles[31: 0];
            leorv32_pkg::CSR_RDTIMEH:     csr_data = cycles[63:32];
            leorv32_pkg::CSR_RDINSTRET:   csr_data = instret[31: 0];
            leorv32_pkg::CSR_RDINSTRETH:  csr_data = instret[63:32];
            leorv32_pkg::CSR_MHARTID:     csr_data = mhartid;
            default: csr_data = '0;
        endcase
    end

endmodule

module leorv32_execute #(
    parameter int ADDR_WIDTH = 24,
    parameter int MHARTID    = 0
)(
    
    // Control signals
    input  logic [ 6: 0] opcode,
    input  logic [ 2: 0] funct3,
    input  logic [ 6: 0] funct7,
    
    // Program Counter
    input logic [ADDR_WIDTH-1:0] PC,
    input logic [ADDR_WIDTH-1:0] PCplus4,
    
    // Performance counter
    input  logic [63: 0] cycles,
    input  logic [63: 0] instret,
    
    // mhartid
    input  logic mhartid_0,
    
    // Immediates
    input  logic [31: 0] I_type_imm,
    input  logic [31: 0] S_type_imm,
    input  logic [31: 0] B_type_imm,
    input  logic [31: 0] U_type_imm,
    input  logic [31: 0] J_type_imm,
    
    // Values
    input  logic [31: 0] rs1_data,
    input  logic [31: 0] rs2_data,
    output logic [31: 0] rd_data,

    // Control flow
    output logic next_word,
    output logic jump,
    output logic [ADDR_WIDTH-1: 0] jump_addr,

    // Load / Store
    output logic [ADDR_WIDTH-1: 0] data_addr,
    output logic [31: 0] data_wdata,
    output logic [ 3: 0] data_wmask
);

    // CSR

    logic [31: 0] csr_data;
    
    leorv32_csr leorv32_csr_inst (
        .csr_address    (I_type_imm[11:0]),

        // Performance counter
        .cycles     (cycles),
        .instret    (instret),
        
        // MHARTID
        .mhartid    (MHARTID | {31'b0, mhartid_0}),

        // Output
        .csr_data   (csr_data)
    );

    // ALU

    logic [31: 0] alu_input1;
    logic [31: 0] alu_input2;

    assign alu_input1 = rs1_data;
    assign alu_input2 = opcode == leorv32_pkg::OP_ARITH ? rs2_data : I_type_imm;

    logic [31: 0] alu_add;
    logic [31: 0] alu_subtract;

    logic [31: 0] alu_and;
    logic [31: 0] alu_or;
    logic [31: 0] alu_xor;

    logic alu_lt;
    logic alu_ltu;
    logic alu_eq;

    leorv32_alu leorv32_alu (
        .operand_a  (alu_input1),
        .operand_b  (alu_input2),

        .result_add     (alu_add),
        .result_subtract(alu_subtract),

        .result_and (alu_and),
        .result_or  (alu_or),
        .result_xor (alu_xor),

        .result_lt  (alu_lt),
        .result_ltu (alu_ltu),
        .result_eq  (alu_eq)
    );

    // Shifter

    logic [4:0] shift_amount;
    assign shift_amount = opcode == leorv32_pkg::OP_IMM ? I_type_imm[4:0] : rs2_data[4:0];

    logic [31:0] rs1_data_r;
    genvar i;
    for (i = 0; i < 32; i = i + 1) assign rs1_data_r[i] = rs1_data[31-i];

    logic [31:0] shifter_input;
    assign shifter_input = funct3[2] ? rs1_data : rs1_data_r;

    logic [31:0] shifter_out;

    leorv32_barrel_shifter leorv32_barrel_shifter_inst (
        .data_in (shifter_input),
        .shift   (shift_amount),
        .arith   (funct7[5]),      // TODO create signals
        .data_out(shifter_out)
    );

    logic [31:0] shifter_out_r;

    for (i = 0; i < 32; i = i + 1) assign shifter_out_r[i] = shifter_out[31-i];

    logic [31:0] shifter_result;
    assign shifter_result = funct3[2] ? shifter_out : shifter_out_r;


    // Load / Store
    // TODO use the ALU
    
    assign data_addr = opcode == leorv32_pkg::OP_LOAD ? rs1_data + I_type_imm :
                       opcode == leorv32_pkg::OP_STORE ? rs1_data + S_type_imm :
                       '0;

    // Store Logic

    always_comb begin
        data_wmask = '0;
        data_wdata  = '0;

        if (opcode == leorv32_pkg::OP_STORE) begin
            case (funct3)  // Width
                leorv32_pkg::FUNC_SB:
                case (data_addr[1:0])
                    2'b00: begin
                        data_wmask = 4'b0001;
                        data_wdata  = rs2_data & 32'h000000FF;
                    end
                    2'b01: begin
                        data_wmask = 4'b0010;
                        data_wdata  = (rs2_data & 32'h000000FF) << 8;
                    end
                    2'b10: begin
                        data_wmask = 4'b0100;
                        data_wdata  = (rs2_data & 32'h000000FF) << 16;
                    end
                    2'b11: begin
                        data_wmask = 4'b1000;
                        data_wdata  = (rs2_data & 32'h000000FF) << 24;
                    end
                endcase
                leorv32_pkg::FUNC_SH:
                case (data_addr[1:0])
                    2'b00: begin
                        data_wmask = 4'b0011;
                        data_wdata  = rs2_data & 32'h0000FFFF;
                    end
                    2'b10: begin
                        data_wmask = 4'b1100;
                        data_wdata  = rs2_data << 16;
                    end
                endcase
                leorv32_pkg::FUNC_SW: begin
                    data_wmask = 4'b1111;
                    data_wdata  = rs2_data;
                end
            endcase
        end
    end

    // Writeback logic
    
    always_comb begin
        rd_data = '0;
        case (opcode)
            leorv32_pkg::OP_IMM:
                case (funct3)
                    leorv32_pkg::FUNC_ADDI:       rd_data = alu_add;
                    leorv32_pkg::FUNC_SLTI:       rd_data = {31'b0, alu_lt};
                    leorv32_pkg::FUNC_SLTIU:      rd_data = {31'b0, alu_ltu};
                    leorv32_pkg::FUNC_ANDI:       rd_data = alu_and;
                    leorv32_pkg::FUNC_ORI:        rd_data = alu_or;
                    leorv32_pkg::FUNC_XORI:       rd_data = alu_xor;
                    leorv32_pkg::FUNC_SLLI:       rd_data = shifter_result;
                    leorv32_pkg::FUNC_SRLI_SRAI:
                        case(I_type_imm[11:5])
                            7'b0000000: rd_data = shifter_result;
                            7'b0100000: rd_data = shifter_result;
                        endcase
                endcase
            leorv32_pkg::OP_ARITH:
                case (funct3)
                    leorv32_pkg::FUNC_ADD_SUB:
                        case(funct7)
                            7'b0000000: rd_data = alu_add;
                            7'b0100000: rd_data = alu_subtract;
                        endcase
                    leorv32_pkg::FUNC_SLT:          rd_data = {31'b0, alu_lt};
                    leorv32_pkg::FUNC_SLTU:         rd_data = {31'b0, alu_ltu};
                    leorv32_pkg::FUNC_AND:          rd_data = alu_and;
                    leorv32_pkg::FUNC_OR:           rd_data = alu_or;
                    leorv32_pkg::FUNC_XOR:          rd_data = alu_xor;
                    leorv32_pkg::FUNC_SLL:          rd_data = shifter_result;
                    leorv32_pkg::FUNC_SRL_SRA:
                        case(funct7)
                            7'b0000000: rd_data = shifter_result;
                            7'b0100000: rd_data = shifter_result;
                        endcase
                endcase
            leorv32_pkg::OP_LUI:    rd_data = U_type_imm;
            leorv32_pkg::OP_AUIPC:  rd_data = PC + U_type_imm;
            leorv32_pkg::OP_JAL:    rd_data = PCplus4;
            leorv32_pkg::OP_JALR:   rd_data = PCplus4;
            leorv32_pkg::OP_SYSTEM:
                case (funct3)
                    leorv32_pkg::FUNC_CSRRW: ;
                    leorv32_pkg::FUNC_CSRRS: rd_data = csr_data;
                    leorv32_pkg::FUNC_CSRRC:  ;
                    leorv32_pkg::FUNC_CSRRWI: ;
                    leorv32_pkg::FUNC_CSRRSI: ;
                    leorv32_pkg::FUNC_CSRRCI: ;
                endcase
        endcase
    end

    // Control flow

    assign jump = opcode == leorv32_pkg::OP_JAL  ||
                  opcode == leorv32_pkg::OP_JALR ||
                  opcode == leorv32_pkg::OP_BRANCH;

    assign next_word = !jump;
    
    always_comb begin
        jump_addr = '0;
        
        case (opcode)
            leorv32_pkg::OP_JAL:    jump_addr = PC + J_type_imm;
            leorv32_pkg::OP_JALR:   jump_addr = ((rs1_data + I_type_imm) & 32'hFFFFFFFE);
            leorv32_pkg::OP_BRANCH:
                case (funct3)
                    leorv32_pkg::FUNC_BEQ:  jump_addr = rs1_data == rs2_data ? PC + B_type_imm : PCplus4;
                    leorv32_pkg::FUNC_BNE:  jump_addr = rs1_data != rs2_data ? PC + B_type_imm : PCplus4;
                    leorv32_pkg::FUNC_BLTU: jump_addr = rs1_data <  rs2_data ? PC + B_type_imm : PCplus4;
                    leorv32_pkg::FUNC_BGEU: jump_addr = rs1_data >= rs2_data ? PC + B_type_imm : PCplus4;
                    leorv32_pkg::FUNC_BLT:  jump_addr = $signed(rs1_data) <  $signed(rs2_data) ? PC + B_type_imm : PCplus4;
                    leorv32_pkg::FUNC_BGE:  jump_addr = $signed(rs1_data) >= $signed(rs2_data) ? PC + B_type_imm : PCplus4;
                endcase
        endcase
    end

endmodule

// TODO rename to leorv32_load?
module leorv32_writeback (
    input  logic [ 6: 0] opcode,
    input  logic [ 2: 0] funct3,
    input  logic [31: 0] rs1_data,

    input  logic [31: 0] data_rdata,
    input  logic [ 1: 0] data_rmask, // TODO it's not really a mask -> one hot
    input  logic [31: 0] exec_rd_data,
    
    output logic [31: 0] rd_data,
    output logic writeback
);
    // Write back logic

    always_comb begin
        writeback = 1'b0;
        case (opcode)
            leorv32_pkg::OP_IMM:    writeback = 1'b1;
            leorv32_pkg::OP_ARITH:  writeback = 1'b1;
            leorv32_pkg::OP_LUI:    writeback = 1'b1;
            leorv32_pkg::OP_AUIPC:  writeback = 1'b1;
            leorv32_pkg::OP_JAL:    writeback = 1'b1;
            leorv32_pkg::OP_JALR:   writeback = 1'b1;
            leorv32_pkg::OP_SYSTEM: if (rs1_data == 0) writeback = 1'b1;
            leorv32_pkg::OP_LOAD:   writeback = 1'b1;
            default:                writeback = 1'b0;
        endcase
    end

    always_comb begin
        rd_data = exec_rd_data; // Default rd_data
        
        // Load operation
        if (opcode == leorv32_pkg::OP_LOAD) begin
            case (funct3)  // Width
                leorv32_pkg::FUNC_LB:
                    case (data_rmask)
                        2'b00: rd_data = {{24{data_rdata[7]}},  data_rdata[7:0]};
                        2'b01: rd_data = {{24{data_rdata[15]}}, data_rdata[15:8]};
                        2'b10: rd_data = {{24{data_rdata[23]}}, data_rdata[23:16]};
                        2'b11: rd_data = {{24{data_rdata[31]}}, data_rdata[31:24]};
                    endcase
                leorv32_pkg::FUNC_LH:
                    case (data_rmask[1])
                        1'b0: rd_data = {{16{data_rdata[15]}}, data_rdata[15:0]};
                        1'b1: rd_data = {{16{data_rdata[23]}}, data_rdata[31:16]};
                    endcase
                leorv32_pkg::FUNC_LW:
                    begin
                        rd_data = data_rdata;
                    end
                leorv32_pkg::FUNC_LBU:
                    case (data_rmask)
                        2'b00: rd_data = {{24{1'b0}}, data_rdata[7:0]};
                        2'b01: rd_data = {{24{1'b0}}, data_rdata[15:8]};
                        2'b10: rd_data = {{24{1'b0}}, data_rdata[23:16]};
                        2'b11: rd_data = {{24{1'b0}}, data_rdata[31:24]};
                    endcase
                leorv32_pkg::FUNC_LHU:
                    case (data_rmask[1])
                        1'b0: rd_data = {{16{1'b0}}, data_rdata[15:0]};
                        1'b1: rd_data = {{16{1'b0}}, data_rdata[31:16]};
                    endcase
            endcase
        end
    end

endmodule

module leorv32_regs (
    input  logic clk,
    input  logic reset,

    // Two read ports
    input  logic [ 4: 0] rs1,
    input  logic [ 4: 0] rs2,
    
    output logic [31: 0] rs1_data,
    output logic [31: 0] rs2_data,
    
    input  logic read,
    
    // One write port
    input logic [ 4: 0] rd,
    input logic [31: 0] rd_data,
    input logic write
);

    logic [31: 0] regs [32]; // TODO only 31 regs

    always_ff @(posedge clk) begin
        if (reset) begin
            regs[0] <= '0; // reg0 must be 0
        end begin
            if (read) begin
                // Two read ports
                rs1_data <= regs[rs1];
                rs2_data <= regs[rs2];
            end
        
            // One write port
            if (write && rd != 0) begin
                regs[rd] <= rd_data;
            end
        end
    end
    
    logic [31:0] sp;
    assign sp = regs[2];
    
    logic [31:0] a0;
    assign a0 = regs[10];

endmodule
    
module leorv32 #(
    parameter int RESET_ADDR = 32'h00000000,
    parameter int ADDR_WIDTH = 24,
    parameter int MHARTID    = 0
) (
    input clk,
    input reset,

    // Instruction Port
    output [ADDR_WIDTH-1: 0] instr_addr,   // address
    input  [31: 0] instr_rdata,  // read data
    output         instr_fetch,  // read
    input          instr_done,   // done

    // Data Port
    output [ADDR_WIDTH-1: 0] data_addr,   // address
    output [31: 0] data_wdata,  // write data
    output [ 3: 0] data_wmask,  // write mask
    input  [31: 0] data_rdata,  // read data
    output         data_rstrb,  // read strobe
    output         data_wstrb,  // write strobe
    input          data_done,   // read busy

    input mhartid_0 // ored with the last bit of MAHRTID
);

    // ----------------------------------
    //        Performance counters
    // ----------------------------------

    logic [63: 0]  cycles;
    logic [63: 0]  instret;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            cycles  <= '0;
        end
        else cycles <= cycles + 1;
    end

    typedef enum {
        ST_FETCH,
        ST_DECODE,
        ST_EXECUTE,
        ST_WRITEBACK
    } state_t;

    state_t cur_state, next_state;
    
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            cur_state <= ST_FETCH;
        end else begin
            cur_state <= next_state;
        end
    end
    
    // TODO storing the instr gives us one cycle penalty
    //      now we have decode + exec together
    //      solution: calculate control signals directly from mem output
    //      and register them
    
    logic st_execute_done;
    assign st_execute_done = (cur_state == ST_EXECUTE) && ((!data_wstrb && !data_rstrb) || data_done);
    
    always_comb begin
        next_state = cur_state;
        case (cur_state)
            ST_FETCH:       if (instr_done) next_state = ST_DECODE;
            ST_DECODE:      next_state = ST_EXECUTE;
            ST_EXECUTE:     if ((!data_wstrb && !data_rstrb) || data_done) next_state = ST_WRITEBACK;
            ST_WRITEBACK:   next_state = ST_FETCH;
        endcase
    end
    
    // TODO set control signals
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            instret <= '0;
        end else begin
            case (cur_state)
                ST_FETCH:       ;
                ST_DECODE:      ;
                ST_EXECUTE:     ; //$display("PC %h, instr %h", PC, cur_instr);
                ST_WRITEBACK:   instret <= instret + 1;  
            endcase
        end
    end
    
    // ----------------------------------
    //              Fetch
    // ----------------------------------

    logic next_word;
    logic jump;
    logic [ADDR_WIDTH-1:0] jump_addr;

    logic [ADDR_WIDTH-1:0] PC;
    logic [ADDR_WIDTH-1:0] PCplus4;


    leorv32_PC #(
        .RESET_ADDR (RESET_ADDR),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) leorv32_PC_inst (
        .clk    (clk),
        .reset  (reset),
    
        .next_word    (next_word && cur_state == ST_WRITEBACK),
        .jump         (jump      && cur_state == ST_WRITEBACK),
        .jump_addr    (jump_addr),

        .PC           (PC),
        .PCplus4      (PCplus4)
    );
    
    assign instr_addr = PC; // address
    assign instr_fetch = cur_state == ST_FETCH; // fetch

    logic [31:0] cur_instr;

    leorv32_instr leorv32_instr_inst (
        .clk    (clk),
        .reset  (reset),
        
        .instr_rdata (instr_rdata),
        .instr_done  (cur_state == ST_DECODE),
        
        .cur_instr   (cur_instr)
    );

    // ----------------------------------
    //              Decode
    // ----------------------------------

    logic [ 6: 0] opcode;
    logic [ 4: 0] rd;
    logic [ 4: 0] rs1;
    logic [ 4: 0] rs2;
    logic [ 2: 0] funct3;
    logic [ 6: 0] funct7;
    
    logic [31: 0] I_type_imm;
    logic [31: 0] S_type_imm;
    logic [31: 0] B_type_imm;
    logic [31: 0] U_type_imm;
    logic [31: 0] J_type_imm;

    leorv32_decode leorv32_decode_inst (
        .instr      (cur_instr),
        
        // Control signals
        .opcode (opcode),
        .rd     (rd),
        .rs1    (rs1),
        .rs2    (rs2),
        .funct3 (funct3),
        .funct7 (funct7),
        
        // Immediates
        .I_type_imm (I_type_imm),
        .S_type_imm (S_type_imm),
        .B_type_imm (B_type_imm),
        .U_type_imm (U_type_imm),
        .J_type_imm (J_type_imm)
    );

    // ----------------------------------
    //             Execute
    // ----------------------------------

    logic [31: 0] exec_rd_data;
    logic [ 3: 0] data_wmask_exec;

    leorv32_execute #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .MHARTID    (MHARTID)
    ) leorv32_execute (
        // Control signals
        .opcode (opcode),
        .funct3 (funct3),
        .funct7 (funct7),
        
        // Program counter
        .PC         (PC),
        .PCplus4    (PCplus4),
        
        // Performance counter
        .cycles     (cycles),
        .instret    (instret),
        
        // mhartid
        .mhartid_0  (mhartid_0),
        
        // Immediates
        .I_type_imm (I_type_imm),
        .S_type_imm (S_type_imm),
        .B_type_imm (B_type_imm),
        .U_type_imm (U_type_imm),
        .J_type_imm (J_type_imm),
        
        // Values
        .rs1_data   (rs1_data),
        .rs2_data   (rs2_data),
        .rd_data    (exec_rd_data),
        
        // Control flow
        .next_word  (next_word),
        .jump       (jump),
        .jump_addr  (jump_addr),
        
        // Load / Store
        .data_addr  (data_addr),
        .data_wdata (data_wdata),
        .data_wmask (data_wmask_exec)
    );
    
    assign data_rstrb = opcode == leorv32_pkg::OP_LOAD  && cur_state == ST_EXECUTE;
    assign data_wstrb = opcode == leorv32_pkg::OP_STORE && cur_state == ST_EXECUTE;
    assign data_wmask = data_wstrb ? data_wmask_exec : 4'b0;

    // ----------------------------------
    //             Writeback
    // ----------------------------------

    logic [31: 0] rd_data;
    logic writeback;

    leorv32_writeback leorv32_writeback_inst (
        .opcode         (opcode),
        .funct3         (funct3),
        .rs1_data       (rs1_data),
        
        .data_rdata     (data_rdata), // Data bus
        .data_rmask     (data_addr[1:0]),
        .exec_rd_data   (exec_rd_data),
        
        .rd_data    (rd_data),
        .writeback  (writeback)
    );
    
    
    // ----------------------------------
    //             Register
    // ----------------------------------

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    leorv32_regs leorv32_regs_inst (
        .clk    (clk),
        .reset  (reset),
    
        // Two read ports
        .rs1        (instr_rdata[19:15]),
        .rs2        (instr_rdata[24:20]),
        
        .rs1_data   (rs1_data),
        .rs2_data   (rs2_data),
        
        .read (cur_state == ST_DECODE),
        
        // One write port
        .rd         (rd),
        .rd_data    (rd_data),
        .write      (writeback && cur_state == ST_WRITEBACK)
    );


endmodule
