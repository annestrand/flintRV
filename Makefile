# --- BUILD ENV -------------------------------------------------------------------------------------------------------
ROOT_DIR               := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ifdef DOCKER
DOCKER_CMD             := docker exec -u user -w /src boredcore
DOCKER_RUNNING         := $(shell docker ps -a -q -f name=boredcore)
else
DOCKER_CMD             :=
endif
GTEST_BASEDIR          ?= /usr/local/lib

OUT_BASE               := build
RTL_SRCS               := $(shell find rtl -type f -name "*.v")

vpath %.v tests
vpath %.py scripts

# --- RISCV TOOLCHAIN -------------------------------------------------------------------------------------------------
ifdef TC_TRIPLECC_FLAGS
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
ICARUS_FLAGS           += -DSIM
ICARUS_FLAGS           += -DDUMP_VCD

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
TEST_PY_MEM            := $(shell find scripts -type f -name "sub_*.mem.py" -exec basename {} \;)
TEST_PY_ASM            := $(shell find scripts -type f -name "sub_*.asm.py" -exec basename {} \;)

CPU_TEST_SRCS          := $(shell find $(ROOT_DIR)/tests/cpu -type f -name "*.cc")
CPU_ASM_TESTS          := $(shell find tests/cpu/functional -type f -name "*.s" -exec basename {} \;)
CPU_C_TESTS            := $(shell find tests/cpu/algorithms -type f -name "*.c" -exec basename {} \;)
CPU_PY_TESTS           := $(shell find scripts -type f -name "cpu_*.asm.py" -exec basename {} \;)
CPU_ASM_TESTS          += $(CPU_PY_TESTS:%.asm.py=%.s)
CPU_TEST_ELF           := $(CPU_PY_ASM_TESTS:%.s=%.elf)
CPU_TEST_MEM           := $(CPU_TEST_ELF:%.elf=%.hex)
CPU_TEST_MEM           += $(CPU_ASM_TESTS:%.s=$(OUT_BASE)/tests/%.hex)
CPU_TEST_MEM           += $(CPU_C_TESTS:%.c=$(OUT_BASE)/tests/%.hex)

CPU_TEST_CFLAGS        := -g
CPU_TEST_CFLAGS        += -I$(ROOT_DIR)/sim/verilator
CPU_TEST_CFLAGS        += -DBASE_PATH='\"$(OUT_BASE)/tests\"'
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

SUB_TEST_ALL_SRCS      := $(shell find tests/sub -type f -name "*.v" -exec basename {} \;)
SUB_TEST_MEMH_SRCS     := $(TEST_PY_MEM:sub_%.mem.py=%.v)
SUB_TEST_MEMH_OBJS     := $(SUB_TEST_MEMH_SRCS:%.v=$(OUT_BASE)/tests/sub/%.mem.out)
SUB_TEST_ASM_SRCS      := $(TEST_PY_ASM:sub_%.asm.py=%.v)
SUB_TEST_ASM_OBJS      := $(SUB_TEST_ASM_SRCS:%.v=$(OUT_BASE)/tests/sub/%.asm.out)
SUB_TEST_PLAIN_SRCS    := $(filter-out $(SUB_TEST_MEMH_SRCS) $(SUB_TEST_ASM_SRCS), $(SUB_TEST_ALL_SRCS))
SUB_TEST_PLAIN_OBJS    := $(SUB_TEST_PLAIN_SRCS:%.v=$(OUT_BASE)/tests/sub/%.out)

# --- SOC SOURCES -----------------------------------------------------------------------------------------------------
BOREDSOC_SRC           := boredsoc/firmware.s
BOREDSOC_ELF           := $(BOREDSOC_SRC:%.s=%.elf)
BOREDSOC_FIRMWARE      := $(BOREDSOC_ELF:%.elf=%.mem)
BOREDSOC_COREGEN       := boredsoc/core_generated.v

# --- MAIN MAKE RECIPES -----------------------------------------------------------------------------------------------
$(OUT_BASE)/tests/sub/sub_%.mem: sub_%.mem.py
	python3 $< -out $(OUT_BASE)/tests/sub

$(OUT_BASE)/tests/sub/sub_%.s: sub_%.asm.py
	python3 $< -out $(OUT_BASE)/tests/sub

$(OUT_BASE)/tests/cpu_%.s: scripts/cpu_%.asm.py
	python3 $< -out $(OUT_BASE)/tests

boredsoc/%_generated.v:
	python3 scripts/core_gen.py -if none -pc 0x0 -isa RV32I -name CPU > $@

.SECONDARY:
$(OUT_BASE)/tests/sub/sub_%.elf: $(OUT_BASE)/tests/sub/sub_%.s
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

