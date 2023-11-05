// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none

module trng #(
    parameter NUM_INVERTER = 5,
    parameter NUM_OSCILLATORS = 8
) (
    input  clk,     // Sampling clock
    input  trng_en, // Enable all ring oscillators
    output trng_out // Output of the trng
);

    logic [NUM_OSCILLATORS-1:0] osc_out;

    // Stage 1: Oscillators

    genvar i;
    generate
        for (i=0; i<NUM_OSCILLATORS; i++) begin

            ring_oscillator #(
                .NUM_INVERTER(NUM_INVERTER)
            ) ring_oscillator_i (
                .osc_en (trng_en),
                .osc_out (osc_out[i])
            );

        end
    endgenerate

    // Stage 2: Capture output of oscillators

    logic [NUM_OSCILLATORS-1:0] osc_out_d;

    always_ff @(posedge clk) begin
        osc_out_d <= osc_out;
    end

    // Stage 3: Balanced xor tree

    logic xor_out;

    generate
        if (NUM_OSCILLATORS == 1) begin
            assign xor_out = osc_out_d;
        end else begin
            balanced_xor_tree #(
                .NUM_INPUTS(NUM_OSCILLATORS)
            ) balanced_xor_tree_i (
                .xor_in (osc_out_d),
                .xor_out (xor_out)
            );
        end
    endgenerate

    // Stage 4: Synchronizer
    
    logic [3:0] xor_out_sync;
    
    always_ff @(posedge clk) begin
        xor_out_sync <= {xor_out_sync[2:0], xor_out};
    end
    
    // Output
    
    assign trng_out = xor_out_sync[3];

endmodule
