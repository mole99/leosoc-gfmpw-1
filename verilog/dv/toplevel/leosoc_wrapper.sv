`default_nettype none
`timescale 1ns / 1ps

module leosoc_wrapper (
`ifdef USE_POWER_PINS
    inout vdd,
    inout vss,
`endif
    input clk,
    input reset,

    input  logic uart0_rx,
    output logic uart0_tx,
    
    input  logic uart1_rx,
    output logic uart1_tx,
    
    input  logic [31: 0] gpio0_in,
    output logic [31: 0] gpio0_out,
    output logic [31: 0] gpio0_oe,

    output logic blink
);

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, leosoc_wrapper);
    end

    leosoc leosoc_i (
    `ifdef USE_POWER_PINS
        .vdd,
        .vss,
    `endif
        .clk,
        .reset,

        .uart0_rx,
        .uart0_tx,
        
        .uart1_rx,
        .uart1_tx,
        
        .gpio0_in,
        .gpio0_out,
        .gpio0_oe,

        .blink,
        
        // SPI signals
        .sck,
        .sdo,
        .sdi,
        .cs
    );
    
    // SPI signals
    wire sck;
    wire sdo;
    wire sdi;
    wire cs;

    spiflash #(
        .INIT_F("../firmware/firmware.hex"),
        .OFFSET(24'h200000)
    ) spiflash_inst (
        .csb    (cs),
        .clk    (sck),
        .io0    (sdo), // MOSI
        .io1    (sdi), // MISO
        .io2    (),
        .io3    ()
    );

endmodule
