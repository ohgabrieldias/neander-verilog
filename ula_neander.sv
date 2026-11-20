// ============================================================================
// ULA do processador Neander - 8 bits, puramente combinacional
// Atividade Pratica 6 (Trabalho Final) - Introducao a Linguagem de Descricao de Hardware
//
// Entradas : AC  [7:0]  - acumulador (operando X)
//            RDM [7:0]  - registrador de dados da memoria (operando Y)
//            sel_ula [2:0]
// Saidas   : resultado [7:0] (S)
//            N = S[7]       (negativo, complemento de 2)
//            Z = (S == 0)   (zero)
//
// Codificacao de sel_ula (ordem do enunciado):
//   000 PASS : S = RDM        (usada pela instrucao LDA)
//   001 ADD  : S = AC + RDM   (carry descartado; o Neander so tem N e Z)
//   010 OR   : S = AC | RDM
//   011 AND  : S = AC & RDM
//   100 NOT  : S = ~AC
//   101..110 : S = 0          (codigos nao utilizados)
//   111 SUB  : S = AC - RDM   (complemento de 2; instrucao SUB acrescentada)
// ============================================================================

`timescale 1ns/1ps

module ula_neander (
    input  wire [7:0] AC,
    input  wire [7:0] RDM,
    input  wire [2:0] sel_ula,
    output reg  [7:0] resultado,
    output wire       N,
    output wire       Z
);

    localparam SEL_PASS = 3'b000;
    localparam SEL_ADD  = 3'b001;
    localparam SEL_OR   = 3'b010;
    localparam SEL_AND  = 3'b011;
    localparam SEL_NOT  = 3'b100;
    localparam SEL_SUB  = 3'b111;

    always @(*) begin
        resultado = 8'h00;              // valor padrao: evita latch

        case (sel_ula)
            SEL_PASS: resultado = RDM;
            SEL_ADD:  resultado = AC + RDM;
            SEL_OR:   resultado = AC | RDM;
            SEL_AND:  resultado = AC & RDM;
            SEL_NOT:  resultado = ~AC;
            SEL_SUB:  resultado = AC - RDM;   // == AC + ~RDM + 1 complemento de 2
            default:  resultado = 8'h00;
        endcase
    end

    // Flags calculadas a partir do resultado S
    assign N = resultado[7];
    assign Z = (resultado == 8'h00);

endmodule
