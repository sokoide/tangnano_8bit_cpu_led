# IPCORE_PATH=/Applications/GowinEDA.app/Contents/Resources/Gowin_EDA/IDE
# $(IPCORE_PATH)/simlib/gw2a/prim_sim.v
SRC=src/top.sv src/cpu.sv src/gowin_sp/gowin_sp.v impl/pnr/8bit_bsram.vo
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

.PHONY: testbin generate clean testrun wave synthesize download

synthesize: $(SRC)
	$(GWSH) proj.tcl

$(FS): synthesize

# operation_index
# /Applications/GowinEDA.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli -h
#  --operation_index <int>, --run <int>, -r <int>
# 0: Read Device Codes;
# 1: Reprogram;
# 2: SRAM Program;
# 3: SRAM Read;
# 4: SRAM Program and Verify;
# 5: embFlash Erase,Program;
# ...
download: $(FS)
	# SRAM
	$(PRG) --device $(DEVICE) --fsFile $(FS) --operation_index 2

wave:
	gtkwave ./waveform.vcd

clean:
	rm -rf obj_dir waveform.*