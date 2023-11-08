// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none

module dffram_512x32 (
`ifdef USE_POWER_PINS
    inout VDD,
    inout VSS,
`endif
	input         CLK,   // Clock
	input         CEN,   // Chip enable
	input         GWEN,  // Global write enable
	input  [3:0]  WMASK, // Byte write enable
	input  [8:0]  A,     // Address
	input  [7:0]  D,     // Data in
	output logic [7:0] Q      // Data out
);

    logic [7:0] memory [512];
    
    always_ff @(posedge CLK) begin
        if (!CEN) begin
            if (!GWEN) begin
                memory[A] <= D;
            end else begin
                Q <= memory[A];
            end
        end
    end

endmodule
