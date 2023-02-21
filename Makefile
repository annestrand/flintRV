# Copyright (c) 2023 Austin Annestrand
# Licensed under the MIT License (see LICENSE file).

# --- BUILD ENV -------------------------------------------------------------------------------------------------------
ROOT_DIR               := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OUT_DIR                := build
ifdef DOCKER
DOCKER_PREFIX          := docker exec -u user -w /src drop32
DOCKER_RUNNING         := $(shell docker ps -a -q -f name=drop32)
else
DOCKER_PREFIX          :=
endif
GTEST_BASEDIR          ?= /usr/local/lib
SYSTEM                 := $(shell uname -s)

# Get Verilator info
VERILATOR_VER          := $(shell verilator --version | awk '{print $$2}' | sed 's/\.//')
VERILATOR_ROOT         := $(shell verilator -V | grep VERILATOR_ROOT | awk 'NR==2{print $$3}')
ifeq (, $(VERILATOR_ROOT)) # If VERILATOR_ROOT env is not set, try compiled default(s)
VERILATOR_ROOT         := $(shell verilator -V | grep VERILATOR_ROOT | awk 'NR==1{print $$3}')
ifeq (, $(VERILATOR_ROOT))
$(error \
	"VERILATOR_ROOT not found! See: https://verilator.org/guide/latest/install.html#eventual-installation-options")
endif
endif

# Find Python Interpreter
PYTHON:=$(shell command -v python3 2> /dev/null)
ifeq (, $(PYTHON))
PYTHON:=$(shell command -v python 2> /dev/null)
ifeq (, $(PYTHON))
$(error "Cannot find either 'python3' or 'python' in $$PATH")
endif
endif

# --- RTL SOURCES -----------------------------------------------------------------------------------------------------
RTL_SRCS               := $(shell find rtl -type f -name "*.v")
RTL_SRCS_BASENAMES     := $(notdir $(RTL_SRCS))
RTL_LIBS               := $(RTL_SRCS_BASENAMES:%.v=$(OUT_DIR)/verilated/V%__ALL.a)
RTL_TYPES              := $(RTL_TYPES)

# --- RISCV TOOLCHAIN -------------------------------------------------------------------------------------------------
ifdef TC_TRIPLE
TOOLCHAIN_PREFIX       := $(TC_TRIPLE)
else
TOOLCHAIN_PREFIX       := riscv64-unknown-elf
endif
RISCV_CC               := $(DOCKER_PREFIX) $(TOOLCHAIN_PREFIX)-gcc
RISCV_AS               := $(DOCKER_PREFIX) $(TOOLCHAIN_PREFIX)-as
RISCV_OBJCOPY          := $(DOCKER_PREFIX) $(TOOLCHAIN_PREFIX)-objcopy
RISCV_OBJDUMP          := $(DOCKER_PREFIX) $(TOOLCHAIN_PREFIX)-objdump

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

SUB_SRCS               := $(shell find tests/unit -type f -name "*.v")

# --- VERILATOR  ------------------------------------------------------------------------------------------------------
VFLAGS                 := -Wall
VFLAGS                 += -Irtl
VFLAGS                 += --trace
VFLAGS                 += -CFLAGS "-g"
VFLAGS                 += --x-assign unique
VFLAGS                 += --x-initial unique

VSRCS                  := $(VERILATOR_ROOT)/include/verilated.cpp
VSRCS                  += $(VERILATOR_ROOT)/include/verilated_dpi.cpp
VSRCS                  += $(VERILATOR_ROOT)/include/verilated_vcd_c.cpp
ifeq ($(SYSTEM), Darwin) # TODO: fix this for non macOS builds
VSRCS                  += $(VERILATOR_ROOT)/include/verilated_threads.cpp
endif
VSRCS_BASENAME         := $(notdir $(VSRCS))
VOBJS                  := $(VSRCS_BASENAME:%.cpp=$(OUT_DIR)/verilated/%.o)

# --- SIMULATOR -------------------------------------------------------------------------------------------------------
SIM_FLAGS              := -Wall
SIM_FLAGS              += -Isim
SIM_FLAGS              += -Ibuild/verilated
SIM_FLAGS              += -Iexternal/miniargparse
SIM_FLAGS              += -I$(VERILATOR_ROOT)/include
SIM_FLAGS              += -I$(VERILATOR_ROOT)/include/vltstd
SIM_FLAGS              += -faligned-new
SIM_FLAGS              += -std=c++14

SIM_LDFLAGS            :=
ifeq ($(SYSTEM), Darwin)
# Verilator fix weak symbols on macOS: https://github.com/verilator/verilator/pull/3823
SIM_LDFLAGS            += -Wl,-U,__Z15vl_time_stamp64v,-U,__Z13sc_time_stampv
endif

