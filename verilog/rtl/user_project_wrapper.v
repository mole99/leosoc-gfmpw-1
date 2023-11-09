// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdd,		// User area 5.0V supply
    inout vss,		// User area ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [63:0] la_data_in,
    output [63:0] la_data_out,
    input  [63:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

// Connect dummy signals

assign wbs_ack_o = 1'b1;
assign wbs_dat_o = 32'b0;

assign la_data_out = la_data_in; // loopback

assign user_irq = 3'b0;

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

// Not used

assign io_out[4:0] = 5'b00000;
assign io_oeb[4:0] = 5'b11111;

// SPI

assign io_oeb[8:5] = 4'b0100;
assign io_out[7] = 1'b0;

// UART0

assign io_oeb[10:9] = 2'b01;
assign io_out[9] = 1'b0;

// UART1

assign io_oeb[12:11] = 2'b01;
assign io_out[11] = 1'b0;

// Blinky

assign io_oeb[13] = 1'b0;

// GPIO - use 24 bits

wire [31:0] gpio0_in;
wire [31:0] gpio0_out;
wire [31:0] gpio0_oe;

assign io_oeb[37:14] = ~gpio0_oe[23:0];
assign io_out[37:14] =  gpio0_out[23:0];
assign gpio0_in = {8'b00000000, io_in[37:14]};

leosoc leosoc_i (
`ifdef USE_POWER_PINS
	.vdd(vdd),	// User area 1 1.8V power
	.vss(vss),	// User area 1 digital ground
`endif
    .clk        (wb_clk_i),
    .reset      (wb_rst_i),

    .uart0_rx   (io_in[9]),
    .uart0_tx   (io_out[10]),
    
    .uart1_rx   (io_in[11]),
    .uart1_tx   (io_out[12]),
    
    .gpio0_in   (gpio0_in),
    .gpio0_out  (gpio0_out),
    .gpio0_oe   (gpio0_oe),

    .blink      (io_out[13]),
    
    // SPI signals
    .sck        (io_out[5]),
    .sdo        (io_out[6]),
    .sdi        (io_in[7]),
    .cs         (io_out[8])
);

endmodule	// user_project_wrapper

`default_nettype wire
