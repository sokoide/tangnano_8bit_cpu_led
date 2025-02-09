SRC=src/top.sv src/cpu.sv src/ram.sv
TEST=src/tb_cpu.sv
export BASE=8bit_bsram
PROJ=$(BASE).gprj
DEVICE=GW2AR-18C

TESTMAIN_TB=tests/tb_main.cpp
TESTBIN=Vtb_cpu
FS=$(PWD)/impl/pnr/$(BASE).fs

GWSH=/Applications/GowinEDA.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh
PRG=/Applications/GowinEDA.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli

export PATH

.PHONY: testbin generate clean run wave synthesize download

synthesize: $(SRC)
	$(GWSH) proj.tcl

$(FS): synthesize


# operation_index
# 1: SRAM
# 2: Read
# 3: Verify
# 4: Erase
# 5: Flash (internal)
# 6: Flash (external)
download: $(FS)
	# SRAM
	$(PRG) --device $(DEVICE) --fsFile $(FS) --operation_index 1
	# Flash
	#$(PRG) --device $(DEVICE) --fsFile $(FS) --operation_index 5

testbin: generate

generate: $(TESTMAIN_TB)
	verilator --trace --cc $(TEST) $(SRC) --assert --timing --exe --build $(TESTMAIN_TB) --top-module tb_cpu -DDEBUG_MODE

clean:
	rm -rf obj_dir waveform.vcd

run: testbin
	./obj_dir/$(TESTBIN)

wave: run
	gtkwave ./waveform.vcd


