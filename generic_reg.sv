`timescale 1ns/10ps

// Registrador com carga: q <= d so quando carga = 1; senao mantem o valor.
// Usado para AC, REM, RDM, RI (8 bits) e para os codigos N e Z (2 bits).
// Reset sincrono.

module generic_reg #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst,
    input wire carga,
    input wire [WIDTH -1:0] d,
    output reg [WIDTH -1:0] q
);
    
    always_ff @(posedge clk) begin
        if(rst)
            q <= 0;
        else if(carga)
            q <= d;
    end
endmodule