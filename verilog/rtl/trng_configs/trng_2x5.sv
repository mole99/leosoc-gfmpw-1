
// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none

module trng_2x5 (
    input  clk,     // Sampling clock
    input  trng_en, // Enable all ring oscillators
    output trng_out // Output of the trng
);

    localparam NUM_OSCILLATORS = 2;
    localparam NUM_INVERTER = 5;

    trng #(
        .NUM_INVERTER       (NUM_INVERTER),
        .NUM_OSCILLATORS    (NUM_OSCILLATORS)
    ) trng_i (
        .clk        (clk),
        .trng_en    (trng_en),
        .trng_out   (trng_out)
    );

endmodule
