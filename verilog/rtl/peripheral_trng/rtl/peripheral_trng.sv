// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none
`timescale 1ns / 1ps

module peripheral_trng #(
    parameter ADDRESS_BASE = 32'hFF000000
) (
`ifdef USE_POWER_PINS
    inout vdd,
    inout vss,
`endif
    input  logic         clk_i,
    input  logic         rst_ni,
    input  logic [31: 0] mem_addr,
    input  logic [31: 0] mem_wdata,
    input  logic [ 3: 0] mem_wmask,
    input  logic         mem_wstrb,
    output logic [31: 0] mem_rdata,
    input  logic         mem_rstrb,
    output logic         mem_done,
    output logic         select
);
    localparam ADDRESS_LENGTH = 32'h00000010; // Multiple of 2
    localparam ADDRESS_MASK_UPPER = ~(ADDRESS_LENGTH - 1);
    localparam ADDRESS_MASK_LOWER =  (ADDRESS_LENGTH - 1);

    assign select = (mem_addr & ADDRESS_MASK_UPPER) == ADDRESS_BASE;
    
    logic [31:0] address;
    assign address = mem_addr & ADDRESS_MASK_LOWER;
    
    /*
        Register Map
        
        0x00: trng enable (each bit corresponds to trng)
        0x04: trng value  (each bit corresponds to trng)
    */
    
    logic [31: 0] trng_en;   // Enable the individual trngs
    logic [31: 0] trng_out;  // Output of the individual trngs
    
    // Read logic
    always_ff @(posedge clk_i) begin
        mem_rdata <= '0;
        if (select && mem_rstrb) begin
            case (address)
                32'h00: mem_rdata <= trng_en;
                32'h04: mem_rdata <= trng_out;
            endcase
        end
    end
    
    // Write logic
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            trng_en <= '0;
        end else begin
            if (select && mem_wstrb) begin
                case (address)
                    32'h00: trng_en <= mem_wdata;
                    32'h04: ;
                endcase
            end
        end
    end
    
    assign mem_done = select && (mem_rstrb || mem_wstrb);
    
        trng_1x3 trng_1x3_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[0]),
        .trng_out   (trng_out[0])
    );


    trng_1x5 trng_1x5_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[1]),
        .trng_out   (trng_out[1])
    );


    trng_1x7 trng_1x7_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[2]),
        .trng_out   (trng_out[2])
    );


    trng_2x3 trng_2x3_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[3]),
        .trng_out   (trng_out[3])
    );


    trng_2x5 trng_2x5_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[4]),
        .trng_out   (trng_out[4])
    );


    trng_2x7 trng_2x7_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[5]),
        .trng_out   (trng_out[5])
    );


    trng_8x3 trng_8x3_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[6]),
        .trng_out   (trng_out[6])
    );


    trng_8x5 trng_8x5_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[7]),
        .trng_out   (trng_out[7])
    );


    trng_8x7 trng_8x7_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[8]),
        .trng_out   (trng_out[8])
    );


    trng_32x3 trng_32x3_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[9]),
        .trng_out   (trng_out[9])
    );


    trng_32x5 trng_32x5_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[10]),
        .trng_out   (trng_out[10])
    );


    trng_32x7 trng_32x7_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[11]),
        .trng_out   (trng_out[11])
    );


    trng_128x3 trng_128x3_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[12]),
        .trng_out   (trng_out[12])
    );


    trng_128x5 trng_128x5_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[13]),
        .trng_out   (trng_out[13])
    );


    trng_128x7 trng_128x7_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[14]),
        .trng_out   (trng_out[14])
    );

    // Fill up the rest
    assign trng_out[31:15] = '0;

endmodule
