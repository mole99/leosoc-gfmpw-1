
// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none

module trng_1x5 (
    input  clk,     // Sampling clock
    input  trng_en, // Enable all ring oscillators
    output trng_out // Output of the trng
);

    localparam NUM_OSCILLATORS = 1;
    localparam NUM_INVERTER = 5;

    reg trng_out_d;

    always_ff @(posedge clk) begin
        if (trng_en) trng_out_d <= $random;
        else trng_out_d <= 1'b0;
    end
    
    assign trng_out = trng_out_d;

endmodule
