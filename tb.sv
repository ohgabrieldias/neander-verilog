`timescale 1ns/10ps

// Testbench do Neander: so clock e reset, e observa apenas as portas.
// Por isso serve igual na simulacao comportamental e na com atraso.

module tb();

`ifndef PROG
  `define PROG "programs/mult.hex"
`endif


reg clk, rst;
wire [7:0] ac_out,pc_out;
wire hlt;
wire [7:0] mem_end, mem_escrita;
wire mem_we, nova_instr;

neander #(.ARQ(`PROG)) neander(
    .clk(clk),.rst(rst),
    .pc_out(pc_out),
    .ac_out(ac_out),
    .halt(hlt),
    .mem_end_out(mem_end),
    .mem_escrita_out(mem_escrita),
    .mem_we_out(mem_we),
    .nova_instr(nova_instr)
);


always #10 clk = ~clk;      // periodo 20 ns = 50 MHz

// Contadores para o relatorio
integer ciclos = 0;         // ciclos de clock do reset ate o HLT
integer instrucoes = 0;     // instrucoes executadas

always @(posedge clk) begin
    if (!rst && !hlt)       ciclos = ciclos + 1;
    if (!rst && nova_instr) instrucoes = instrucoes + 1;
end

// Resultados: cada gravacao na memoria (STA)
always @(posedge clk)
    if (!rst && mem_we) $display("%t  STA: mem[%h] <- %h", $time, mem_end, mem_escrita);

initial #100000 begin $display("TIMEOUT"); $finish; end

initial begin
    $dumpfile("neander.vcd");
    $dumpvars(0, tb);


    clk = 0;
    rst = 1;

    #150 rst = 0;           // > 100 ns: reset global (GSR) da pos-implementacao

    wait(hlt == 1);
    $display("Programa: %s", `PROG);
    $display("Instrucoes: %0d | Ciclos: %0d | Tempo a 50 MHz: %0d ns", instrucoes, ciclos, ciclos*20);
    $display("AC = %h | PC = %h", ac_out, pc_out);

    $finish;

end
endmodule
