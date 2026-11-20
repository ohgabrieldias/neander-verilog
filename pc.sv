`timescale 1ns/10ps

// Contador de programa. A carga (desvios JMP/JN/JZ) tem prioridade sobre o
// incremento; o controle nunca ativa os dois no mesmo ciclo.

module pc #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst,
    input wire carga,
    input wire incPC,
    input wire [WIDTH -1:0] d,
    output reg [WIDTH -1:0] q
);
    
    always_ff @(posedge clk) begin
        if(rst)
            q <= 0;
        else if(carga)
            q <= d;
        else if(incPC)
            q <= q + 1;
    end
endmodule