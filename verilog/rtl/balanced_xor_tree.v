// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none

module xor_recursive #(
    parameter NUM_INPUTS = 4
) (
    input  [NUM_INPUTS-1:0] a,
    input  [NUM_INPUTS-1:0] b,
    output                  z
);

    genvar i;
    generate

        if (NUM_INPUTS > 1) begin
        
            wire [NUM_INPUTS-1:0] z_tmp;
        
            for (i=0; i<NUM_INPUTS; i++) begin
                gf180mcu_fd_sc_mcu7t5v0__xor2_1 xor_tree_mux2 (
                    .A1  (a[i]),
                    .A2  (b[i]),
                    .Z   (z_tmp[i])
                );
            end
            
            // Recursively instantiate the next stage of the tree
            xor_recursive #(
                .NUM_INPUTS(NUM_INPUTS/2)
            ) xor_recursive_i (
                .a  (z_tmp[NUM_INPUTS/2-1:0]),
                .b  (z_tmp[NUM_INPUTS-1:NUM_INPUTS/2]),
                .z  (z)
            );
            
        // Reached the end of the xor tree
        end else begin
            gf180mcu_fd_sc_mcu7t5v0__xor2_1 xor_tree_mux2 (
                .A1  (a),
                .A2  (b),
                .Z   (z)
            );
        end
    endgenerate

endmodule

module balanced_xor_tree #(
    parameter NUM_INPUTS = 8
) (
    input  [NUM_INPUTS-1:0] xor_in, // Inputs of the xor tree
    output                  xor_out // Output of the xor tree
);

    xor_recursive #(
        .NUM_INPUTS(NUM_INPUTS/2)
    ) xor_tree (
        .a  (xor_in[NUM_INPUTS/2-1:0]),
        .b  (xor_in[NUM_INPUTS-1:NUM_INPUTS/2]),
        .z  (xor_out)
    );

endmodule
