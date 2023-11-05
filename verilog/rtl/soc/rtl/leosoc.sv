// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none
`timescale 1ns / 1ps

module leosoc #(
    parameter int FREQUENCY = 40_000_000,
    parameter int BAUDRATE  = 9600,
    parameter int NUM_CORES = 2,
    parameter int INSTR_CACHE = 1,
    parameter int INSTR_CACHE_SIZE = 32
) (
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

    output logic blink,
    
    // SPI signals
    output sck,
    output sdo,
    input  sdi,
    output cs
);

    // Configuration

    localparam SOC_ADDRW = 32;

    localparam NUM_WMASKS = 4;
    localparam DATA_WIDTH = 32;
    localparam WRAM_ADDR_WIDTH = 9;

    localparam WRAM_MASK        = 8'h00;
    localparam SPI_FLASH_MASK   = 8'h02;
    localparam BLINK_MASK       = 8'h0F;
    
    localparam UART0_BASE_ADDRESS = 32'h03000000;
    localparam UART1_BASE_ADDRESS = 32'h04000000;
    localparam GPIO0_BASE_ADDRESS = 32'h05000000;

    // ----------------------------------
    //           LeoRV32 Core
    // ----------------------------------

    logic [31: 0] mem_addr;
    logic [31: 0] mem_wdata;
    logic [ 3: 0] mem_wmask;
    logic         mem_wstrb;
    logic [31: 0] mem_rdata;
    logic         mem_rstrb;
    logic         mem_done;
    
    // Peripherals have no latency (except SPI Flash)
    assign mem_done = soc_spi_flash_sel ? spi_flash_done && mem_rstrb : mem_rstrb || mem_wstrb;

    core_wrapper #(
        .NUM_CORES          (NUM_CORES),
        .RESET_ADDR         (32'h02000000 + 32'h00200000),
        .ADDR_WIDTH         (SOC_ADDRW),
        .INSTR_CACHE        (INSTR_CACHE),
        .INSTR_CACHE_SIZE   (INSTR_CACHE_SIZE)
    ) core_wrapper (
        .clk    (clk),
        .reset  (reset),
        
        .mem_addr (mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wmask(mem_wmask),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_rstrb(mem_rstrb),
        .mem_done (mem_done)
    );
    
    logic soc_wram_sel;
    logic soc_spi_flash_sel;
    logic soc_blink_sel;
    
    assign soc_wram_sel         = mem_addr[31:24] == WRAM_MASK;
    assign soc_spi_flash_sel    = mem_addr[31:24] == SPI_FLASH_MASK;
    assign soc_blink_sel        = mem_addr[31:24] == BLINK_MASK;
    
    logic soc_wram_sel_del;
    logic soc_spi_flash_sel_del;
    logic soc_blink_sel_del;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            soc_wram_sel_del        <= 1'b0;
            soc_spi_flash_sel_del   <= 1'b0;
            soc_blink_sel_del       <= 1'b0;
        end else begin
            soc_wram_sel_del        <= soc_wram_sel;
            soc_spi_flash_sel_del   <= soc_spi_flash_sel;
            soc_blink_sel_del       <= soc_blink_sel;
        end
    end

    // WRAM Memory
    
    // Memory Port 1 - R/W
    logic wram_web0;
    logic [NUM_WMASKS-1:0] wram_wmask0;
    logic [WRAM_ADDR_WIDTH-1:0] wram_addr0;
    logic [DATA_WIDTH-1:0] wram_din0;
    logic [DATA_WIDTH-1:0] wram_dout0;

    gf180_ram_32_wrapper
    #(
        .ADDR_WIDTH (WRAM_ADDR_WIDTH),
        .INIT_F     ("")
    )
    wram
    (
    `ifdef USE_POWER_PINS
        .vdd    (vdd),
        .vss    (vss),
    `endif
        .clk    (clk),
        .cen    (reset),
        .gwen   (wram_web0),
        .wmask  (wram_wmask0),
        .addr   (wram_addr0),
        .din    (wram_din0),
        .dout   (wram_dout0)
    );
    
    // SoC read data
    logic [DATA_WIDTH-1:0] mem_rdata_memory;
    
    // Connect WRAM
    assign wram_web0        = !(mem_wstrb && soc_wram_sel);
    assign wram_wmask0      = mem_wmask;
    assign wram_addr0       = mem_addr >> 2;
    assign wram_din0        = mem_wdata;
    assign mem_rdata_memory = wram_dout0;

    always_comb begin
        // SPI Flash
        if (soc_spi_flash_sel_del) begin
            mem_rdata = spi_flash_rdata;
        // Blink
        end else if (soc_blink_sel_del) begin
            mem_rdata = {32{blink}};
        // UART0
        end else if (uart0_select_del) begin
            mem_rdata = uart0_rdata;
        // UART1
        end else if (uart1_select_del) begin
            mem_rdata = uart1_rdata;
        // GPIO0
        end else if (gpio0_select_del) begin
            mem_rdata = gpio0_rdata;
        // WRAM
        end else begin
            mem_rdata = mem_rdata_memory;
        end
    end

    // Blinky

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            blink <= 1'b0;
        end else if (soc_blink_sel && mem_wstrb) begin
            blink <= mem_wdata[0];
        end
    end

    // Uart

    /*logic mem_rstrb_delayed;
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            mem_rstrb_delayed <= 1'b0;
        end else begin
            mem_rstrb_delayed <= mem_rstrb;
        end
    end

    logic rx_flag;
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            rx_flag  <= 1'b0;
        end else begin
            if (!rx_done_delayed && rx_done) rx_flag <= 1'b1;
            else if (soc_uart_sel && mem_rstrb) rx_flag <= 1'b0;
        end
    end
    
    logic [DATA_WIDTH-1: 0] uart_reg;
    assign uart_reg = {rx_flag, tx_busy, {22{1'b0}}, rx_received};

    logic [7:0] rx_received;
    logic rx_done;
    logic rx_done_delayed;

    always_ff @(posedge clk) begin
        if (reset) begin
            rx_done_delayed <= 1'b0;
        end else begin
            rx_done_delayed <= rx_done;
        end
    end

    my_uart_rx #(
        .FREQUENCY(FREQUENCY),
        .BAUDRATE (BAUDRATE)
    ) my_uart_rx (
        .clk    (clk),
        .rst    (reset),
        .rx     (uart_rx_sync),
        .data   (rx_received),
        .valid  (rx_done)
    );

    logic tx_busy;

    my_uart_tx #(
        .FREQUENCY(FREQUENCY),
        .BAUDRATE (BAUDRATE)
    ) my_uart_tx (
        .clk    (clk),
        .rst    (reset),
        .data   (mem_wdata[7:0]),
        .start  (soc_uart_sel && mem_wstrb),
        .tx     (uart_tx),
        .busy   (tx_busy)
    );*/

    // UART0 Peripheral
    
    logic [31:0] uart0_rdata;
    logic uart0_done; // Not used
    logic uart0_select;
    
    logic uart0_select_del;
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            uart0_select_del <= 1'b0;
        end else begin
            uart0_select_del <= uart0_select;
        end
    end
    
    peripheral_uart #(
        .ADDRESS_BASE   (UART0_BASE_ADDRESS),
        .FREQUENCY      (FREQUENCY),
        .BAUDRATE       (BAUDRATE)
    ) peripheral_uart_i0 (
        .clk_i      (clk),
        .rst_ni     (!reset),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wmask  (mem_wmask),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (uart0_rdata),
        .mem_rstrb  (mem_rstrb),
        .mem_done   (uart0_done),
        .select     (uart0_select),
        
        .uart_rx    (uart0_rx),
        .uart_tx    (uart0_tx)
    );
    
    // UART1 Peripheral
    
    logic [31:0] uart1_rdata;
    logic uart1_done; // Not used
    logic uart1_select;
    
    logic uart1_select_del;
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            uart1_select_del <= 1'b0;
        end else begin
            uart1_select_del <= uart1_select;
        end
    end
    
    peripheral_uart #(
        .ADDRESS_BASE   (UART1_BASE_ADDRESS),
        .FREQUENCY      (FREQUENCY),
        .BAUDRATE       (BAUDRATE)
    ) peripheral_uart_i1 (
        .clk_i      (clk),
        .rst_ni     (!reset),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wmask  (mem_wmask),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (uart1_rdata),
        .mem_rstrb  (mem_rstrb),
        .mem_done   (uart1_done),
        .select     (uart1_select),
        
        .uart_rx    (uart1_rx),
        .uart_tx    (uart1_tx)
    );

    // GPIO0 Peripheral
    
    logic [31:0] gpio0_rdata;
    logic gpio0_done; // Not used
    logic gpio0_select;
    
    logic gpio0_select_del;
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            gpio0_select_del <= 1'b0;
        end else begin
            gpio0_select_del <= gpio0_select;
        end
    end
    
    peripheral_gpio #(
        .ADDRESS_BASE   (GPIO0_BASE_ADDRESS)
    ) peripheral_gpio_i (
        .clk_i      (clk),
        .rst_ni     (!reset),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_wmask  (mem_wmask),
        .mem_wstrb  (mem_wstrb),
        .mem_rdata  (gpio0_rdata),
        .mem_rstrb  (mem_rstrb),
        .mem_done   (gpio0_done),
        .select     (gpio0_select),
        
        .gpio_in    (gpio0_in),
        .gpio_out   (gpio0_out),
        .gpio_oe    (gpio0_oe)
    );

    // SPI Flash
    
    logic [DATA_WIDTH-1:0] spi_flash_rdata;
    logic spi_flash_done;
    logic spi_flash_initialized;

    spi_flash spi_flash_inst (
        .clk,
        .reset,

        .addr_in    (mem_addr[23:0]),      // address of word
        .data_out   (spi_flash_rdata),              // received word
        .strobe     (soc_spi_flash_sel && mem_rstrb),    // start transmission
        .done       (spi_flash_done),               // pulse, transmission done
        .initialized(spi_flash_initialized),        // initial cmds sent

        // SPI signals
        .sck,
        .sdo,
        .sdi,
        .cs
    );

endmodule
