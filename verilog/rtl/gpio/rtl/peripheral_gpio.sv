// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none
`timescale 1ns / 1ps

module peripheral_gpio #(
    parameter ADDRESS_BASE = 32'hFF000000
) (
    input  logic         clk_i,
    input  logic         rst_ni,
    input  logic [31: 0] mem_addr,
    input  logic [31: 0] mem_wdata,
    input  logic [ 3: 0] mem_wmask,
    input  logic         mem_wstrb,
    output logic [31: 0] mem_rdata,
    input  logic         mem_rstrb,
    output logic         mem_done,
    output logic         select,

    input  logic [31: 0] gpio_in,   // State of the I/Os
    output logic [31: 0] gpio_out,  // Output value
    output logic [31: 0] gpio_oe    // Output enable
);
    localparam ADDRESS_LENGTH = 32'h00000010; // Multiple of 2
    localparam ADDRESS_MASK_UPPER = ~(ADDRESS_LENGTH - 1);
    localparam ADDRESS_MASK_LOWER =  (ADDRESS_LENGTH - 1);

    assign select = (mem_addr & ADDRESS_MASK_UPPER) == ADDRESS_BASE;
    
    logic [31:0] address;
    assign address = mem_addr & ADDRESS_MASK_LOWER;
    
    /*
        Register Map
        
        0x00: gpio value    (write = set value, read = get value)
        0x04: output enable (0 = input, 1=output)
    */
    
    // Read logic
    always_ff @(posedge clk_i) begin
        mem_rdata <= '0;
        if (select && mem_rstrb) begin
            case (address)
                32'h00: mem_rdata <= gpio_in;
                32'h04: mem_rdata <= gpio_oe;
            endcase
        end
    end
    
    // Write logic
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            gpio_out <= '0;
            gpio_oe  <= '0;
        end else begin
            if (select && mem_wstrb) begin
                case (address)
                    32'h00: gpio_out <= mem_wdata;
                    32'h04: gpio_oe  <= mem_wdata;
                endcase
            end
        end
    end
    
    assign mem_done = select && (mem_rstrb || mem_wstrb);

endmodule
