ifdef TC_TRIPLE
TOOLCHAIN_PREFIX       := $(TC_TRIPLE)
else
TOOLCHAIN_PREFIX       := riscv64-unknown-elf
endif
CC                     := $(TOOLCHAIN_PREFIX)-gcc
AS                     := $(TOOLCHAIN_PREFIX)-as
OBJCOPY                := $(TOOLCHAIN_PREFIX)-objcopy
OBJDUMP                := $(TOOLCHAIN_PREFIX)-objdump

SUB_TEST_FLAGS         := -Wall
SUB_TEST_FLAGS         += -Ihdl
SUB_TEST_FLAGS         += -DSIM
SUB_TEST_FLAGS         += -DDUMP_VCD

SOC_TEST_FLAGS         := -Wall
SOC_TEST_FLAGS         += -Isoc
SOC_TEST_FLAGS         += -DSIM
SOC_TEST_FLAGS         += -DDUMP_VCD

CPU_TEST_OUT           := obj_dir
SUB_TEST_OUT           := obj_dir/sub
SOC_TEST_OUT           := obj_dir/soc

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
CPU_TEST_CFLAGS        += -DBASE_PATH='\"$(ROOT_DIR)/obj_dir\"'
CPU_TEST_CFLAGS        += -DVERILATOR_VER=$(VERILATOR_VER)

CPU_TEST_FLAGS         := -Wall
CPU_TEST_FLAGS         += -Ihdl
CPU_TEST_FLAGS         += --trace
CPU_TEST_FLAGS         += -CFLAGS "$(CPU_TEST_CFLAGS)"
CPU_TEST_FLAGS         += -LDFLAGS "$(GTEST_BASEDIR)/libgtest.a -lpthread"
CPU_TEST_FLAGS         += --x-assign unique
CPU_TEST_FLAGS         += --x-initial unique

vpath %.v tests
vpath %.py scripts

HDL_SRCS               := $(shell find hdl -type f -name "*.v")
TEST_PY_MEM            := $(shell find scripts -type f -name "sub_*.mem.py" -exec basename {} \;)
TEST_PY_ASM            := $(shell find scripts -type f -name "sub_*.asm.py" -exec basename {} \;)

CPU_TEST_SRCS          := $(shell find tests/cpu -type f -name "*.cc")
CPU_TEST_TEST_ASM      := $(shell find tests/cpu/programs -type f -name "*.s" -exec basename {} \;)
CPU_TEST_PY_SRCS       := $(shell find scripts -type f -name "cpu_*.asm.py" -exec basename {} \;)
CPU_TEST_TEST_SRCS     := $(CPU_TEST_PY_SRCS:%.asm.py=$(CPU_TEST_OUT)/%.s)
CPU_TEST_TEST_ELF      := $(CPU_TEST_TEST_SRCS:%.s=%.elf)
CPU_TEST_TEST_MEM      := $(CPU_TEST_TEST_ELF:%.elf=%.mem)
CPU_TEST_TEST_ASM_MEM  := $(CPU_TEST_TEST_ASM:%.s=$(CPU_TEST_OUT)/%.mem)

SUB_TEST_ALL_SRCS      := $(shell find tests/sub -type f -name "*.v" -exec basename {} \;)
SUB_TEST_MEMH_SRCS     := $(TEST_PY_MEM:sub_%.mem.py=%.v)
SUB_TEST_MEMH_OBJS     := $(SUB_TEST_MEMH_SRCS:%.v=$(SUB_TEST_OUT)/%.mem.out)
SUB_TEST_ASM_SRCS      := $(TEST_PY_ASM:sub_%.asm.py=%.v)
SUB_TEST_ASM_OBJS      := $(SUB_TEST_ASM_SRCS:%.v=$(SUB_TEST_OUT)/%.asm.out)
SUB_TEST_PLAIN_SRCS    := $(filter-out $(SUB_TEST_MEMH_SRCS) $(SUB_TEST_ASM_SRCS), $(SUB_TEST_ALL_SRCS))
SUB_TEST_PLAIN_OBJS    := $(SUB_TEST_PLAIN_SRCS:%.v=$(SUB_TEST_OUT)/%.out)

SOC_TEST_SRCS          := $(shell find tests/soc -type f -name "*.v" -exec basename {} \;)
SOC_TEST_OBJS          := $(SOC_TEST_SRCS:%.v=$(SOC_TEST_OUT)/%.out)

$(SUB_TEST_OUT)/sub_%.mem: sub_%.mem.py
	python3 $< -out $(SUB_TEST_OUT)

$(SUB_TEST_OUT)/sub_%.s: sub_%.asm.py
	python3 $< -out $(SUB_TEST_OUT)

$(CPU_TEST_OUT)/cpu_%.s: scripts/cpu_%.asm.py
	python3 $< -out obj_dir

.SECONDARY:
$(SUB_TEST_OUT)/sub_%.elf: $(SUB_TEST_OUT)/sub_%.s
	$(DOCKER_CMD) $(AS) -o $@ $<

.SECONDARY:
$(SUB_TEST_OUT)/sub_%.mem: $(SUB_TEST_OUT)/sub_%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

$(SUB_TEST_OUT)/%.out: tests/sub/%.v hdl/%.v
	iverilog $(SUB_TEST_FLAGS) -o $@ $<

$(SUB_TEST_OUT)/%.mem.out: tests/sub/%.v hdl/%.v $(SUB_TEST_OUT)/sub_%.mem
	iverilog $(SUB_TEST_FLAGS) -o $@ $<

$(SUB_TEST_OUT)/%.asm.out: tests/sub/%.v hdl/%.v $(SUB_TEST_OUT)/sub_%.mem
	iverilog $(SUB_TEST_FLAGS) -o $@ $<

$(SOC_TEST_OUT)/%.out: tests/soc/%.v soc/%.v
	iverilog $(SOC_TEST_FLAGS) -o $@ $<

$(CPU_TEST_OUT)/%.cpp: $(CPU_TEST_SRCS) $(HDL_SRCS)
	verilator $(CPU_TEST_FLAGS) --exe tests/cpu/boredcore.cc $(CPU_TEST_SRCS) --top-module boredcore -cc $(HDL_SRCS)

$(CPU_TEST_OUT)/cpu_%.elf: $(CPU_TEST_OUT)/cpu_%.s
	$(DOCKER_CMD) $(AS) -o $@ $<

$(CPU_TEST_OUT)/cpu_%.mem: $(CPU_TEST_OUT)/cpu_%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

$(CPU_TEST_OUT)/%.elf: tests/cpu/programs/%.s
	$(DOCKER_CMD) $(AS) -o $@ $<

$(CPU_TEST_OUT)/%.mem: $(CPU_TEST_OUT)/%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@
# =====================================================================================================================
# Build tests
.PHONY: tests
tests: build-dir $(CPU_TEST_TEST_MEM) $(CPU_TEST_TEST_ASM_MEM) $(CPU_TEST_OUT)/Vboredcore.cpp
tests: $(SUB_TEST_PLAIN_OBJS) $(SUB_TEST_ASM_OBJS) $(SUB_TEST_MEMH_OBJS)
tests: $(SOC_TEST_OBJS)
	@$(MAKE) -C obj_dir -f Vboredcore.mk Vboredcore
	@printf "\nAll done building cpu tests.\n"

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
	@mkdir -p $(SOC_TEST_OUT)/

.PHONY: clean
clean:
	rm -rf obj_dir 2> /dev/null || true
