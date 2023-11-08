`default_nettype none
`timescale 1ns / 1ps

module user_project_wrapper_wrapper (
`ifdef USE_POWER_PINS
    inout vdd,		// User area 5.0V supply
    inout vss,		// User area ground
`endif

    input clk,
    input reset,

    input  logic uart0_rx,
    output logic uart0_tx,
    
    input  logic uart1_rx,
    output logic uart1_tx,
    
    input  logic [23: 0] gpio0_in,
    output logic [23: 0] gpio0_out,
    output logic [23: 0] gpio0_oe,

    output logic blink
);

    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0, user_project_wrapper_wrapper);
    end

    user_project_wrapper user_project_wrapper_i (
    `ifdef USE_POWER_PINS
        .vdd,
        .vss,
    `endif

        // Wishbone Slave ports (WB MI A)
        .wb_clk_i               (clk),
        .wb_rst_i               (reset),
        .wbs_stb_i              (1'b0),
        .wbs_cyc_i              (1'b0),
        .wbs_we_i               (1'b0),
        .wbs_sel_i              (4'b0000),
        .wbs_dat_i              (32'b0),
        .wbs_adr_i              (32'b0),
        .wbs_ack_o              (),
        .wbs_dat_o              (),

        // Logic Analyzer Signals
        .la_data_in             (64'b0),
        .la_data_out            (),
        .la_oenb                (64'b0),

        // IOs
        .io_in                  (io_in),
        .io_out                 (io_out),
        .io_oeb                 (io_oeb),

        // Independent clock (on independent integer divider)
        .user_clock2            (1'b0),

        // User maskable interrupt signals
        .user_irq               ()
    );

    wire [37:0] io_in;
    wire [37:0] io_out;
    wire [37:0] io_oeb;
    
    assign sck = io_out[5];
    assign sdo = io_out[6];
    assign io_in[7] = sdi;
    assign cs = io_out[8];
    
    assign io_in[9] = uart0_rx;
    assign uart0_tx = io_out[10];
    
    assign io_in[11] = uart1_rx;
    assign uart1_tx = io_out[12];
    
    assign blink = io_out[13];
    
    assign io_in[37:14] = gpio0_in;
    assign gpio0_out = io_out[37:14];
    assign gpio0_oe = io_oeb[37:14];

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
