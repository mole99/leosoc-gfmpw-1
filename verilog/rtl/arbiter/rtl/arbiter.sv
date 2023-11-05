// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none
`timescale 1ns / 1ps

module arbiter #(
    parameter int NUM_PORTS = 2,
    // TODO algorithm
    parameter ALGORITHM = "ROUNDROB"
) (
    input  logic clk,
    input  logic reset,

    input  logic [NUM_PORTS-1:0] claim_signals,
    output logic [NUM_PORTS-1:0] granted_signals // one-hot
);

    // Which port is currently granted access
    // current_granted = 0 means that no port has access
    logic [$clog2(NUM_PORTS+1)-1:0] current_granted;
    
    // Used to determine next port access
    logic [$clog2(NUM_PORTS+1)-1:0] next_granted;
    
    always_comb begin
        next_granted = '0;
        
        if (ALGORITHM == "PRIORITY") begin
            // Lowest port has highest priority
            for (int i=NUM_PORTS-1; i>=0; i--) begin
                if (claim_signals[i] == 1'b1) begin
                    /* verilator lint_off WIDTHTRUNC */
                    next_granted = i + 1;
                    /* verilator lint_on WIDTHTRUNC */
                end
            end
        end
        
        if (ALGORITHM == "ROUNDROB") begin
            // Grant the next port
            /* verilator lint_off WIDTHEXPAND */
            if (current_granted < NUM_PORTS) begin
            /* verilator lint_on WIDTHEXPAND */
                next_granted = current_granted + 1;
            end else begin
                next_granted = '0;
            end
        end
    end

    // Manage access
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            current_granted <= '0;
        end else begin
            
            // Claim has been released
            if (claim_signals[current_granted-1] == 1'b0) begin

                // Let's see who wants to claim
                current_granted <= next_granted;
            end
            
            // Currently nothing is granted, let's see who wants to claim
            if (current_granted == '0) begin
                current_granted <= next_granted;                
            end
        end
    end

    // Combinatorial for instant access
    always_comb begin
        granted_signals = '0;
    
        // Bus is free
        if (current_granted == '0) begin
            // Someone wants to claim
            if (next_granted != 1'b0) begin
                granted_signals = 1'b1 << (next_granted-1);
            end
        // Bus already claimed
        end else begin
            if (current_granted != 1'b0) begin
                granted_signals = 1'b1 << (current_granted-1);
            end
        end
    end

endmodule
