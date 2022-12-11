# --- BUILD ENV -------------------------------------------------------------------------------------------------------
ROOT_DIR               := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ifdef DOCKER
DOCKER_CMD             := docker exec -u user -w /src boredcore
DOCKER_RUNNING         := $(shell docker ps -a -q -f name=boredcore)
else
DOCKER_CMD             :=
endif
GTEST_BASEDIR          ?= /usr/local/lib

OUT_DIR                := build
RTL_SRCS               := $(shell find rtl -type f -name "*.v")

# Find Python Interpreter
PYTHON:=$(shell command -v python3 2> /dev/null)
ifeq (, $(PYTHON))
PYTHON:=$(shell command -v python 2> /dev/null)
ifeq (, $(PYTHON))
$(error "Cannot find either 'python3' or 'python' in $$PATH")
endif
endif

# --- RISCV TOOLCHAIN -------------------------------------------------------------------------------------------------
ifdef TC_TRIPLE
TOOLCHAIN_PREFIX       := $(TC_TRIPLE)
else
TOOLCHAIN_PREFIX       := riscv64-unknown-elf
endif
RISCV_CC               := $(TOOLCHAIN_PREFIX)-gcc
RISCV_AS               := $(TOOLCHAIN_PREFIX)-as
RISCV_OBJCOPY          := $(TOOLCHAIN_PREFIX)-objcopy
RISCV_OBJDUMP          := $(TOOLCHAIN_PREFIX)-objdump

RISCV_CC_FLAGS         := -march=rv32i
RISCV_CC_FLAGS         += -mabi=ilp32
RISCV_CC_FLAGS         += -ffunction-sections
RISCV_CC_FLAGS         += -Wl,--section-start=.text=0x0

RISCV_AS_FLAGS         := -march=rv32i
RISCV_AS_FLAGS         += -mabi=ilp32

# --- IVERILOG --------------------------------------------------------------------------------------------------------
ICARUS_FLAGS           := -Wall
ICARUS_FLAGS           += -Irtl
ICARUS_FLAGS           += -Itests/unit

# --- SIMULATOR (VERILATOR) -------------------------------------------------------------------------------------------
VERILATOR_VER          := $(shell verilator --version | awk '{print $$2}' | sed 's/\.//')

SIM_CFLAGS             := -g
SIM_CFLAGS             += -I$(ROOT_DIR)/sim/verilator
SIM_CFLAGS             += -I$(ROOT_DIR)/external/miniargparse
SIM_CFLAGS             += -DVERILATOR_VER=$(VERILATOR_VER)

SIM_FLAGS              := -Wall
SIM_FLAGS              += -Irtl
SIM_FLAGS              += --trace
SIM_FLAGS              += -CFLAGS "$(SIM_CFLAGS)"
SIM_FLAGS              += --x-assign unique
SIM_FLAGS              += --x-initial unique
SIM_FLAGS              += --top-module boredcore
SIM_FLAGS              += --exe

VERILATOR_SIM_SRCS     := $(shell find $(ROOT_DIR)/sim/verilator -type f -name "*.cc" ! -name "main.cc")

# --- TEST SOURCES ----------------------------------------------------------------------------------------------------
CPU_TEST_SRCS          := $(shell find $(ROOT_DIR)/tests/cpu -type f -name "*.cc")
CPU_ASM_TESTS          := $(shell find tests/cpu/functional -type f -name "*.s" -exec basename {} \;)
CPU_C_TESTS            := $(shell find tests/cpu/algorithms -type f -name "*.c" -exec basename {} \;)
CPU_PY_TESTS           := $(shell find scripts -type f -name "cpu_*.asm.py" -exec basename {} \;)
CPU_ASM_TESTS          += $(CPU_PY_TESTS:%.asm.py=%.s)
CPU_TEST_ELF           := $(CPU_PY_ASM_TESTS:%.s=%.elf)
CPU_TEST_HEX           := $(CPU_TEST_ELF:%.elf=%.hex)
CPU_TEST_HEX           += $(CPU_ASM_TESTS:%.s=$(OUT_DIR)/tests/%.hex)
CPU_TEST_HEX           += $(CPU_C_TESTS:%.c=$(OUT_DIR)/tests/%.hex)
CPU_TEST_INC           := $(CPU_TEST_HEX:%.hex=%.inc)

CPU_TEST_CFLAGS        := -g
CPU_TEST_CFLAGS        += -I$(ROOT_DIR)/sim/verilator
CPU_TEST_CFLAGS        += -DVERILATOR_VER=$(VERILATOR_VER)

CPU_TEST_FLAGS         := -Wall
CPU_TEST_FLAGS         += -Irtl
CPU_TEST_FLAGS         += --trace
CPU_TEST_FLAGS         += -CFLAGS "$(CPU_TEST_CFLAGS)"
CPU_TEST_FLAGS         += -LDFLAGS "$(GTEST_BASEDIR)/libgtest.a -lpthread"
CPU_TEST_FLAGS         += --x-assign unique
CPU_TEST_FLAGS         += --x-initial unique
CPU_TEST_FLAGS         += --top-module boredcore
CPU_TEST_FLAGS         += --exe

