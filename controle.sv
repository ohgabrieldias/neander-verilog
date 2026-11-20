`timescale 1ns/10ps

// Unidade de controle do Neander: FSM de Moore (saidas dependem so do estado).
// A memoria tem leitura sincrona (BRAM): o dado so aparece um ciclo depois do
// endereco, por isso todo acesso gasta tres estados (REM, espera, RDM).
// SUB usa o codigo 0111, o mesmo do Ahmes, para montar os programas no Hidra.

module controle(
    input wire clk,
    input wire rst,

    input wire [3:0] opcode,
    input wire [1:0] flags,

    output reg cargaAC,
    output reg  cargaRDM,
    output reg  cargaREM,
    output reg  cargaNZ,
    output reg  cargaPC,
    output reg  cargaRI,

    output reg  incPC, sel, escreveMem,
    output reg [2:0] selULA,
    output reg  halt
);

localparam NOP = 4'b0000;
localparam STA = 4'b0001;
localparam LDA = 4'b0010;
localparam ADD = 4'b0011;
localparam OR = 4'b0100;
localparam AND = 4'b0101;
localparam SUB = 4'b0111;
localparam NOT = 4'b0110;
localparam JMP = 4'b1000;
localparam JN = 4'b1001;
localparam JZ = 4'b1010;
localparam HLT = 4'b1111;


//ESTADOS
// busca da instrucao (igual pra todas)
localparam B0 = 4'b0000;        //REM <- PC, endereco da instrucao
localparam B1 = 4'b0001;        //espera a memoria ler e ja incrementa o PC
localparam B2 = 4'b0010;        //RDM <- memoria (chegou a instrucao)
localparam B3 = 4'b0011;        //RI <- RDM, guarda a instrucao

localparam DEC = 4'b0100;       //olha o opcode e decide pra onde ir

// instrucoes com endereco (LDA, ADD, SUB, OR, AND, STA, JMP, JN, JZ)
localparam E0 = 4'b0101;        //cargaREM pra pegar o end (REM <- PC)
localparam E1 = 4'b0110;        //incrementa pc e espera
localparam E2 = 4'b0111;        //RDM <- memoria, agora o RDM tem o end do operando
localparam E3 = 4'b1000;        //REM <- RDM pra ler o operando; nos desvios PC <- RDM e acabou
localparam E4 = 4'b1001;        //espera a memoria ler o operando; no STA grava o AC aqui
localparam E5 = 4'b1010;        //RDM <- memoria, chegou o operando
localparam E6 = 4'b1011;        //AC <- ULA(AC, RDM) e atualiza N e Z

// casos especiais
localparam PARADO = 4'b1100;    //HLT, fica preso aqui com halt = 1
localparam EXEC_NOT = 4'b1101;  //AC <- NOT AC, nao precisa de memoria
localparam JN_JZ = 4'b1110;     //desvio nao tomado: so pula o byte do end (PC + 1)

reg [3:0] estado, prox_estado;

always_ff @(posedge clk) begin
    if(rst) estado <= B0;
    else estado <= prox_estado;
end


always_comb begin : ProxEstado
    prox_estado = estado;           //evita latch

    case(estado)
        B0: prox_estado = B1;
        B1: prox_estado = B2;
        B2: prox_estado = B3;
        B3: prox_estado = DEC;
        DEC: 
            case (opcode)
                NOP:     prox_estado = B0;
                NOT:     prox_estado = EXEC_NOT;
                HLT:     prox_estado = PARADO;
                JN:      prox_estado = flags[1] ? E0 : JN_JZ;   // N=1: desvia
                JZ:      prox_estado = flags[0] ? E0 : JN_JZ;   // Z=1: desvia
                default: prox_estado = E0;    // LDA, ADD, SUB, OR, AND, STA, JMP
            endcase
        E0: prox_estado = E1;
        E1: prox_estado = E2;
        E2: prox_estado = E3;
        E3: begin
            case(opcode)
                JMP, JN, JZ: prox_estado = B0;
                default:     prox_estado = E4;
            endcase
        end

        E4: begin
            case(opcode)
                STA: prox_estado = B0;
                default: prox_estado = E5;
            endcase
        end

        E5: prox_estado = E6;
        E6: prox_estado = B0;

        EXEC_NOT: prox_estado = B0;
        JN_JZ:    prox_estado = B0;   // desvio nao tomado
        PARADO:   prox_estado = PARADO;



    endcase
end

always_comb begin : Sinais
    cargaAC = 0;
    cargaNZ = 0;
    cargaPC = 0;
    cargaRDM = 0;
    cargaREM = 0;
    cargaRI = 0;
    incPC = 0;
    sel = 0;
    escreveMem = 0;
    selULA = 3'b000;
    halt = 0;

    case(estado)
        B0: cargaREM = 1;  // sel = 0 (PC) pelo valor padrao acima
        B1: incPC = 1;
        B2: cargaRDM = 1;
        B3: cargaRI = 1;

        E0: begin
            cargaREM = 1;
            sel = 0;
        end
        E1: incPC = 1;
        E2: cargaRDM = 1;

        E3: begin
            case(opcode)
                STA: begin
                    cargaREM = 1;
                    sel = 1;
                end
                JMP, JN, JZ: cargaPC = 1;      // PC <- RDM (endereco do desvio)
                default: begin
                    cargaREM = 1;
                    sel = 1;
                end
            endcase
        end

        E4: begin
            case(opcode)
                STA: escreveMem = 1;           // mem[REM] <- AC
                default: ;                     // espera a memoria
            endcase
        end

        E5: cargaRDM = 1;
        E6: begin
            cargaAC = 1;
            cargaNZ = 1;
            case(opcode)
                LDA: selULA = 3'b000;
                ADD: selULA = 3'b001;
                OR: selULA = 3'b010;
                AND: selULA = 3'b011;
                SUB: selULA = 3'b111;
            endcase
        end

        EXEC_NOT: begin
            cargaAC = 1;
            cargaNZ = 1;
            selULA = 3'b100;
        end

        JN_JZ:  incPC = 1;          // pula o byte de endereco
        PARADO: halt = 1;
    endcase

end
endmodule