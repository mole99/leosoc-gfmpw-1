#!/usr/bin/env python3

configs = [
    {'num_ringos': 1, 'num_inverter': 3},
    {'num_ringos': 1, 'num_inverter': 5},
    {'num_ringos': 1, 'num_inverter': 7},
    
    {'num_ringos': 2, 'num_inverter': 3},
    {'num_ringos': 2, 'num_inverter': 5},
    {'num_ringos': 2, 'num_inverter': 7},
    
    {'num_ringos': 8, 'num_inverter': 3},
    {'num_ringos': 8, 'num_inverter': 5},
    {'num_ringos': 8, 'num_inverter': 7},
    
    {'num_ringos': 32, 'num_inverter': 3},
    {'num_ringos': 32, 'num_inverter': 5},
    {'num_ringos': 32, 'num_inverter': 7},
    
    {'num_ringos': 128, 'num_inverter': 3},
    {'num_ringos': 128, 'num_inverter': 5},
    {'num_ringos': 128, 'num_inverter': 7}
]

source_code = """
// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none

module trng_{}x{} (
    input  clk,     // Sampling clock
    input  trng_en, // Enable all ring oscillators
    output trng_out // Output of the trng
);

    localparam NUM_OSCILLATORS = {};
    localparam NUM_INVERTER = {};

    trng #(
        .NUM_INVERTER       (NUM_INVERTER),
        .NUM_OSCILLATORS    (NUM_OSCILLATORS)
    ) trng_i (
        .clk        (clk),
        .trng_en    (trng_en),
        .trng_out   (trng_out)
    );

endmodule
"""

for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']

    assert (num_inverter % 2 != 0)
    
    with open(f'trng_{num_ringos}x{num_inverter}.sv', 'w') as writer:
        writer.write(source_code.format(num_ringos, num_inverter, num_ringos, num_inverter))
    
