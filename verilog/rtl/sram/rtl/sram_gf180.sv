// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none
`timescale 1ns / 1ps

`define GF180 // TODO

`ifdef GF180
module gf180_ram_512x32_wrapper (
`ifdef USE_POWER_PINS
    inout VDD,
    inout VSS,
`endif
	input         CLK,   // Clock
	input         CEN,   // Chip enable
	input         GWEN,  // Global write enable
	input  [3:0]  WMASK, // Byte write enable
	input  [8:0]  A,     // Address
	input  [31:0] D,     // Data in
	output [31:0] Q      // Data out
);

    gf180_ram_512x8_wrapper sram512x8_i0 (
    `ifdef USE_POWER_PINS
        .VDD    (VDD), 
        .VSS    (VSS),
    `endif
        .CLK    (CLK), 
        .CEN    (CEN), 
        .GWEN   (GWEN), 
        .WEN    (~{8{WMASK[0]}}), 
        .A      (A), 
        .D      (D[7:0]), 
        .Q      (Q[7:0])
    );

    gf180_ram_512x8_wrapper sram512x8_i1 (
    `ifdef USE_POWER_PINS
        .VDD    (VDD), 
        .VSS    (VSS),
    `endif
        .CLK    (CLK), 
        .CEN    (CEN), 
        .GWEN   (GWEN), 
        .WEN    (~{8{WMASK[1]}}), 
        .A      (A), 
        .D      (D[15:8]), 
        .Q      (Q[15:8])
    );

    gf180_ram_512x8_wrapper sram512x8_i2 (
    `ifdef USE_POWER_PINS
        .VDD    (VDD), 
        .VSS    (VSS),
    `endif
        .CLK    (CLK), 
        .CEN    (CEN), 
        .GWEN   (GWEN), 
        .WEN    (~{8{WMASK[2]}}), 
        .A      (A), 
        .D      (D[23:16]), 
        .Q      (Q[23:16])
    );

    gf180_ram_512x8_wrapper sram512x8_i3 (
    `ifdef USE_POWER_PINS
        .VDD    (VDD), 
        .VSS    (VSS),
    `endif
        .CLK    (CLK), 
        .CEN    (CEN), 
        .GWEN   (GWEN), 
        .WEN    (~{8{WMASK[3]}}), 
        .A      (A), 
        .D      (D[31:24]), 
        .Q      (Q[31:24])
    );

endmodule
`endif

module gf180_ram_32_wrapper
#(
    parameter ADDR_WIDTH = 11,
    parameter INIT_F = ""
)
(
`ifdef USE_POWER_PINS
    inout vdd,
    inout vss,
`endif
    input                   clk,    // Clock
    input                   cen,    // Chip enable
    input                   gwen,   // Global write
    input  [3:0]            wmask,  // Byte write mask
    input  [ADDR_WIDTH-1:0] addr,   // Address
    input  [31:0]           din,    // Data in
    output [31:0]           dout    // Data out
);

    localparam VERBOSE = 0;
    localparam DATA_WIDTH = 32;

`ifdef GF180

    localparam DEFAULT_ADDR_WIDTH = 9; //11 - 9 = 2 -> 2^2 = 4 instances
    localparam NUM_INSTANCES = 2**(ADDR_WIDTH - DEFAULT_ADDR_WIDTH); //11 - 9 = 2 -> 2^2 = 4 instances

    initial begin
        $display("NUM_INSTANCES %d", NUM_INSTANCES);
        
        if (ADDR_WIDTH < DEFAULT_ADDR_WIDTH) begin
            $fatal("ADDR_WIDTH must not be smaller than DEFAULT_ADDR_WIDTH!");
        end
    end

    logic [NUM_INSTANCES-1:0] select_instance;
    logic [NUM_INSTANCES*DATA_WIDTH-1:0] select_dout;

    generate
        if (ADDR_WIDTH > DEFAULT_ADDR_WIDTH) begin
            assign select_instance = 1'b1 << (addr[ADDR_WIDTH-1:DEFAULT_ADDR_WIDTH]); // addr[10:9]
        end else begin
            assign select_instance = 1'b1;
        end
    endgenerate


    initial begin
        if (VERBOSE) begin
            $monitor("select_instance %b address %b", select_instance, addr);
            $monitor("addr[ADDR_WIDTH-1:DEFAULT_ADDR_WIDTH] %b", addr[ADDR_WIDTH-1:DEFAULT_ADDR_WIDTH]);
        end
    end

    generate
        genvar i;
        for (i = 0; i < NUM_INSTANCES; i++) begin : memory
            gf180_ram_512x32_wrapper sram512x32_i (
            `ifdef USE_POWER_PINS
                .VDD(vdd),
                .VSS(vss),
            `endif
	            .CLK    (clk),
	            .CEN    (cen),
	            .GWEN   (gwen),
	            .WMASK  (wmask),
	            .A      (addr[DEFAULT_ADDR_WIDTH-1:0]),
	            .D      (din),
	            .Q      (select_dout[i*DATA_WIDTH+:DATA_WIDTH])
            );
        end
    endgenerate

    generate
        if (ADDR_WIDTH > DEFAULT_ADDR_WIDTH) begin
            assign dout = select_dout[addr[ADDR_WIDTH-1:DEFAULT_ADDR_WIDTH]*DATA_WIDTH+:DATA_WIDTH];
        end else begin
            assign dout = select_dout[DATA_WIDTH-1:0];
        end
    endgenerate

`else

    localparam RAM_DEPTH = 1 << ADDR_WIDTH;
    logic [DATA_WIDTH-1:0] mem[RAM_DEPTH];

    initial begin
        if (INIT_F != 0) begin
            if (VERBOSE) $display("Initializing BRAM with: '%s'", INIT_F);
            $readmemh(INIT_F, mem);
        end
    end

    // Memory Write Block
    always_ff @(posedge clk) begin
        if (cen && gwen) begin
            if (wmask[0]) mem[addr][ 7: 0] <= din[7:0];
            if (wmask[1]) mem[addr][15: 8] <= din[15:8];
            if (wmask[2]) mem[addr][23:16] <= din[23:16];
            if (wmask[3]) mem[addr][31:24] <= din[31:24];
        end
    end

    reg [31:0] dout_reg;

    // Memory Read Block
    always_ff @(posedge clk) begin
        if (cen) begin
            dout_reg <= mem[addr];
        end
    end
    
    assign dout = dout_reg;

`endif

endmodule
