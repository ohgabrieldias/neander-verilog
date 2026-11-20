# Cria o projeto do Neander no Vivado, sintetiza e implementa.
#
#   vivado -mode batch -source vivado.tcl              (na pasta da pratica)
#   vivado -mode batch -source vivado.tcl -tclargs sub_mat
#
# O projeto fica em vivado/ (fora do espelho com o servidor) e e recriado a
# cada execucao (-force); fontes e restricoes ficam na pasta da pratica.
# Para abrir na interface: vivado vivado/neander.xpr
#
# Placa: Digilent Nexys A7-100T (Artix-7 xc7a100tcsg324-1).

set PART  xc7a100tcsg324-1
set DIR   [file normalize [file dirname [info script]]]

# Programa carregado na BRAM. Vai para dentro da netlist na sintese: a
# simulacao com atraso de outro programa exige reimplementar com ele.
set NOME  [expr {[llength $argv] > 0 ? [lindex $argv 0] : "mult"}]
set PROG  $DIR/programs/$NOME.hex

create_project neander $DIR/vivado -part $PART -force

# Projeto (sem o testbench)
add_files [glob $DIR/*.sv]
remove_files [glob $DIR/tb.sv]
set_property top neander [get_filesets sources_1]
set_property generic "ARQ=\"$PROG\"" [get_filesets sources_1]
add_files -fileset constrs_1 $DIR/neander.xdc

# Testbench (simulacao no xsim ate o fim)
add_files -fileset sim_1 $DIR/tb.sv
set_property top tb [get_filesets sim_1]
set_property verilog_define "PROG=\"$PROG\"" [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

# Sintese e implementacao (sem bitstream: pinos da placa nao atribuidos)
launch_runs impl_1 -jobs 4
wait_on_run impl_1
open_run impl_1

file mkdir $DIR/vivado/relatorios
report_utilization     -file $DIR/vivado/relatorios/utilizacao.rpt
report_ram_utilization -file $DIR/vivado/relatorios/ram.rpt
report_timing_summary  -max_paths 3 -file $DIR/vivado/relatorios/timing.rpt