SIM_SRCS               := $(shell find $(ROOT_DIR)/sim -type f -name "*.cc" -exec basename {} \;)
SIM_OBJS               := $(SIM_SRCS:%.cc=$(OUT_DIR)/sim/%.o)
SIM_OBJS_BASE          := $(filter-out build/sim/main.o,$(SIM_OBJS))

# --- TEST SOURCES ----------------------------------------------------------------------------------------------------
CPU_ASM_TESTS          := $(shell find tests/basic -type f -name "*.s" -exec basename {} \;)
CPU_C_TESTS            := $(shell find tests/algorithms -type f -name "*.c" -exec basename {} \;)
CPU_TEST_HEX           := $(CPU_ASM_TESTS:%.s=$(OUT_DIR)/tests/%.hex)
CPU_TEST_HEX           += $(CPU_C_TESTS:%.c=$(OUT_DIR)/tests/%.hex)
CPU_TEST_INC           := $(CPU_TEST_HEX:%.hex=%.inc)

# External riscv tests
RV32I_TEST_STR         := -name "*.S" ! -name "rem*" ! -name "mul*" ! -name "div*"
RV32I_TEST_SRCS        := $(shell find external/riscv-tests -type f $(RV32I_TEST_STR) -exec basename {} \;)
RV32I_TEST_HEX         := $(RV32I_TEST_SRCS:%.S=$(OUT_DIR)/external/riscv_tests/%.hex)
RV32I_TEST_INC         := $(RV32I_TEST_HEX:%.hex=%.inc)
RV32I_TEST_HEADERS     := $(shell find external/riscv-tests -type f -name "*.h")
# ---
RV32I_TEST_CC_FLAGS    := -nostdlib
RV32I_TEST_CC_FLAGS    += -nostartfiles
RV32I_TEST_CC_FLAGS    += -march=rv32i
RV32I_TEST_CC_FLAGS    += -mabi=ilp32
RV32I_TEST_CC_FLAGS    += -Wl,-Ttext 0x0
RV32I_TEST_CC_FLAGS    += -Wl,--no-relax

TEST_FLAGS             := -Wall
TEST_FLAGS             += -Isim
TEST_FLAGS             += -Ibuild/tests
TEST_FLAGS             += -Ibuild/verilated
TEST_FLAGS             += -Iexternal/miniargparse
TEST_FLAGS             += -Ibuild/external/riscv_tests
TEST_FLAGS             += -I$(VERILATOR_ROOT)/include
TEST_FLAGS             += -I$(VERILATOR_ROOT)/include/vltstd
TEST_FLAGS             += -faligned-new
TEST_FLAGS             += -std=c++14

TEST_LDFLAGS           := -pthread
TEST_LDFLAGS           += $(GTEST_BASEDIR)/libgtest.a
ifeq ($(SYSTEM), Darwin)
# Verilator fix weak symbols on macOS: https://github.com/verilator/verilator/pull/3823
TEST_LDFLAGS           += -Wl,-U,__Z15vl_time_stamp64v,-U,__Z13sc_time_stampv
endif

TEST_SRCS              := $(shell find tests/ -type f -name "*.cc")
TEST_SRCS_BASENAME     := $(notdir $(TEST_SRCS))
TEST_OBJS              := $(TEST_SRCS_BASENAME:%.cc=$(OUT_DIR)/tests/%.o)
TEST_OBJS              += $(SIM_OBJS_BASE)

# --- SOC SOURCES -----------------------------------------------------------------------------------------------------
DROP32SOC_SRC          := drop32soc/firmware.s
DROP32SOC_ELF          := $(DROP32SOC_SRC:%.s=%.elf)
DROP32SOC_FIRMWARE     := $(DROP32SOC_ELF:%.elf=%.mem)
DROP32SOC_COREGEN      := drop32soc/soc_generated.v

# --- PHONY MAKE RECIPES ----------------------------------------------------------------------------------------------
.PHONY: all
all: sim
all: tests
all: soc

# Build tests
.PHONY: tests
tests: $(OUT_DIR)/Vdrop32_tests
tests: $(OUT_DIR)/Unit_tests

# Build simulator
.PHONY: sim
sim: $(OUT_DIR)/Vdrop32

# Build drop32soc firmware and generate drop32 core
.PHONY: soc
soc: $(DROP32SOC_COREGEN)
soc: $(DROP32SOC_ELF)
soc: $(DROP32SOC_FIRMWARE)

# Create the docker container (if needed) and start
.PHONY: docker
docker:
ifeq ($(DOCKER_RUNNING),)
	@docker build -t riscv-gnu-toolchain .
	@docker create -it -v $(ROOT_DIR):/src --name drop32 riscv-gnu-toolchain
endif
	@docker start drop32

