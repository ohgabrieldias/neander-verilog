`timescale 1ns/10ps

// Topo do processador Neander (com SUB): controle + bloco operacional + memoria.
// As saidas existem para observar o processador pelas portas, o que permite
// usar o mesmo testbench na simulacao com atraso, em que os sinais internos
// deixam de existir com os nomes originais. Sem saidas, a sintese removeria
// toda a logica.

module neander #(
    parameter ARQ = "programs/programa.hex"   // programa carregado na memoria
)(
    input  wire       clk,
    input  wire       rst,
    output wire [7:0] ac_out,   // valor do acumulador
    output wire [7:0] pc_out,   // onde o programa esta
    output wire       halt,     // 1 quando executar HLT
    // barramento da memoria visto de fora (permite verificar pelas portas)
    output wire [7:0] mem_end_out,     // endereco acessado (REM)
    output wire [7:0] mem_escrita_out, // dado a gravar (AC)
    output wire       mem_we_out,      // 1 quando grava (STA)
    output wire       nova_instr       // 1 por ciclo a cada instrucao buscada (carga do RI)
);


// Sinais de controle
wire       cargaAC, cargaRDM, cargaREM, cargaNZ, cargaPC, cargaRI;
wire       incPC, sel, escreveMem;
wire [2:0] selULA;

// Datapath -> controle
wire [3:0] opcode;
wire [1:0] flags;

controle fsm(
    //entradas
    .clk(clk),.rst(rst),
    .opcode(opcode),
    .flags(flags),

    //saidas
    .cargaAC(cargaAC),
    .cargaNZ(cargaNZ),
    .cargaPC(cargaPC),
    .cargaRDM(cargaRDM),
    .cargaREM(cargaREM),
    .cargaRI(cargaRI),

    .incPC(incPC),
    .sel(sel),
    .selULA(selULA),
    .escreveMem(escreveMem),
    .halt(halt)

   
);

// Barramento da memoria
wire [7:0] mem_end, mem_escrita;
wire [7:0] mem_dado;


datapath #(
    .WIDTH(8)
) dp (
    .clk        (clk),
    .rst        (rst),
    // controle -> datapath
    .cargaAC    (cargaAC),
    .cargaRDM   (cargaRDM),
    .cargaREM   (cargaREM),
    .cargaNZ    (cargaNZ),
    .cargaPC    (cargaPC),
    .cargaRI    (cargaRI),
    .incPC      (incPC),
    .sel        (sel),
    .selULA     (selULA),
    // memoria <-> datapath
    .mem_dado   (mem_dado),     // memoria -> RDM
    .mem_end    (mem_end),      // REM -> memoria
    .mem_escrita(mem_escrita),  // AC -> memoria
    // datapath -> controle
    .opcode     (opcode),
    .flags      (flags),
    // observacao
    .ac_saida   (ac_out),
    .pc_saida   (pc_out)
);

ram_sync_read #(
    .AW(8),                 // 2^8 = 256 posicoes
    .DW(8),                 // 8 bits por posicao
    .ARQ(ARQ)               // repassa o arquivo escolhido no topo/testbench
) memo (
    .clk  (clk),
    .we   (escreveMem),     // vem do controle (1 so no STA)
    .addr (mem_end),        // vem do datapath (REM)
    .din  (mem_escrita),    // vem do datapath (AC)
    .dout (mem_dado)        // vai para o datapath (RDM)
);

// Barramento da memoria para fora
assign mem_end_out     = mem_end;
assign mem_escrita_out = mem_escrita;
assign mem_we_out      = escreveMem;
assign nova_instr      = cargaRI;

endmodule