# LeoRV32

LeoRV32 is a simple RV32I RISC-V CPU written in SystemVerilog.

All SystemVerilog features used are supported by Yosys and Icarus Verilog.

# TBD

`M` and `C` support is planned

# Parameter

- `RESET_ADDR`: default = 32'h00000000
	- The address of the first instructiohn executed after reset.
- `ADDR_WIDTH`: default = 24
	- The address width for the instruction and data bus
- `MHARTID`: default = 0
	- The ID of the hart (hardware thread)

# CPU Interface

The CPU interface consists of one `clk` and `reset` (active high) signal as well as the instruction port and data port:

```Verilog
    // Instruction Port
    output [31: 0] instr_addr,   // address
    input  [31: 0] instr_rdata,  // read data
    output         instr_fetch,  // read
    input          instr_done,   // done

    // Data Port
    output [31: 0] data_addr,   // address
    output [31: 0] data_wdata,  // write data
    output [ 3: 0] data_wmask,  // write mask
    input  [31: 0] data_rdata,  // read data
    output         data_rstrb,  // read strobe
    output         data_wstrb,  // write strobe
    input          data_done,   // read busy
```

The instruction port is used to supply new instructions, the data port to access memory and peripherals.

There is also the `mhartid_0` input to dynamically change the last bit of `mhartid`.

## Combine Instruction and Data Bus

The instruction and data bus can easily be combined into one memory bus for easier integration into various SoCs.

```Verilog
    // Merge instruction and data bus to memory bus

    // Shared lines
    assign mem_addr = instr_fetch ? instr_addr :
                      data_rstrb || data_wstrb ? data_addr :
                      '0;
    assign mem_rstrb = instr_fetch || data_rstrb;
    
    // Fetch
    assign instr_rdata = mem_rdata;
    assign instr_done  = mem_done;
    
    // Load / Store
    assign mem_wdata  = data_wdata;
    assign mem_wmask  = data_wmask;
    assign mem_wstrb  = data_wstrb;
    assign data_rdata = mem_rdata;
    assign data_done  = mem_done;
```