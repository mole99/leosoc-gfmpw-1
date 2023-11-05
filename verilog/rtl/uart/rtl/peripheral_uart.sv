// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none
`timescale 1ns / 1ps

module peripheral_uart #(
    parameter ADDRESS_BASE = 32'hFF000000,
    parameter FREQUENCY    = 40_000_000,
    parameter BAUDRATE     = 9600
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

    input  logic         uart_rx,
    output logic         uart_tx
);
    localparam ADDRESS_LENGTH = 32'h00000010; // Multiple of 2
    localparam ADDRESS_MASK_UPPER = ~(ADDRESS_LENGTH - 1);
    localparam ADDRESS_MASK_LOWER =  (ADDRESS_LENGTH - 1);

    assign select = (mem_addr & ADDRESS_MASK_UPPER) == ADDRESS_BASE;
    
    logic [31:0] address;
    assign address = mem_addr & ADDRESS_MASK_LOWER;
    
    /*
        Register Map
        
        0x00: uart status |rx_flag|tx_busy|
        0x04: uart rx
        0x08: uart tx
        0x0C: baudrate configuration |wait_cycles|
    */
    
    // Read logic
    always_ff @(posedge clk_i) begin
        mem_rdata <= '0;
        if (select && mem_rstrb) begin
            case (address)
                32'h00: mem_rdata <= {{30{1'b0}}, tx_busy, rx_flag};
                32'h04: mem_rdata <= rx_data_d;
                32'h08: mem_rdata <= '0;
                32'h0C: mem_rdata <= {{16{1'b0}}, wait_cycles};
            endcase
        end
    end
    
    localparam DEFAULT_WAIT_CYCLES = FREQUENCY / BAUDRATE;
    logic [15:0] wait_cycles;
    
    // Write logic
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            wait_cycles <= DEFAULT_WAIT_CYCLES;
        end else begin
            if (select && mem_wstrb) begin
                case (address)
                    32'h00: ;
                    32'h04: ;
                    32'h08: ;
                    32'h0C: begin
                        if (mem_wmask[0]) wait_cycles[ 7:0] <= mem_wdata[ 7:0];
                        if (mem_wmask[1]) wait_cycles[15:8] <= mem_wdata[15:8];
                    end
                endcase
            end
        end
    end
    
    assign mem_done = select && (mem_rstrb || mem_wstrb);
    
    // Synchronize input
    logic uart_rx_sync;

    synchronizer #(
        .FF_COUNT(3)
    ) synchronizer (
        .clk(clk_i),
        .resetn(rst_ni),
        .in(uart_rx),

        .out(uart_rx_sync)
    );
    
    logic rx_flag;
    logic [7:0] rx_data_d;
    
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            rx_flag  <= 1'b0;
            rx_data_d <= '0;
        end else begin
            if (!rx_done_delayed && rx_done) begin
                rx_data_d <= rx_data;
                rx_flag <= 1'b1;
            end
            else if (select && mem_rstrb && address == 32'h00) rx_flag <= 1'b0;
        end
    end
    
    logic [7:0] rx_data;
    logic rx_done;
    logic rx_done_delayed;

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            rx_done_delayed <= 1'b0;
        end else begin
            rx_done_delayed <= rx_done;
        end
    end
    
    uart_rx uart_rx_i (
        .clk    (clk_i),
        .rst    (!rst_ni),
        .rx     (uart_rx),
        .data   (rx_data),
        .valid  (rx_done),
        
        .wait_cycles(wait_cycles)
    );

    logic tx_busy;

    uart_tx uart_tx_i (
        .clk    (clk_i),
        .rst    (!rst_ni),
        .data   (mem_wdata[7:0]),
        .start  (select && mem_wstrb && address == 32'h08),
        .tx     (uart_tx),
        .busy   (tx_busy),
        
        .wait_cycles(wait_cycles)
    );

endmodule
