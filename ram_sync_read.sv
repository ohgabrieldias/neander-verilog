`timescale 1ns/10ps

// Memoria com escrita e leitura sincronas: o Vivado infere uma BRAM.
// A saida e registrada, entao o dado lido aparece um ciclo depois do endereco.
// Durante uma escrita a saida mantem o valor anterior (modo no-change da BRAM).
// Conteudo inicial: arquivo .hex escolhido por ARQ (o .coe equivalente, para o
// Block Memory Generator, e gerado por programs/hex2coe.py).

module ram_sync_read #(
    parameter AW = 4,   // 2^4 = 16 posicoes
    parameter DW = 8,    // 8 bits por posicao
    parameter ARQ = "programs/programa.hex"
)(
    input  wire          clk,
    input  wire          we,
    input  wire [AW-1:0] addr,
    input  wire [DW-1:0] din,
    output reg  [DW-1:0] dout
);

    // Memoria: 2^AW palavras de DW bits
    reg [DW-1:0] mem [0:(1<<AW)-1];

    // Inicializacao
    initial begin
        $readmemh(ARQ, mem);
    end

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;     // Escrita sincrona
        else
            dout <= mem[addr];    // Leitura sincrona
    end

endmodule
