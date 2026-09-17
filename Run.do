#create Work Folder
vlib work

#Compile files with names
vlog DSP.v REG_pipe.v DSP_tb.v

#simulate The TB file with module Name
vsim -voptargs=+acc work.DSP_tb

#add objects name to wave Window
#add wave -position insertpoint \sim:/tb/dut/*
add wave *
run -all
wave zoom full