.SECONDARY:
$(OUT_BASE)/tests/sub/sub_%.mem: $(OUT_BASE)/tests/sub/sub_%.elf
	$(DOCKER_CMD) $(RISCV_OBJCOPY) -O verilog --verilog-data-width=4 $< $@
	python3 ./scripts/byteswap_memfile.py $@

.SECONDARY:
boredsoc/%.elf: boredsoc/%.s
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

.SECONDARY:
boredsoc/%.mem: boredsoc/%.elf
	$(DOCKER_CMD) $(RISCV_OBJCOPY) -O verilog --verilog-data-width=4 $< $@
	python3 ./scripts/byteswap_memfile.py $@

$(OUT_BASE)/tests/sub/%.out: tests/sub/%.v rtl/%.v
	iverilog $(ICARUS_FLAGS) -o $@ $<

$(OUT_BASE)/tests/sub/%.mem.out: tests/sub/%.v rtl/%.v $(OUT_BASE)/tests/sub/sub_%.mem
	iverilog $(ICARUS_FLAGS) -o $@ $<

$(OUT_BASE)/tests/sub/%.asm.out: tests/sub/%.v rtl/%.v $(OUT_BASE)/tests/sub/sub_%.mem
	iverilog $(ICARUS_FLAGS) -o $@ $<

# Sim target
$(OUT_BASE)/sim/%.cpp: $(VERILATOR_SIM_SRCS) $(RTL_SRCS)
	verilator $(SIM_FLAGS) --Mdir $(OUT_BASE)/sim $(VERILATOR_SIM_SRCS) -cc $(RTL_SRCS)

# CPU test target
$(OUT_BASE)/tests/%.cpp: $(VERILATOR_SIM_SRCS) $(RTL_SRCS)
	verilator $(CPU_TEST_FLAGS) --Mdir $(OUT_BASE)/tests $(VERILATOR_SIM_SRCS) -cc $(RTL_SRCS)

$(OUT_BASE)/tests/cpu_%.elf: $(OUT_BASE)/tests/cpu_%.s
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

$(OUT_BASE)/tests/%.elf: tests/cpu/functional/%.s
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

$(OUT_BASE)/tests/%.elf: tests/cpu/algorithms/%.c
	$(DOCKER_CMD) $(RISCV_CC) $(RISCV_CC_FLAGS) -Wl,-Tscripts/boredcore.ld,-Map=$@.map -o $@ $<

$(OUT_BASE)/tests/%.hex: $(OUT_BASE)/tests/%.elf
	$(DOCKER_CMD) $(RISCV_OBJCOPY) -O binary $< $@

# --- PHONY MAKE RECIPES ----------------------------------------------------------------------------------------------
.PHONY: all
all: submodules sim tests soc

# Build tests
.PHONY: tests
tests: VERILATOR_SIM_SRCS+=$(CPU_TEST_SRCS)
tests: build-test-dirs $(CPU_TEST_MEM) $(OUT_BASE)/tests/Vboredcore.cpp
tests: $(SUB_TEST_PLAIN_OBJS) $(SUB_TEST_ASM_OBJS) $(SUB_TEST_MEMH_OBJS)
	$(MAKE) -C $(OUT_BASE)/tests -f Vboredcore.mk

# Build Verilated simulator
.PHONY: sim
sim: VERILATOR_SIM_SRCS+=$(ROOT_DIR)/sim/verilator/main.cc
sim: build-sim-dir $(OUT_BASE)/sim/Vboredcore.cpp
sim:
	$(MAKE) -C $(OUT_BASE)/sim -f Vboredcore.mk

# Build boredsoc firmware
.PHONY: soc
soc: $(BOREDSOC_FIRMWARE) $(BOREDSOC_COREGEN)

# Create the docker container (if needed) and start
.PHONY: docker
docker:
ifeq ($(DOCKER_RUNNING),)
	@docker build -t riscv-gnu-toolchain .
	@docker create -it -v $(ROOT_DIR):/src --name boredcore riscv-gnu-toolchain
endif
	@docker start boredcore

.PHONY: build-sim-dir
build-sim-dir:
	@mkdir -p $(OUT_BASE)/sim

.PHONY: build-test-dirs
build-test-dirs:
	@mkdir -p $(OUT_BASE)/tests
	@mkdir -p $(OUT_BASE)/tests/sub

.PHONY: objdump
objdump:
	@$(DOCKER_CMD) $(RISCV_OBJDUMP) -D obj_dir/$(DUMP).elf

.PHONY: submodules
submodules:
	git submodule update --init --recursive

.PHONY: clean
clean:
	rm -rf $(OUT_BASE) 2> /dev/null || true
	rm -rf boredsoc/firmware.mem 2> /dev/null || true
	rm -rf boredsoc/firmware.elf 2> /dev/null || true
	rm -rf boredsoc/*_generated.v 2> /dev/null || true
