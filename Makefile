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
ICARUS_OUT             := $(OUT_BASE)/sub

ICARUS_FLAGS           := -Wall
ICARUS_FLAGS           += -Irtl
ICARUS_FLAGS           += -DSIM
ICARUS_FLAGS           += -DDUMP_VCD

# --- VERILATOR -------------------------------------------------------------------------------------------------------
VERILATOR_VER          := $(shell verilator --version | awk '{print $$2}' | sed 's/\.//')

VERILATOR_CFLAGS       := -g
VERILATOR_CFLAGS       += -I$(ROOT_DIR)/sim/verilator
VERILATOR_CFLAGS       += -DBASE_PATH='\"$(OUT_BASE)/cpu\"'
VERILATOR_CFLAGS       += -DVERILATOR_VER=$(VERILATOR_VER)

VERILATOR_FLAGS        := -Wall
VERILATOR_FLAGS        += -Irtl
VERILATOR_FLAGS        += --trace
VERILATOR_FLAGS        += -CFLAGS "$(VERILATOR_CFLAGS)"
VERILATOR_FLAGS        += -LDFLAGS "$(GTEST_BASEDIR)/libgtest.a -lpthread"
VERILATOR_FLAGS        += --x-assign unique
VERILATOR_FLAGS        += --x-initial unique
VERILATOR_FLAGS        += --top-module boredcore
VERILATOR_FLAGS        += --exe

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
CPU_TEST_MEM           += $(CPU_ASM_TESTS:%.s=build/cpu/%.hex)
CPU_TEST_MEM           += $(CPU_C_TESTS:%.c=build/cpu/%.hex)

SUB_TEST_ALL_SRCS      := $(shell find tests/sub -type f -name "*.v" -exec basename {} \;)
SUB_TEST_MEMH_SRCS     := $(TEST_PY_MEM:sub_%.mem.py=%.v)
SUB_TEST_MEMH_OBJS     := $(SUB_TEST_MEMH_SRCS:%.v=$(ICARUS_OUT)/%.mem.out)
SUB_TEST_ASM_SRCS      := $(TEST_PY_ASM:sub_%.asm.py=%.v)
SUB_TEST_ASM_OBJS      := $(SUB_TEST_ASM_SRCS:%.v=$(ICARUS_OUT)/%.asm.out)
SUB_TEST_PLAIN_SRCS    := $(filter-out $(SUB_TEST_MEMH_SRCS) $(SUB_TEST_ASM_SRCS), $(SUB_TEST_ALL_SRCS))
SUB_TEST_PLAIN_OBJS    := $(SUB_TEST_PLAIN_SRCS:%.v=$(ICARUS_OUT)/%.out)

BOREDSOC_SRC           := boredsoc/firmware.s
BOREDSOC_ELF           := $(BOREDSOC_SRC:%.s=%.elf)
BOREDSOC_FIRMWARE      := $(BOREDSOC_ELF:%.elf=%.mem)
BOREDSOC_COREGEN       := boredsoc/core_generated.v

# --- MAIN MAKE RECIPES -----------------------------------------------------------------------------------------------
$(ICARUS_OUT)/sub_%.mem: sub_%.mem.py
	python3 $< -out $(ICARUS_OUT)

$(ICARUS_OUT)/sub_%.s: sub_%.asm.py
	python3 $< -out $(ICARUS_OUT)

build/cpu/cpu_%.s: scripts/cpu_%.asm.py
	python3 $< -out build/cpu

boredsoc/%_generated.v:
	python3 scripts/core_gen.py -if none -pc 0x0 -isa RV32I -name CPU > $@

.SECONDARY:
$(ICARUS_OUT)/sub_%.elf: $(ICARUS_OUT)/sub_%.s
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

.SECONDARY:
$(ICARUS_OUT)/sub_%.mem: $(ICARUS_OUT)/sub_%.elf
	$(DOCKER_CMD) $(RISCV_OBJCOPY) -O verilog --verilog-data-width=4 $< $@
	python3 ./scripts/byteswap_memfile.py $@

.SECONDARY:
boredsoc/%.elf: boredsoc/%.s
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

.SECONDARY:
boredsoc/%.mem: boredsoc/%.elf
	$(DOCKER_CMD) $(RISCV_OBJCOPY) -O verilog --verilog-data-width=4 $< $@
	python3 ./scripts/byteswap_memfile.py $@

$(ICARUS_OUT)/%.out: tests/sub/%.v rtl/%.v
	iverilog $(ICARUS_FLAGS) -o $@ $<

$(ICARUS_OUT)/%.mem.out: tests/sub/%.v rtl/%.v $(ICARUS_OUT)/sub_%.mem
	iverilog $(ICARUS_FLAGS) -o $@ $<

$(ICARUS_OUT)/%.asm.out: tests/sub/%.v rtl/%.v $(ICARUS_OUT)/sub_%.mem
	iverilog $(ICARUS_FLAGS) -o $@ $<

# Sim target
build/sim/%.cpp: $(VERILATOR_SIM_SRCS) $(RTL_SRCS)
	verilator $(VERILATOR_FLAGS) --Mdir build/sim $(VERILATOR_SIM_SRCS) -cc $(RTL_SRCS)

# CPU test target
build/cpu/%.cpp: $(VERILATOR_SIM_SRCS) $(RTL_SRCS)
	verilator $(VERILATOR_FLAGS) --Mdir build/cpu $(VERILATOR_SIM_SRCS) -cc $(RTL_SRCS)

build/cpu/cpu_%.elf: build/cpu/cpu_%.s
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

build/cpu/%.elf: tests/cpu/functional/%.s
	$(DOCKER_CMD) $(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

build/cpu/%.elf: tests/cpu/algorithms/%.c
	$(DOCKER_CMD) $(RISCV_CC) $(RISCV_CC_FLAGS) -Wl,-Tscripts/boredcore.ld,-Map=$@.map -o $@ $<

build/cpu/%.hex: build/cpu/%.elf
	$(DOCKER_CMD) $(RISCV_OBJCOPY) -O binary $< $@

# --- PHONY MAKE RECIPES ----------------------------------------------------------------------------------------------
.PHONY: all
all: submodules sim tests soc

# Build tests
.PHONY: tests
tests: VERILATOR_SIM_SRCS+=$(CPU_TEST_SRCS)
tests: build-test-dirs $(CPU_TEST_MEM) $(OUT_BASE)/cpu/Vboredcore.cpp
tests: $(SUB_TEST_PLAIN_OBJS) $(SUB_TEST_ASM_OBJS) $(SUB_TEST_MEMH_OBJS)
	$(MAKE) -C build/cpu -f Vboredcore.mk

# Build Verilated simulator
.PHONY: sim
sim: VERILATOR_SIM_SRCS+=$(ROOT_DIR)/sim/verilator/main.cc
sim: build-sim-dir $(OUT_BASE)/sim/Vboredcore.cpp
sim:
	$(MAKE) -C build/sim -f Vboredcore.mk

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
	@mkdir -p $(OUT_BASE)/cpu
	@mkdir -p $(ICARUS_OUT)

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
