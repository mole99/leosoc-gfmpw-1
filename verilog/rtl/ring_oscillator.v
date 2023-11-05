// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none

module ring_oscillator #(
    parameter NUM_INVERTER = 101
) (
    input  osc_en, // Enable the ring oscillator
    output osc_out // Output of the ring oscillator
);

    wire [NUM_INVERTER-1:0] inv_out;
    wire inv_gated;

    gf180mcu_fd_sc_mcu7t5v0__and2_1 osc_and (
        .A1  (osc_en),
        .A2  (inv_out[NUM_INVERTER-1]),
        .Z   (inv_gated)
    );

    genvar i;
    generate
        for (i=0; i<NUM_INVERTER; i++) begin

            // First inverter is gated
            if (i == 0) begin
                gf180mcu_fd_sc_mcu7t5v0__inv_1 osc_gated_inv (
                    .I  (inv_gated),
                    .ZN (inv_out[i])
                ); 
            // Just the normal inverters
            end else begin
                gf180mcu_fd_sc_mcu7t5v0__inv_1 osc_inv (
                    .I  (inv_out[i-1]),
                    .ZN (inv_out[i])
                );
            end
        end
    endgenerate

    assign osc_out = inv_gated;

endmodule
