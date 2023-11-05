module gf180_ram_512x8_wrapper (CEN,
    CLK,
    GWEN,
    VDD,
    VSS,
    A,
    D,
    Q,
    WEN);
 input CEN;
 input CLK;
 input GWEN;
 input VDD;
 input VSS;
 input [8:0] A;
 input [7:0] D;
 output [7:0] Q;
 input [7:0] WEN;


 gf180mcu_fd_ip_sram__sram512x8m8wm1 sram512x8 (.CEN(CEN),
    .CLK(CLK),
    .GWEN(GWEN),
    .VDD(VDD),
    .VSS(VSS),
    .A({A[8],
    A[7],
    A[6],
    A[5],
    A[4],
    A[3],
    A[2],
    A[1],
    A[0]}),
    .D({D[7],
    D[6],
    D[5],
    D[4],
    D[3],
    D[2],
    D[1],
    D[0]}),
    .Q({Q[7],
    Q[6],
    Q[5],
    Q[4],
    Q[3],
    Q[2],
    Q[1],
    Q[0]}),
    .WEN({WEN[7],
    WEN[6],
    WEN[5],
    WEN[4],
    WEN[3],
    WEN[2],
    WEN[1],
    WEN[0]}));
endmodule
