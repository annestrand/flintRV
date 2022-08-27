ifdef TC_TRIPLE
TOOLCHAIN_PREFIX       := $(TC_TRIPLE)
else
TOOLCHAIN_PREFIX       := riscv64-unknown-elf
endif
CC                     := $(TOOLCHAIN_PREFIX)-gcc
AS                     := $(TOOLCHAIN_PREFIX)-as
OBJCOPY                := $(TOOLCHAIN_PREFIX)-objcopy
OBJDUMP                := $(TOOLCHAIN_PREFIX)-objdump

AS_FLAGS               := -march=rv32i
AS_FLAGS               += -mabi=ilp32

SUB_TEST_FLAGS         := -Wall
SUB_TEST_FLAGS         += -Irtl
SUB_TEST_FLAGS         += -DSIM
SUB_TEST_FLAGS         += -DDUMP_VCD

SOC_TEST_FLAGS         := -Wall
SOC_TEST_FLAGS         += -Isoc/common
SOC_TEST_FLAGS         += -DSIM
SOC_TEST_FLAGS         += -DDUMP_VCD

CPU_TEST_OUT           := obj_dir
SUB_TEST_OUT           := obj_dir/sub

ROOT_DIR               := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ifdef DOCKER
DOCKER_CMD             := docker exec -u user -w /src boredcore
DOCKER_RUNNING         := $(shell docker ps -a -q -f name=boredcore)
else
DOCKER_CMD             :=
endif

GTEST_BASEDIR          ?= /usr/local/lib

VERILATOR_VER          := $(shell verilator --version | awk '{print $$2}' | sed 's/\.//')

CPU_TEST_CFLAGS        := -g
CPU_TEST_CFLAGS        += -I$(ROOT_DIR)/tests/cpu
CPU_TEST_CFLAGS        += -DBASE_PATH='\"$(ROOT_DIR)/obj_dir\"'
CPU_TEST_CFLAGS        += -DVERILATOR_VER=$(VERILATOR_VER)

CPU_TEST_FLAGS         := -Wall
CPU_TEST_FLAGS         += -Irtl
CPU_TEST_FLAGS         += --trace
CPU_TEST_FLAGS         += -CFLAGS "$(CPU_TEST_CFLAGS)"
CPU_TEST_FLAGS         += -LDFLAGS "$(GTEST_BASEDIR)/libgtest.a -lpthread"
CPU_TEST_FLAGS         += --x-assign unique
CPU_TEST_FLAGS         += --x-initial unique

vpath %.v tests
vpath %.py scripts

CPU_SRCS               := $(shell find rtl -type f -name "*.v")
TEST_PY_MEM            := $(shell find scripts -type f -name "sub_*.mem.py" -exec basename {} \;)
TEST_PY_ASM            := $(shell find scripts -type f -name "sub_*.asm.py" -exec basename {} \;)

CPU_TEST_SRCS          := $(shell find tests/cpu -type f -name "*.cc")
CPU_ASM_TESTS          := $(shell find tests/cpu/functional -type f -name "*.s" -exec basename {} \;)
CPU_PY_TESTS           := $(shell find scripts -type f -name "cpu_*.asm.py" -exec basename {} \;)
CPU_PY_ASM_TESTS       := $(CPU_PY_TESTS:%.asm.py=$(CPU_TEST_OUT)/%.s)
CPU_TEST_ELF           := $(CPU_PY_ASM_TESTS:%.s=%.elf)
CPU_TEST_MEM           := $(CPU_TEST_ELF:%.elf=%.mem)
CPU_TEST_ASM_MEM       := $(CPU_ASM_TESTS:%.s=$(CPU_TEST_OUT)/%.mem)

SUB_TEST_ALL_SRCS      := $(shell find tests/sub -type f -name "*.v" -exec basename {} \;)
SUB_TEST_MEMH_SRCS     := $(TEST_PY_MEM:sub_%.mem.py=%.v)
SUB_TEST_MEMH_OBJS     := $(SUB_TEST_MEMH_SRCS:%.v=$(SUB_TEST_OUT)/%.mem.out)
SUB_TEST_ASM_SRCS      := $(TEST_PY_ASM:sub_%.asm.py=%.v)
SUB_TEST_ASM_OBJS      := $(SUB_TEST_ASM_SRCS:%.v=$(SUB_TEST_OUT)/%.asm.out)
SUB_TEST_PLAIN_SRCS    := $(filter-out $(SUB_TEST_MEMH_SRCS) $(SUB_TEST_ASM_SRCS), $(SUB_TEST_ALL_SRCS))
SUB_TEST_PLAIN_OBJS    := $(SUB_TEST_PLAIN_SRCS:%.v=$(SUB_TEST_OUT)/%.out)

