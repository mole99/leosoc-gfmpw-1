module gf180_ram_512x8_wrapper (
	input        CLK,  // Clock
	input        CEN,  // Chip enable
	input        GWEN, // Global write enable
	input  [7:0] WEN,  // Write enable
	input  [8:0] A,    // Address
	input  [7:0] D,    // Data in
	output [7:0] Q     // Data out
);

gf180mcu_fd_ip_sram__sram512x8m8wm1 sram512x8 (
    .CLK    (CLK),
    .CEN    (CEN),
    .GWEN   (GWEN),
    .WEN    (WEN),
    .A      (A),
    .D      (D),
    .Q      (Q),
    .VDD    (),
    .VSS    ()
);

endmodule
