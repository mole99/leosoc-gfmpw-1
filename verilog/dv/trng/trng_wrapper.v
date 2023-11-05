`default_nettype none
`timescale 1ns / 1ps

module trng_wrapper (clk,
    trng_en,
    trng_out,
    vdd,
    vss);
 input clk;
 input trng_en;
 output trng_out;
 input vdd;
 input vss;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, trng_wrapper);
    end

    trng trng_i (
    `ifdef USE_POWER_PINS
        .vdd,
        .vss,
    `endif
        .clk,
        .trng_en,
        .trng_out
    );

endmodule
