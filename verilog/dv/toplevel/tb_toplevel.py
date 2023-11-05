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

from cocotbext.uart import UartSource, UartSink

from random import randint

ENV_GL = os.getenv("GL", None)
ENV_PDK_ROOT = os.getenv("PDK_ROOT")

# Reset coroutine
async def reset_dut(rst, duration_ns):
    rst.value = 0
    await Timer(duration_ns, units="ns")
    rst.value = 1
    await Timer(duration_ns, units="ns")
    rst.value = 0
    rst._log.info("Reset complete")

@cocotb.test()
async def simple_test(dut):
    """ Simple test for """

    # Start the clock
    c = Clock(dut.clk, 25, 'ns')
    await cocotb.start(c.start())

    # Reset values
    dut.sdi.value = 0

    uart0_source = UartSource(dut.uart0_rx, baud=115200, bits=8)
    uart0_sink   = UartSink(dut.uart0_tx, baud=115200, bits=8)
    
    uart1_source = UartSource(dut.uart1_rx, baud=9600, bits=8)
    uart1_sink   = UartSink(dut.uart1_tx, baud=9600, bits=8)
    
    dut.gpio0_in.value = 42;

    if ENV_GL: # Apply power for gate-level simulation
        dut.vdd.value = 1
        dut.vss.value = 0

    # Execution will block until reset_dut has completed
    await reset_dut(dut.reset, 50)
    
    # Wait for 100 clock cycles
    for i in range(100):
        await FallingEdge(dut.clk)
    
    # Wait for 500000 clock cycles
    for i in range(500000):
        await FallingEdge(dut.clk)
        
    await uart0_source.write(b'test data!!!')
    await uart0_source.wait()
    
    data0 = uart0_sink.read_nowait()
    dut._log.info(f"uart0: {data0.decode('ascii')}")

    data1 = uart1_sink.read_nowait()
    dut._log.info(f"uart1: {data1.decode('ascii')}")
    
    dut._log.info("Simulation done")

def test_runner():

    sim = "icarus" #"verilator"
    proj_path = Path(__file__).resolve().parent

    verilog_sources = [
	    proj_path / "leosoc_wrapper.sv",
    
	    proj_path / "../../rtl/leorv32/rtl/leorv32_pkg.sv",
	    proj_path / "../../rtl/leorv32/rtl/leorv32.sv",
	    proj_path / "../../rtl/soc/rtl/leosoc.sv",
	    proj_path / "../../rtl/soc/rtl/core_wrapper.sv",
	    proj_path / "../../rtl/cache/rtl/direct_mapped_cache.sv",
	    proj_path / "../../rtl/sram/rtl/sram_gf180.sv",
	    proj_path / "../../rtl/arbiter/rtl/arbiter.sv",
	    proj_path / "../../rtl/uart/rtl/uart_rx.sv",
	    proj_path / "../../rtl/uart/rtl/uart_tx.sv",
	    proj_path / "../../rtl/uart/rtl/peripheral_uart.sv",
	    proj_path / "../../rtl/gpio/rtl/peripheral_gpio.sv",
	    proj_path / "../../rtl/spi_flash/rtl/spi_flash.sv",
	    proj_path / "../../rtl/util/rtl/synchronizer.sv",
	    
	    proj_path / "../../rtl/spi_flash/tb/spiflash.v",

	    proj_path / "../../rtl/gf180_ram_512x8_wrapper.v",
	    proj_path / "../../rtl/gf180mcu_fd_ip_sram__sram512x8m8wm1.v" # TODO from PDK
    ]
    defines = [
        ("COCOTB", 1),
        ("GF180", 1)
    ]
    hdl_toplevel = "leosoc_wrapper"
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
        test_module="tb_toplevel,"
    )

if __name__ == "__main__":
    test_runner()
