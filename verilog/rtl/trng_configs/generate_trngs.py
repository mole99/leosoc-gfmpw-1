#!/usr/bin/env python3

import os

configs = [
    {'num_ringos': 1, 'num_inverter': 3, 'size': 70},
    {'num_ringos': 1, 'num_inverter': 5, 'size': 70},
    {'num_ringos': 1, 'num_inverter': 7, 'size': 70},
    
    {'num_ringos': 2, 'num_inverter': 3, 'size': 75},
    {'num_ringos': 2, 'num_inverter': 5, 'size': 75},
    {'num_ringos': 2, 'num_inverter': 7, 'size': 75},
    
    {'num_ringos': 8, 'num_inverter': 3, 'size': 80},
    {'num_ringos': 8, 'num_inverter': 5, 'size': 85},
    {'num_ringos': 8, 'num_inverter': 7, 'size': 90},
    
    {'num_ringos': 32, 'num_inverter': 3, 'size': 130},
    {'num_ringos': 32, 'num_inverter': 5, 'size': 135},
    {'num_ringos': 32, 'num_inverter': 7, 'size': 140},
    
    {'num_ringos': 128, 'num_inverter': 3, 'size': 230},
    {'num_ringos': 128, 'num_inverter': 5, 'size': 240},
    {'num_ringos': 128, 'num_inverter': 7, 'size': 250}
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

source_code_model = """
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

    reg trng_out_d;

    always_ff @(posedge clk) begin
        if (trng_en) trng_out_d <= $random;
        else trng_out_d <= 1'b0;
    end
    
    assign trng_out = trng_out_d;

endmodule
"""

max_width = 2800
current_x = 300
current_y = 72
current_size = 0

margin = 20

for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']

    assert (num_inverter % 2 != 0)
    
    with open(f'trng_{num_ringos}x{num_inverter}.sv', 'w') as writer:
        writer.write(source_code.format(num_ringos, num_inverter, num_ringos, num_inverter))
    
    with open(f'trng_{num_ringos}x{num_inverter}_model.sv', 'w') as writer:
        writer.write(source_code_model.format(num_ringos, num_inverter, num_ringos, num_inverter))
    
    # Fits in current line
    if current_x + config['size'] + 2*margin <= max_width:
        print(f'leosoc_i.peripheral_trng_i.trng_{num_ringos}x{num_inverter}_i {current_x + margin} {current_y + margin} N')
        current_x += config['size'] + 2*margin
        
        if current_size < config["size"]:
            current_size = config["size"]
    
    else:
        current_x = 0
        current_y += current_size + 2*margin
        
        print(f'leosoc_i.peripheral_trng_i.trng_{num_ringos}x{num_inverter}_i {current_x + margin} {current_y + margin} N')
        current_x += config['size'] + 2*margin

instantiation = """
    trng_{}x{} trng_{}x{}_i (
    `ifdef USE_POWER_PINS
        .vdd        (vdd),
        .vss        (vss),
    `endif
        .clk        (clk_i),
        .trng_en    (trng_en[{}]),
        .trng_out   (trng_out[{}])
    );
"""

index = 0
for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']

    assert (num_inverter % 2 != 0)
    
    print(instantiation.format(num_ringos, num_inverter, num_ringos, num_inverter, index, index))
    index += 1

print('	"VERILOG_FILES": [')
directory = '		"dir::../../verilog/rtl/trng_configs/trng_{}x{}.sv",'
index = 0
for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']

    assert (num_inverter % 2 != 0)
    
    print(directory.format(num_ringos, num_inverter))
    index += 1
print('	],')

print('	"VERILOG_FILES_BLACKBOX": [')
directory = '		"dir::../../verilog/gl/trng_{}x{}.v",'
index = 0
for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']

    assert (num_inverter % 2 != 0)
    
    print(directory.format(num_ringos, num_inverter))
    index += 1
print('	],')

print('	"EXTRA_LEFS": [')
directory = '	    "dir::../../lef/trng_{}x{}.lef",'
index = 0
for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']

    assert (num_inverter % 2 != 0)
    
    print(directory.format(num_ringos, num_inverter))
    index += 1
print('	],')

print('	"EXTRA_GDS_FILES": [')
directory = '    	"dir::../../gds/trng_{}x{}.gds",'
index = 0
for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']

    assert (num_inverter % 2 != 0)
    
    print(directory.format(num_ringos, num_inverter))
    index += 1
print('	],')

print('	"EXTRA_LIBS": [')
directory = '	    "dir::../../lib/trng_{}x{}.lib",'
index = 0
for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']

    assert (num_inverter % 2 != 0)
    
    print(directory.format(num_ringos, num_inverter))
    index += 1
print('	],')

print('	"EXTRA_SPEFS": [')
directory = """		"trng_{}x{}",
		"dir::../../spef/multicorner/trng_{}x{}.min.spef",
		"dir::../../spef/multicorner/trng_{}x{}.nom.spef",
		"dir::../../spef/multicorner/trng_{}x{}.max.spef","""

index = 0
for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']

    assert (num_inverter % 2 != 0)
    
    print(directory.format(num_ringos, num_inverter, num_ringos, num_inverter, num_ringos, num_inverter, num_ringos, num_inverter))
    index += 1
print('	],')

print('Make:')
directory = 'make trng_{}x{} && \\'
index = 0
for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']

    assert (num_inverter % 2 != 0)
    
    print(directory.format(num_ringos, num_inverter))
    index += 1


# Create Openlane configs


config_json = """{{
	"PDK": "gf180mcuD",
	"STD_CELL_LIBRARY": "gf180mcu_fd_sc_mcu7t5v0",
	"DESIGN_NAME": "trng_{}x{}",
	"VERILOG_FILES": [
		"dir::../../verilog/rtl/trng_configs/trng_{}x{}.sv",
		"dir::../../verilog/rtl/trng.sv",
        "dir::../../verilog/rtl/balanced_xor_tree.v",
        "dir::../../verilog/rtl/ring_oscillator.v"
	],
	"DESIGN_IS_CORE": 0,
	"CLOCK_PORT": "clk",
	"CLOCK_PERIOD": "24.0",
	"FP_SIZING": "absolute",
	"DIE_AREA": "0 0 {} {}",
	"FP_PIN_ORDER_CFG": "dir::pin_order.cfg",
	"PL_BASIC_PLACEMENT": 0,
	"PL_TARGET_DENSITY": 0.45,
	"ROUTING_CORES": 6,
	"MAX_FANOUT_CONSTRAINT": 4,
	"RT_MAX_LAYER": "Metal4",
	"VDD_NETS": [
		"vdd"
	],
	"GND_NETS": [
		"vss"
	],
	"SYNTH_READ_BLACKBOX_LIB": 1
}}"""

pin_order = """#BUS_SORT

#N

clk
trng_en
trng_out

#E

#S

#W
"""

for config in configs:
    num_inverter = config['num_inverter']
    num_ringos   = config['num_ringos']
    size   = config['size']

    assert (num_inverter % 2 != 0)
    
    os.makedirs(f'trng_{num_ringos}x{num_inverter}', exist_ok=True)
    
    with open(f'trng_{num_ringos}x{num_inverter}/config.json', 'w') as writer:
        writer.write(config_json.format(num_ringos, num_inverter, num_ringos, num_inverter, size, size))
    
    with open(f'trng_{num_ringos}x{num_inverter}/pin_order.cfg', 'w') as writer:
        writer.write(pin_order)
