TB_CC               := iverilog
PYTHON              := python3
ifdef TC_TRIPLE
TOOLCHAIN_PREFIX    := $(TC_TRIPLE)
else
TOOLCHAIN_PREFIX    := riscv64-unknown-elf
endif
CC                  := $(TOOLCHAIN_PREFIX)-gcc
AS                  := $(TOOLCHAIN_PREFIX)-as
OBJCOPY             := $(TOOLCHAIN_PREFIX)-objcopy
OBJDUMP             := $(TOOLCHAIN_PREFIX)-objdump
OUTPUT              := build
FLAGS               := -Wall
FLAGS               += -Ihdl
FLAGS               += -DSIM
ifdef VCD
FLAGS               += -DDUMP_VCD
endif # VCD
ROOT_DIR            := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ifdef DOCKER
DOCKER_CMD          := docker run -v $(ROOT_DIR):/src -w /src riscv-gnu-toolchain
else
DOCKER_CMD          :=
endif # DOCKER
LINE                := ================================================================================================

vpath %.v           tests
vpath %.py          scripts

HDL_SOURCES         := $(shell find hdl -type f -name "*.v")
VERILATOR_TB		:= $(shell find tests/verilator -type f -name "*.cpp")
TB_SOURCES          := $(shell find tests -type f -name "*.v" -exec basename {} \;)
TB_OUTPUTS          := $(TB_SOURCES:%.v=$(OUTPUT)/%)
TEST_PY             := $(shell find scripts -type f -name "*.mem.py" -exec basename {} \;)
TEST_MEMH           := $(TEST_PY:%.mem.py=$(OUTPUT)/%.mem)
TEST_PY_ASM         := $(shell find scripts -type f -name "*.asm.py" -exec basename {} \;)
TEST_ASM            := $(TEST_PY_ASM:%.asm.py=$(OUTPUT)/%.s)
TEST_ASM_ELF        := $(TEST_ASM:%.s=%.elf)
TEST_ASM_MEMH       := $(TEST_ASM_ELF:%.elf=%.mem)

# Testbench mem
.SECONDARY:
$(OUTPUT)/%.mem: %.mem.py
	$(PYTHON) $<

# Testbench ASM
.SECONDARY:
$(OUTPUT)/%.s: %.asm.py
	$(PYTHON) $<

# Testbench ELF
.SECONDARY:
$(OUTPUT)/%.elf: $(OUTPUT)/%.s
	$(DOCKER_CMD) $(AS) -o $@ $<

# Testbench Objcopy
.SECONDARY:
$(OUTPUT)/%.mem: $(OUTPUT)/%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

# Testbench iverilog
$(OUTPUT)/%: tests/%.v $(TEST_MEMH) $(TEST_ASM_MEMH)
	$(TB_CC) $(FLAGS) -o $@ $<

obj_dir/%.cpp: $(VERILATOR_TB)
	verilator -Wall -Ihdl --trace --exe tests/verilator/cpu_test.cpp --top-module boredcore -cc $(HDL_SOURCES)

# Main build is simulating CPU with Verilator
.PHONY: all
all: obj_dir/Vboredcore.cpp
	$(MAKE) -C obj_dir -f Vboredcore.mk Vboredcore
	@printf "\nDone.\n"

# Unit testing (i.e. sub-module testing)
.PHONY: unit
unit: build-dir $(TB_OUTPUTS)
	@printf "\nAll done building unit-tests.\n"

.PHONY: build-dir
build-dir:
	@mkdir -p $(OUTPUT)

.PHONY: clean
clean:
	rm -rf $(OUTPUT) 2> /dev/null || true
	rm -rf obj_dir 2> /dev/null || true

.PHONY: soc-unit
soc-unit:
	$(MAKE) unit -C ./soc
