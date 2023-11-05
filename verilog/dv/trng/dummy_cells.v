// These cells are not from the PDK!
// They are only used to make sure the ring oscillator
// is connected correctly

module gf180mcu_fd_sc_mcu7t5v0__antenna (
    input I,
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fillcap_4 (
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fillcap_8 (
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fillcap_16 (
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fillcap_32 (
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fillcap_64 (
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fill_1 (
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__fill_2 (
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__endcap (
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__filltie (
    inout VDD,
    inout VSS
);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__and2_1 (
    input A1,
    input A2,
    output Z,
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
    and #1 (Z, A1, A2);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__xor2_1 (
    input A1,
    input A2,
    output Z,
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
    xor #1 (Z, A1, A2);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__dffq_1 (
    input D,
    input CLK,
    output Q,
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
    reg Q1;
    
    always @(posedge CLK) begin
        Q1 <= D;
    end

    assign #1 Q = Q1;

endmodule

module gf180mcu_fd_sc_mcu7t5v0__dlyb_1 (
    input I,
    output Z,
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
    buf #1 (Z, I);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__buf_3 (
    input I,
    output Z,
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
    buf #1 (Z, I);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkbuf_1 (
    input I,
    output Z,
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
    buf #1 (Z, I);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkbuf_16 (
    input I,
    output Z,
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
    buf #1 (Z, I);
endmodule

module gf180mcu_fd_sc_mcu7t5v0__clkinv_1 (
    input I,
    output ZN,
    inout VDD,
    inout VNW,
    inout VPW,
    inout VSS
);
    not #1 (ZN, I);
endmodule