SUB_SRCS               := $(shell find tests/unit -type f -name "*.v")

# --- SOC SOURCES -----------------------------------------------------------------------------------------------------
BOREDSOC_SRC           := boredsoc/firmware.s
BOREDSOC_ELF           := $(BOREDSOC_SRC:%.s=%.elf)
BOREDSOC_FIRMWARE      := $(BOREDSOC_ELF:%.elf=%.mem)
BOREDSOC_COREGEN       := boredsoc/core_generated.v

# --- PHONY MAKE RECIPES ----------------------------------------------------------------------------------------------
.PHONY: all
all: submodules sim tests soc

# Build tests
.PHONY: tests
tests: VERILATOR_SIM_SRCS+=$(CPU_TEST_SRCS)
tests: $(CPU_TEST_INC) $(CPU_TEST_HEX) $(OUT_DIR)/tests/Vboredcore.cpp
tests: $(OUT_DIR)/Unit_tests
	@$(MAKE) -C $(OUT_DIR)/tests -f Vboredcore.mk

# Build Verilated simulator
.PHONY: sim
sim: VERILATOR_SIM_SRCS+=$(ROOT_DIR)/sim/verilator/main.cc
sim: $(OUT_DIR)/sim/Vboredcore.cpp
sim:
	@$(MAKE) -C $(OUT_DIR)/sim -f Vboredcore.mk

# Build boredsoc firmware
.PHONY: soc
soc: $(BOREDSOC_COREGEN) $(BOREDSOC_ELF) $(BOREDSOC_FIRMWARE)

# Create the docker container (if needed) and start
.PHONY: docker
docker:
ifeq ($(DOCKER_RUNNING),)
	@docker build -t riscv-gnu-toolchain .
	@docker create -it -v $(ROOT_DIR):/src --name boredcore riscv-gnu-toolchain
endif
	@docker start boredcore

.PHONY: submodules
submodules:
	git submodule update --init --recursive

.PHONY: clean
clean:
	rm -rf $(OUT_DIR)
	rm -rf boredsoc/firmware.mem
	rm -rf boredsoc/firmware.elf
	rm -rf boredsoc/*_generated.v

# --- MAIN MAKE RECIPES -----------------------------------------------------------------------------------------------
$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(OUT_DIR)/sim:
	mkdir -p $(OUT_DIR)/sim

$(OUT_DIR)/tests:
	mkdir -p $(OUT_DIR)/tests

# Testgen
$(OUT_DIR)/tests/cpu_%.s: scripts/cpu_%.asm.py
	$(PYTHON) $< -out $(OUT_DIR)/tests

# boredsoc
boredsoc/%_generated.v: $(RTL_SRCS) $(ROOT_DIR)/rtl/types.vh
	$(PYTHON) scripts/core_gen.py -if none -pc 0x0 -isa RV32I -name CPU > $@

boredsoc/%.elf: boredsoc/%.s
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

boredsoc/%.mem: boredsoc/%.elf
	$(DOCKER_CMD) $(RISCV_OBJCOPY) -O verilog --verilog-data-width=4 $< $@
	$(PYTHON) ./scripts/byteswap_memfile.py $@

# Unit tests
$(OUT_DIR)/Unit_tests: tests/unit/main_tb.v $(SUB_SRCS) $(RTL_SRCS) | $(OUT_DIR)
	iverilog $(ICARUS_FLAGS) -o $@ $<

# Simulator (Verilator)
$(OUT_DIR)/sim/%.cpp: $(VERILATOR_SIM_SRCS) $(RTL_SRCS) $(ROOT_DIR)/rtl/types.vh | $(OUT_DIR)/sim
	verilator $(SIM_FLAGS) --Mdir $(OUT_DIR)/sim -o ../Vboredcore $(VERILATOR_SIM_SRCS) -cc $(RTL_SRCS)

# CPU/Functional tests
$(OUT_DIR)/tests/%.cpp: $(VERILATOR_SIM_SRCS) $(RTL_SRCS) $(ROOT_DIR)/rtl/types.vh
	verilator $(CPU_TEST_FLAGS) --Mdir $(OUT_DIR)/tests -o ../Vboredcore_tests $(VERILATOR_SIM_SRCS) -cc $(RTL_SRCS)

.SECONDARY:
$(OUT_DIR)/tests/cpu_%.elf: $(OUT_DIR)/tests/cpu_%.s | $(OUT_DIR)/tests
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

.SECONDARY:
$(OUT_DIR)/tests/%.elf: tests/cpu/functional/%.s | $(OUT_DIR)/tests
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

.SECONDARY:
$(OUT_DIR)/tests/%.elf: tests/cpu/algorithms/%.c
	$(DOCKER_CMD) $(RISCV_CC) $(RISCV_CC_FLAGS) -Wl,-Tscripts/boredcore.ld,-Map=$@.map -o $@ $<

$(OUT_DIR)/tests/%.hex: $(OUT_DIR)/tests/%.elf
	$(DOCKER_CMD) $(RISCV_OBJCOPY) -O binary $< $@

$(OUT_DIR)/tests/%.inc: $(OUT_DIR)/tests/%.hex
	xxd -i $< $@