BOREDSOC_SRC           := boredsoc/firmware.s
BOREDSOC_ELF           := $(BOREDSOC_SRC:%.s=%.elf)
BOREDSOC_FIRMWARE      := $(BOREDSOC_ELF:%.elf=%.mem)

$(SUB_TEST_OUT)/sub_%.mem: sub_%.mem.py
	python3 $< -out $(SUB_TEST_OUT)

$(SUB_TEST_OUT)/sub_%.s: sub_%.asm.py
	python3 $< -out $(SUB_TEST_OUT)

$(CPU_TEST_OUT)/cpu_%.s: scripts/cpu_%.asm.py
	python3 $< -out obj_dir

.SECONDARY:
$(SUB_TEST_OUT)/sub_%.elf: $(SUB_TEST_OUT)/sub_%.s
	$(DOCKER_CMD) $(AS) $(AS_FLAGS) -o $@ $<

.SECONDARY:
$(SUB_TEST_OUT)/sub_%.mem: $(SUB_TEST_OUT)/sub_%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@
	python3 ./scripts/byteswap_memfile.py $@

.SECONDARY:
boredsoc/%.elf: boredsoc/%.s
	$(DOCKER_CMD) $(AS) $(AS_FLAGS) -o $@ $<

.SECONDARY:
boredsoc/%.mem: boredsoc/%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@
	python3 ./scripts/byteswap_memfile.py $@

$(SUB_TEST_OUT)/%.out: tests/sub/%.v rtl/%.v
	iverilog $(SUB_TEST_FLAGS) -o $@ $<

$(SUB_TEST_OUT)/%.mem.out: tests/sub/%.v rtl/%.v $(SUB_TEST_OUT)/sub_%.mem
	iverilog $(SUB_TEST_FLAGS) -o $@ $<

$(SUB_TEST_OUT)/%.asm.out: tests/sub/%.v rtl/%.v $(SUB_TEST_OUT)/sub_%.mem
	iverilog $(SUB_TEST_FLAGS) -o $@ $<

$(CPU_TEST_OUT)/%.cpp: $(CPU_TEST_SRCS) $(CPU_SRCS)
	verilator $(CPU_TEST_FLAGS) --exe tests/cpu/boredcore.cc $(CPU_TEST_SRCS) --top-module boredcore -cc $(CPU_SRCS)

$(CPU_TEST_OUT)/cpu_%.elf: $(CPU_TEST_OUT)/cpu_%.s
	$(DOCKER_CMD) $(AS) $(AS_FLAGS) -o $@ $<

$(CPU_TEST_OUT)/cpu_%.mem: $(CPU_TEST_OUT)/cpu_%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@
	python3 ./scripts/byteswap_memfile.py $@

$(CPU_TEST_OUT)/%.elf: tests/cpu/functional/%.s
	$(DOCKER_CMD) $(AS) $(AS_FLAGS) -o $@ $<

$(CPU_TEST_OUT)/%.mem: $(CPU_TEST_OUT)/%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@
	python3 ./scripts/byteswap_memfile.py $@

# =====================================================================================================================
.PHONY: all
all: docker tests soc

# Build tests
.PHONY: tests
tests: build-dir $(CPU_TEST_MEM) $(CPU_TEST_ASM_MEM) $(CPU_TEST_OUT)/Vboredcore.cpp
tests: $(SUB_TEST_PLAIN_OBJS) $(SUB_TEST_ASM_OBJS) $(SUB_TEST_MEMH_OBJS)
tests: $(SOC_TEST_OBJS)
	@$(MAKE) -C obj_dir -f Vboredcore.mk Vboredcore
	@printf "\nAll done building cpu tests.\n"

# Build boredsoc firmware
.PHONY: soc
soc: $(BOREDSOC_FIRMWARE)
	@printf "\nAll done building boredsoc firmware.\n"

# Create the docker container (if needed) and start
.PHONY: docker
docker:
ifeq ($(DOCKER_RUNNING),)
	@docker build -t riscv-gnu-toolchain .
	@docker create -it -v $(ROOT_DIR):/src --name boredcore riscv-gnu-toolchain
endif
	@docker start boredcore

.PHONY: build-dir
build-dir:
	@mkdir -p $(CPU_TEST_OUT)/
	@mkdir -p $(SUB_TEST_OUT)/

.PHONY: clean
clean:
	rm -rf obj_dir 2> /dev/null || true
	rm -rf boredsoc/firmware.mem 2> /dev/null || true
	rm -rf boredsoc/firmware.elf 2> /dev/null || true
