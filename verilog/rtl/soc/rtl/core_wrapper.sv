// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none
`timescale 1ns / 1ps

module core_wrapper #(
    parameter int NUM_CORES = 1,
    parameter int RESET_ADDR = 32'h00000000,
    parameter int ADDR_WIDTH = 32,
    parameter int INSTR_CACHE = 1,
    parameter int INSTR_CACHE_SIZE = 32
) (
    input  logic clk,
    input  logic reset,

    output logic [31:0] mem_addr,   // address
    output logic [31:0] mem_wdata,  // write data
    output logic [ 3:0] mem_wmask,  // write mask
    output logic        mem_wstrb,  // write strobe
    input  logic [31:0] mem_rdata,  // read data
    output logic        mem_rstrb,  // read strobe
    input  logic        mem_done    // done
);

    logic [NUM_CORES-1:0] claim_signals;
    logic [NUM_CORES-1:0] granted_signals;

    arbiter  #(
        .NUM_PORTS(NUM_CORES)
    ) arbiter_inst (
        .clk    (clk),
        .reset  (reset),

        .claim_signals   (claim_signals),
        .granted_signals (granted_signals)
    );
    
    
    // Memory interface all cores
    logic [32 * NUM_CORES - 1:0] mem_addr_all_cores;   // address
    logic [32 * NUM_CORES - 1:0] mem_wdata_all_cores;  // write data
    logic [ 4 * NUM_CORES - 1:0] mem_wmask_all_cores;  // write mask
    logic [     NUM_CORES - 1:0] mem_wstrb_all_cores;  // write strobe
    logic [     NUM_CORES - 1:0] mem_rstrb_all_cores;  // read strobe
    
    always_comb begin
        mem_addr  = '0;
        mem_rstrb = '0;
        mem_wdata = '0;
        mem_wmask = '0;
        mem_wstrb = '0;
    
        for (int i=0; i<NUM_CORES; i++) begin
            if (granted_signals[i]) begin
                mem_addr  = mem_addr_all_cores[32*i+:32];
                mem_rstrb = mem_rstrb_all_cores[i];
                mem_wdata = mem_wdata_all_cores[32*i+:32];
                mem_wmask = mem_wmask_all_cores[4*i+:4];
                mem_wstrb = mem_wstrb_all_cores[i];
            end
        end
    end
    
    genvar gen_core;
    
    generate
    
    for (gen_core = 0; gen_core < NUM_CORES; gen_core++) begin : cpus

        // Memory interface core i
        logic [31:0] mem_addr_gen_core;   // address
        logic [31:0] mem_wdata_gen_core;  // write data
        logic [ 3:0] mem_wmask_gen_core;  // write mask
        logic        mem_wstrb_gen_core;  // write strobe
        logic        mem_rstrb_gen_core;  // read strobe

        // Instruction Port
        logic [31: 0] instr_addr_gen_core;   // address
        logic [31: 0] instr_rdata_gen_core;  // read data
        logic         instr_fetch_gen_core;  // read
        logic         instr_done_gen_core;   // done

        // Data Port
        logic [31: 0] data_addr_gen_core;   // address
        logic [31: 0] data_wdata_gen_core;  // write data
        logic [ 3: 0] data_wmask_gen_core;  // write mask
        logic [31: 0] data_rdata_gen_core;  // read data
        logic         data_rstrb_gen_core;  // read strobe
        logic         data_wstrb_gen_core;  // write strobe
        logic         data_done_gen_core;   // read busy

        // Merge instruction and data bus to memory bus
        
        if (INSTR_CACHE) begin

            direct_mapped_cache #(
                .CACHE_ENTRIES(INSTR_CACHE_SIZE),
                .ADDR_WIDTH(32)
            ) direct_mapped_cache_i (
                .clk_i      (clk),
                .rst_ni     (!reset),

                // Connected to core
                .cache_addr     (instr_addr_gen_core),
                .cache_rdata    (instr_rdata_gen_core),
                .cache_rstrb    (instr_fetch_gen_core),
                .cache_done     (instr_done_gen_core),
                
                // Connected to memory
                .mem_addr       (cache2mem_addr),
                .mem_rdata      (mem_rdata),
                .mem_rstrb      (cache2mem_rstrb),
                .mem_done       (mem_done && granted_signals[gen_core])
            );
            
            logic [31: 0] cache2mem_addr;
            logic cache2mem_rstrb;
            
            // Shared lines
            assign mem_addr_gen_core = cache2mem_rstrb ? cache2mem_addr :
                              data_rstrb_gen_core || data_wstrb_gen_core ? data_addr_gen_core :
                              '0;
            assign mem_rstrb_gen_core = cache2mem_rstrb || data_rstrb_gen_core;

        end else begin
        
            // Shared lines
            assign mem_addr_gen_core = instr_fetch_gen_core ? instr_addr_gen_core :
                              data_rstrb_gen_core || data_wstrb_gen_core ? data_addr_gen_core :
                              '0;
            assign mem_rstrb_gen_core = instr_fetch_gen_core || data_rstrb_gen_core;
        
            // Fetch
            assign instr_rdata_gen_core = mem_rdata;
            assign instr_done_gen_core = mem_done && granted_signals[gen_core];
        
        end
        
        // Load / Store
        assign mem_wdata_gen_core = data_wdata_gen_core;
        assign mem_wmask_gen_core = data_wmask_gen_core;
        assign mem_wstrb_gen_core = data_wstrb_gen_core;
        assign data_rdata_gen_core = mem_rdata;
        assign data_done_gen_core = mem_done && granted_signals[gen_core];
        
        // ====================================================================================================================
        
        
        assign mem_addr_all_cores[(32 * (gen_core+1)) - 1: 32 * gen_core] = mem_addr_gen_core;
        assign mem_rstrb_all_cores[gen_core] = mem_rstrb_gen_core;
        assign mem_wdata_all_cores[(32 * (gen_core+1)) - 1: 32 * gen_core] = mem_wdata_gen_core;
        assign mem_wmask_all_cores[(4  * (gen_core+1)) - 1: 4 *  gen_core] = mem_wmask_gen_core;
        assign mem_wstrb_all_cores[gen_core] = mem_wstrb_gen_core;
        
        leorv32 #(
            .RESET_ADDR(RESET_ADDR),
            .ADDR_WIDTH(ADDR_WIDTH),
            .MHARTID(gen_core)
        ) leorv32_inst (
            .clk(clk),
            .reset(reset),

            // Instruction Port
            .instr_addr     (instr_addr_gen_core),   // address
            .instr_rdata    (instr_rdata_gen_core),  // read data
            .instr_fetch    (instr_fetch_gen_core),  // read
            .instr_done     (instr_done_gen_core),   // done

            // Data Port
            .data_addr      (data_addr_gen_core),   // address
            .data_wdata     (data_wdata_gen_core),  // write data
            .data_wmask     (data_wmask_gen_core),  // write mask
            .data_rdata     (data_rdata_gen_core),  // read data
            .data_rstrb     (data_rstrb_gen_core),  // read strobe
            .data_wstrb     (data_wstrb_gen_core),  // write strobe
            .data_done      (data_done_gen_core),   // read busy

            .mhartid_0(1'b0)
        );

        assign claim_signals[gen_core] = mem_rstrb_gen_core || mem_wstrb_gen_core;
    end
    
    endgenerate

endmodule
