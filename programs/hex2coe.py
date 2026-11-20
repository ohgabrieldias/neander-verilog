"""Gera o .coe (Block Memory Generator do Vivado) a partir de um .hex do
$readmemh ou de um .mem exportado pelo Hidra (Maquina > Exportar memoria).

    python3 hex2coe.py programa.hex [saida.coe]
    python3 hex2coe.py programa.mem [saida.coe]

O .coe nao aceita comentarios nem saltos de endereco (@80): as 256 posicoes
sao escritas em ordem, e as que o .hex nao define ficam em 00.

Formato do .mem do Hidra: 4 bytes de cabecalho (0x03 + nome da maquina, ex.:
"AHM") seguidos das 256 posicoes, 2 bytes cada (valor, 0x00).
"""

import re
import sys

PROFUNDIDADE = 256


def le_hex(caminho):
    mem = [0] * PROFUNDIDADE
    end = 0
    for linha in open(caminho, encoding="utf-8"):
        linha = re.sub(r"//.*", "", linha)
        linha = re.sub(r"/\*.*?\*/", "", linha)
        for tok in linha.split():
            if tok.startswith("@"):
                end = int(tok[1:], 16)
                continue
            if end >= PROFUNDIDADE:
                sys.exit(f"[ERRO] {caminho}: endereco {end:#x} fora da memoria de {PROFUNDIDADE} posicoes")
            mem[end] = int(tok, 16)
            end += 1
    return mem


def le_mem_hidra(caminho):
    dados = open(caminho, "rb").read()
    if len(dados) != 4 + 2 * PROFUNDIDADE:
        sys.exit(f"[ERRO] {caminho}: tamanho {len(dados)}, esperado {4 + 2 * PROFUNDIDADE} (.mem do Hidra)")
    return list(dados[4::2])


def escreve_coe(mem, caminho):
    linhas = [", ".join(f"{v:02X}" for v in mem[i:i + 16]) for i in range(0, PROFUNDIDADE, 16)]
    with open(caminho, "w", encoding="utf-8") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        f.write(",\n".join(linhas) + ";\n")


if __name__ == "__main__":
    origem = sys.argv[1]
    destino = sys.argv[2] if len(sys.argv) > 2 else re.sub(r"\.(hex|mem)$", "", origem) + ".coe"
    mem = le_mem_hidra(origem) if origem.endswith(".mem") else le_hex(origem)
    escreve_coe(mem, destino)
    print(f"[INFO] {destino}")
