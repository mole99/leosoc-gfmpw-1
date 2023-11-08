# leosoc-gfmpw-1

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

A simple dual-core SoC with true random number generators as payload.

- Two RV32I cores running in parallel
  - 32 word direct-mapped instruction cache for each core
- 4kB of shared memory
- SPI flash controller
- 2 UARTs
- 1 GPIO controller (24 I/Os)
- 15 different TRNGs

It uses the foundry provided 512x8 SRAM macros.

### True Random Number Generators

| #ring oscillators | #inverters per oscillator | macro width and height |
|-------------------|---------------------------|------------------------|
| 1                 | 3                         | 70                     |
| 1                 | 5                         | 70                     |
| 1                 | 7                         | 70                     |
| 2                 | 3                         | 75                     |
| 2                 | 5                         | 75                     |
| 2                 | 7                         | 75                     |
| 8                 | 3                         | 80                     |
| 8                 | 5                         | 85                     |
| 8                 | 7                         | 90                     |
| 32                | 3                         | 130                    |
| 32                | 5                         | 135                    |
| 32                | 7                         | 140                    |
| 128               | 3                         | 230                    |
| 128               | 5                         | 240                    |
| 128               | 7                         | 250                    |

### Memory Map

- `0x00000000` RAM
- `0x02000000` Flash
- `0x03000000` UART0
- `0x04000000` UART1
- `0x05000000` GPIO0
- `0x06000000` TRNG0
- `0x0F000000` Blinky


