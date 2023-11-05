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

ENV_PDK_ROOT = os.getenv("PDK_ROOT")

@cocotb.test()
async def simple_test(dut):
    """ Simple test for """

    # Start the clock
    c = Clock(dut.clk, 25, 'ns')
    await cocotb.start(c.start())

    # Reset values
    dut.trng_en.value = 0
    dut.vdd.value = 1
    dut.vss.value = 0
    
    # Wait for 100 clock cycles
    for i in range(100):
        await RisingEdge(dut.clk)

    dut.trng_en.value = 1
    
    # Wait for 5000 clock cycles
    for i in range(5000):
        await RisingEdge(dut.clk)

        dut._log.info(f"trng_out: {dut.trng_out.value}")
    
    dut._log.info("Simulation done")

def test_runner():

    sim = "icarus" #"verilator"
    proj_path = Path(__file__).resolve().parent

    verilog_sources = [
	    proj_path / "trng_wrapper.v",
	    proj_path / "../../gl/trng.v",
	    proj_path / "dummy_cells.v"
    ]
    defines = [
        ("COCOTB", 1)
    ]
    hdl_toplevel = "trng_wrapper"
    build_args=[]#["-Wno-fatal", "--timing", "--trace-fst", "--trace-structs"]

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
        test_module="tb_trng,"
    )

if __name__ == "__main__":
    test_runner()
