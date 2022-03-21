ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all:
	@echo 'dummy'

.PHONY: tests
tests:
	@make -s -C tests ROOT_DIR=$(ROOT_DIR)

#.PHONY: dump_firmware_verilog
#dump_firmware_verilog:
#	@riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 <ELF> <OUTFILE_NAME>
