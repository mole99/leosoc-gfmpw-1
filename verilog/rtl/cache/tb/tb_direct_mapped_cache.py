# SPDX-FileCopyrightText: © 2022 Leo Moser <leo.moser@pm.me>
# SPDX-License-Identifier: GPL-3.0-or-later

import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.types import LogicArray

from random import randint

MEMORY_SIZE_BITS = 8
ITERATIONS = 1000

mem_data = [random.randint(0, 2**32-1) for _ in range(2**MEMORY_SIZE_BITS)]

# Reset coroutine
async def reset_dut(rst, duration_ns):
    rst.value = 0
    await Timer(duration_ns, units="ns")
    rst.value = 1
    rst._log.info("Reset complete")

# Memory coroutine
async def memory(dut):
    cache_misses = 0
    while 1:
        await RisingEdge(dut.mem_rstrb)
        
        assert (dut.mem_addr.value % 4 == 0)
        
        dut.mem_rdata.value = mem_data[dut.mem_addr.value>>2]
        dut.mem_done.value = 1
        
        await RisingEdge(dut.clk_i)
        dut.mem_done.value = 0
        
        cache_misses += 1
        dut._log.info(f"Cache misses: {cache_misses} / {ITERATIONS}")

@cocotb.test()
async def simple_test(dut):
    """ Simple test for """

    # Start the clock
    c = Clock(dut.clk_i, 25, 'ns')
    await cocotb.start(c.start())

    # Reset values
    dut.cache_addr.value = 0
    dut.cache_rstrb.value = 0

    # Execution will block until reset_dut has completed
    await reset_dut(dut.rst_ni, 50)
    
    # Start memory
    await cocotb.start(memory(dut))
    
    for _ in range(ITERATIONS):
    
        dut.cache_addr.value = random.randint(0, 2**(MEMORY_SIZE_BITS)-1)<<2
        dut.cache_rstrb.value = 1
        
        await RisingEdge(dut.cache_done)
        dut.cache_rstrb.value = 0
        
        assert(mem_data[dut.cache_addr.value>>2] == dut.cache_rdata.value.integer)

        # Wait for 10 clock cycles
        for i in range(10):
            await RisingEdge(dut.clk_i)
    
    dut._log.info("Simulation done")

def test_runner():

    sim = "verilator"
    proj_path = Path(__file__).resolve().parent

    verilog_sources = [
	    proj_path / "../rtl/direct_mapped_cache.sv"
    ]
    defines = []
    hdl_toplevel = "direct_mapped_cache"
    build_args=["--trace-fst", "--trace-structs"]

    runner = get_runner(sim)

    runner.build(
        verilog_sources=verilog_sources,
        defines=defines,
        build_args=build_args,
        hdl_toplevel=hdl_toplevel,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module="tb_direct_mapped_cache,"
    )

if __name__ == "__main__":
    test_runner()
