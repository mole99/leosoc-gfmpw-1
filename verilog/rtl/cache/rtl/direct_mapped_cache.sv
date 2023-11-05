// SPDX-FileCopyrightText: © 2023 Leo Moser <https://codeberg.org/mole99>
// SPDX-License-Identifier: GPL-3.0-or-later

`default_nettype none
`timescale 1ns / 1ps

module direct_mapped_cache #(
    parameter CACHE_ENTRIES = 16,
    parameter ADDR_WIDTH = 32
) (
    input  logic clk_i,
    input  logic rst_ni,

    // Connected to core
    input  logic [31:0] cache_addr,   // address
    output logic [31:0] cache_rdata,  // read data
    input  logic        cache_rstrb,  // read strobe
    output logic        cache_done,   // done
    
    // Connected to memory
    output logic [31:0] mem_addr,   // address
    input  logic [31:0] mem_rdata,  // read data
    output logic        mem_rstrb,  // read strobe
    input  logic        mem_done    // done
);

    typedef struct packed {
        logic valid;                                        // Cache entry valid
        logic [ADDR_WIDTH-$clog2(CACHE_ENTRIES)-2-1:0] tag; // Tag
        logic [31:0] data;                                  // Data (4 bytes)
    } cache_set_t;
    
    // Cache memory
    cache_set_t cache [CACHE_ENTRIES];
    
    // Extract attributes from address
    logic [1:0]                                     cache_offset;
    logic [$clog2(CACHE_ENTRIES)-1:0]               cache_index;
    logic [ADDR_WIDTH-$clog2(CACHE_ENTRIES)-2-1:0]  cache_tag;
    
    assign cache_offset = cache_addr[1:0];
    assign cache_index  = cache_addr[$clog2(CACHE_ENTRIES)+2-1:2];
    assign cache_tag    = cache_addr[ADDR_WIDTH-1:$clog2(CACHE_ENTRIES)+2];
    
    // Currently referenced entry
    cache_set_t entry;
    assign mem_addr = cache_addr;

    logic [1:0] state;
    
    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i=0;i<CACHE_ENTRIES;i++) begin
                cache[i] <= '0;
            end
            cache_done <= 1'b0;
            cache_rdata <= '0;
            entry <= '0;
            state <= 0;
            mem_rstrb <= 1'b0;
        end else begin
            cache_done <= 1'b0;
        
            // Waiting for core
            if (state == 0 && cache_rstrb && !cache_done) begin
                entry <= cache[cache_index];
                state <= 1;
            end
            
            // Check cache
            if (state == 1) begin
                // Entry is valid and tag matches
                if (entry.valid && entry.tag == cache_tag) begin
                    // Send data to core
                    cache_rdata <= entry.data;
                    cache_done <= 1'b1;
                    
                    // Back to idle
                    state <= 0;
                // Else need to ask memory
                end else begin
                    mem_rstrb <= 1'b1;
                    state <= 2;
                end
            end
            
            // Waiting for memory
            if (state == 2 && mem_done) begin
                mem_rstrb <= 1'b0;

                // New cache entry
                cache[cache_index] <= {1'b1, cache_tag, mem_rdata};

                // Send to core
                cache_rdata <= mem_rdata;
                cache_done <= 1'b1;

                // Back to idle
                state <= 0;
            end
        end
    end

endmodule
