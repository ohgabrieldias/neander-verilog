# Neander em Verilog

Processador Neander (Weber, *Fundamentos de Arquitetura de Computadores*) descrito
em SystemVerilog, com a instrução **SUB** acrescentada e memória em BRAM.
Trabalho final da disciplina *Introdução à Linguagem de Descrição de Hardware*
(CI-Inovador, 2026).

Fluxo FPGA no Vivado para a **Nexys A7-100T** (Artix-7 `xc7a100tcsg324-1`):
síntese, implementação e simulação com atraso (SDF).

## Arquitetura

| Arquivo | Conteúdo |
|---|---|
| `neander.sv` | topo: controle + bloco operacional + memória; expõe AC, PC, `halt` e o barramento de escrita da memória |
| `controle.sv` | FSM de Moore (busca, decodificação, execução) |
| `datapath.sv` | registradores AC, PC, REM, RDM, RI, N/Z, mux de endereço e ULA |
| `ula_neander.sv` | ULA combinacional: PASS, ADD, OR, AND, NOT, SUB |
| `generic_reg.sv`, `pc.sv` | registrador com carga e contador de programa |
| `ram_sync_read.sv` | memória 256 × 8, escrita e leitura síncronas (inferida como BRAM) |
| `tb.sv` | testbench: só clock (50 MHz) e reset, observa apenas as portas |
| `neander.xdc` | relógio de 20 ns e exclusão da BRAM da otimização de consumo |
| `vivado.tcl` | cria o projeto, sintetiza e implementa |

Instruções: NOP, STA, LDA, ADD, OR, AND, NOT, **SUB (`0111`)**, JMP, JN, JZ, HLT.
O código do SUB é o mesmo do computador Ahmes, então os programas são montados
no [Hidra](https://github.com/petcomputacaoufrgs/hidracpp) escolhendo a máquina Ahmes.

A leitura síncrona da BRAM entrega o dado um ciclo depois do endereço; por isso
cada acesso à memória gasta três estados na FSM. Ciclos por instrução:
LDA/ADD/SUB/OR/AND 12, STA 10, JMP 9, NOT 6, NOP e HLT 5.

## Programas (`programs/`)

| Programa | Fonte Hidra | Binário Hidra | `$readmemh` | BRAM (`.coe`) |
|---|---|---|---|---|
| Multiplicação por somas sucessivas | `mult.ahd` | `mult.mem` | `mult.hex` | `mult.coe` |
| Subtração de matrizes 3×3 | `sub_mat.ahd` | `sub_mat.mem` | `sub_mat.hex` | `sub_mat.coe` |

`programa.hex` é o exemplo do livro (soma de três posições).
`hex2coe.py` gera o `.coe` a partir do `.hex` ou do `.mem` exportado pelo Hidra:

```sh
python3 programs/hex2coe.py programs/sub_mat.mem
```

## Simulação sem atraso (Icarus Verilog)

```sh
iverilog -g2012 -o neander.vvp *.sv && vvp neander.vvp                    # multiplicação
iverilog -g2012 -DPROG='"programs/sub_mat.hex"' -o neander.vvp *.sv && vvp neander.vvp
```

O testbench imprime cada gravação na memória (STA), o número de instruções e de
ciclos. `estados.txt` é um filtro do GTKWave que mostra o nome dos estados da FSM.

## Vivado

```sh
vivado -mode batch -source vivado.tcl                  # BRAM com a multiplicação
vivado -mode batch -source vivado.tcl -tclargs sub_mat # BRAM com a subtração
```

O projeto é criado em `vivado/` e os relatórios em `vivado/relatorios/`. O
conteúdo da BRAM entra na netlist na síntese: para a simulação com atraso de
outro programa é preciso reimplementar com ele.

## Resultados (Nexys A7-100T, 50 MHz)

| Programa | Instruções | Ciclos | Tempo |
|---|---|---|---|
| Subtração de matrizes 3×3 | 28 | 311 | 6,22 µs |
| Multiplicação 16 × 8 | 70 | 722 | 14,44 µs |

| Recurso | Uso |
|---|---|
| LUTs | 63 |
| Flip-flops | 44 (15 do estado: o Vivado recodifica a FSM em one-hot) |
| BRAM | 1 RAMB18 |
| DSP | 0 |
| WNS / WHS a 50 MHz | +14,170 / +0,167 ns (máx. ≈ 171 MHz) |
