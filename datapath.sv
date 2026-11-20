`timescale 1ns/10ps

// Bloco operacional do Neander: registradores, PC, ULA e o multiplexador de
// endereco da memoria (sel = 0: PC, busca; sel = 1: RDM, operando).
// Nao toma decisoes: obedece aos sinais de carga gerados pelo controle.
// A memoria fica fora, no topo; aqui saem endereco (REM) e dado (AC).

module datapath #(parameter WIDTH = 8)(
    input wire clk,
    input wire rst,

    input wire cargaAC,
    input wire cargaRDM,
    input wire cargaREM,
    input wire cargaNZ,
    input wire cargaPC,
    input wire cargaRI,
    input wire incPC,
    input wire sel,
    input wire [2:0] selULA,

    input wire [7:0] mem_dado,
    output [7:0] mem_end,
    output [7:0] mem_escrita,
    output [3:0] opcode,
    output [1:0] flags,
    // observacao (testbench / sintese)
    output [7:0] ac_saida,
    output [7:0] pc_saida
);

wire [WIDTH-1:0] pc_out;
wire [WIDTH-1:0] ac;
wire [WIDTH-1:0] rdm_out;
wire [WIDTH-1:0] rem_out;
wire [WIDTH-1:0] ri_out;
wire [WIDTH-1:0] ula_out;
wire [WIDTH-1:0] mux_out;
wire             ula_n, ula_z;   // flags "cruas" da ULA (mudam o tempo todo)
wire [1:0] nz;   // flags guardadas: nz[1] = N, nz[0] = Z


assign mux_out = sel? rdm_out:pc_out;
assign mem_end = rem_out;
assign mem_escrita = ac;
assign opcode = ri_out[7:4];
assign flags = nz;
assign ac_saida = ac;
assign pc_saida = pc_out;

generic_reg #(8) AC(
    .clk(clk),.rst(rst),
    .carga(cargaAC),
    .d(ula_out),
    .q(ac)
);
generic_reg #(8) REM(
    .clk(clk),.rst(rst),
    .carga(cargaREM),
    .d(mux_out),
    .q(rem_out)
);
generic_reg #(8) RDM(
    .clk(clk),.rst(rst),
    .carga(cargaRDM),
    .d(mem_dado),
    .q(rdm_out)
);  
generic_reg #(8) RI(
    .clk(clk),.rst(rst),
    .carga(cargaRI),
    .d(rdm_out),
    .q(ri_out)
);

pc #(8) PC(
    .clk(clk),.rst(rst),
    .carga(cargaPC),
    .incPC(incPC),
    .d(rdm_out),
    .q(pc_out)
);

ula_neander ULA (
    .AC(ac),
    .RDM(rdm_out),
    .sel_ula(selULA),
    .resultado(ula_out),
    .N(ula_n),
    .Z(ula_z)
);

generic_reg #(2) NZ (
    .clk(clk), .rst(rst),
    .carga(cargaNZ),
    .d({ula_n, ula_z}),
    .q(nz)
);



endmodule