.PHONY: clean
clean:
	rm -rf $(OUT_DIR)
	rm -rf drop32soc/firmware.mem
	rm -rf drop32soc/firmware.elf
	rm -rf drop32soc/*_generated.v

# --- MAIN MAKE RECIPES -----------------------------------------------------------------------------------------------
drop32soc/%_generated.v: $(RTL_SRCS) $(RTL_TYPES)
	$(PYTHON) scripts/drop32soc_gen.py > $@

drop32soc/%.elf: drop32soc/%.s
	$(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

drop32soc/%.mem: drop32soc/%.elf
	$(DOCKER_PREFIX) $(RISCV_OBJCOPY) -O verilog --verilog-data-width=4 $< $@
	$(PYTHON) ./scripts/byteswap_memfile.py $@

$(OUT_DIR)/Unit_tests: tests/unit/main_tb.v $(SUB_SRCS) $(RTL_SRCS) | $(OUT_DIR)
	iverilog $(ICARUS_FLAGS) -o $@ $<

$(OUT_DIR)/verilated/%.o: $(VERILATOR_ROOT)/include/%.cpp
	$(CXX) -c -o $@ -std=c++14 -I$(VERILATOR_ROOT)/include/vltstd $<

$(OUT_DIR)/verilated/V%__ALL.a: rtl/%.v | $(OUT_DIR)/verilated
	verilator $(VFLAGS) --Mdir $(dir $@) -cc $<
	@$(MAKE) -C $(dir $@) -f V$(basename $(notdir $<)).mk > /dev/null

$(OUT_DIR)/sim/%.o: sim/%.cc | $(RTL_LIBS) $(OUT_DIR)/sim
	$(CXX) -c -o $@ $(SIM_FLAGS) $<

$(OUT_DIR)/tests/%.o: tests/%.cc | $(CPU_TEST_INC) $(CPU_TEST_HEX) $(RV32I_TEST_INC) $(RTL_LIBS) $(OUT_DIR)/tests
	$(CXX) -c -o $@ $(TEST_FLAGS) $<

$(OUT_DIR)/Vdrop32: | $(SIM_OBJS) $(VOBJS) $(OUT_DIR)/vcd
	$(CXX) -o $@ $(SIM_OBJS) $(OUT_DIR)/verilated/Vdrop32__ALL.a $(VOBJS) $(SIM_LDFLAGS)

$(OUT_DIR)/Vdrop32_tests: | $(TEST_OBJS) $(VOBJS) $(OUT_DIR)/vcd
	$(CXX) -o $@ $(TEST_OBJS) $(OUT_DIR)/verilated/Vdrop32__ALL.a $(VOBJS) $(TEST_LDFLAGS)

.SECONDARY:
$(OUT_DIR)/tests/cpu_%.elf: $(OUT_DIR)/tests/cpu_%.s | $(OUT_DIR)/tests
	$(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

.SECONDARY:
$(OUT_DIR)/tests/%.elf: tests/basic/%.s | $(OUT_DIR)/tests
	$(RISCV_AS) $(RISCV_AS_FLAGS) -o $@ $<

.SECONDARY:
$(OUT_DIR)/tests/%.elf: tests/algorithms/%.c
	$(RISCV_CC) $(RISCV_CC_FLAGS) -Wl,-Tscripts/drop32.ld,-Map=$@.map -o $@ $<

$(OUT_DIR)/tests/%.hex: $(OUT_DIR)/tests/%.elf
	$(RISCV_OBJCOPY) -O binary $< $@

$(OUT_DIR)/tests/%.inc: $(OUT_DIR)/tests/%.hex
	xxd -i $< $@

# RV32I external tests
$(OUT_DIR)/external/riscv_tests/%.elf: external/riscv-tests/%.S $(RV32I_TEST_HEADERS) | $(OUT_DIR)/external/riscv_tests
	$(RISCV_CC) $(RV32I_TEST_CC_FLAGS) -o $@ \
		-DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' \
		-DTEST_FUNC_RET=$(notdir $(basename $<))_ret \
		$<

$(OUT_DIR)/external/riscv_tests/%.hex: $(OUT_DIR)/external/riscv_tests/%.elf
	$(RISCV_OBJCOPY) -O binary $< $@

$(OUT_DIR)/external/riscv_tests/%.inc: $(OUT_DIR)/external/riscv_tests/%.hex
	xxd -i $< $@

$(OUT_DIR):
	@mkdir -p $@

$(OUT_DIR)/sim:
	@mkdir -p $@

$(OUT_DIR)/tests:
	@mkdir -p $@

$(OUT_DIR)/external/riscv_tests:
	@mkdir -p $@

$(OUT_DIR)/vcd:
	@mkdir -p $@

$(OUT_DIR)/verilated:
	@mkdir -p $@
