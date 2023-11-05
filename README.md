# leosoc-gfmpw-1

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

A simple SoC with true random number generators as payload.

- Two RV32I cores running in parallel
  - 32 word direct-mapped instruction cache each
- 2kB of shared memory
- Flash controller
- Two UARTs
- GPIO controller

It uses the foundry provided 512x8 SRAM macros.

### True Random Number Generators

TODO

### Memory Map

- 0x00000000 RAM
- 0x02000000 Flash
- 0x03000000 UART0
- 0x04000000 UART1
- 0x05000000 GPIO
- 0x0F000000 Blinky


