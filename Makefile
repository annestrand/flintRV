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
FLAGS               += -DDUMP_VCD

ROOT_DIR            := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ifdef DOCKER
DOCKER_CMD          := docker exec -u user -w /src boredcore
DOCKER_RUNNING		:= $(shell docker ps -a -q -f name=boredcore)
else
DOCKER_CMD          :=
endif

VERILATOR_FLAGS     := -Wall
VERILATOR_FLAGS     += -Ihdl
VERILATOR_FLAGS     += --trace
VERILATOR_FLAGS     += -CFLAGS "-g"
VERILATOR_FLAGS     += --x-assign unique
VERILATOR_FLAGS     += --x-initial unique

vpath %.v           tests
vpath %.py          scripts

HDL_SRCS            := $(shell find hdl -type f -name "*.v")
TEST_PY_MEM         := $(shell find scripts -type f -name "*.mem.py" -exec basename {} \;)
TEST_PY_MEMH        := $(TEST_PY_MEM:%.mem.py=$(OUTPUT)/%.mem)
TEST_PY_ASM         := $(shell find scripts -type f -name "*.asm.py" -exec basename {} \;)
TEST_PY_ASM_OUT     := $(TEST_PY_ASM:%.asm.py=$(OUTPUT)/%.s)
TEST_PY_ASM_ELF     := $(TEST_PY_ASM_OUT:%.s=%.elf)
TEST_PY_ASM_MEMH    := $(TEST_PY_ASM_ELF:%.elf=%.mem)

VERILATOR_SRCS		:= $(shell find tests/cpu -type f -name "*.cc")

IVERILOG_ALL_SRCS   := $(shell find tests/units -type f -name "*.v" -exec basename {} \;)
IVERILOG_MEMH_SRCS  := $(TEST_PY_MEM:%.mem.py=%.v)
IVERILOG_MEMH_OBJS  := $(IVERILOG_MEMH_SRCS:%.v=$(OUTPUT)/%_mem.out)
IVERILOG_ASM_SRCS   := $(TEST_PY_ASM:%.asm.py=%.v)
IVERILOG_ASM_OBJS   := $(IVERILOG_ASM_SRCS:%.v=$(OUTPUT)/%_asm.out)
IVERILOG_PLAIN_SRCS := $(filter-out $(IVERILOG_MEMH_SRCS) $(IVERILOG_ASM_SRCS), $(IVERILOG_ALL_SRCS))
IVERILOG_PLAIN_OBJS := $(IVERILOG_PLAIN_SRCS:%.v=$(OUTPUT)/%.out)

.SECONDARY:
$(OUTPUT)/%.mem: %.mem.py
	python3 $<

.SECONDARY:
$(OUTPUT)/%.s: %.asm.py
	python3 $<

.SECONDARY:
$(OUTPUT)/%.elf: $(OUTPUT)/%.s
	$(DOCKER_CMD) $(AS) -o $@ $<

.SECONDARY:
$(OUTPUT)/%.mem: $(OUTPUT)/%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

$(OUTPUT)/%_asm.out: tests/units/%.v hdl/%.v $(OUTPUT)/%.mem $(OUTPUT)/%.s
	iverilog $(FLAGS) -o $@ $<

$(OUTPUT)/%_mem.out: tests/units/%.v hdl/%.v $(OUTPUT)/%.mem
	iverilog $(FLAGS) -o $@ $<

$(OUTPUT)/%.out: tests/units/%.v hdl/%.v
	iverilog $(FLAGS) -o $@ $<

obj_dir/%.cpp: $(VERILATOR_SRCS)
	verilator $(VERILATOR_FLAGS) --exe tests/cpu/boredcore.cc --top-module boredcore -cc $(HDL_SRCS)

# Main build is simulating CPU with Verilator
.PHONY: all
all: obj_dir/Vboredcore.cpp
	@$(MAKE) -C obj_dir -f Vboredcore.mk Vboredcore

# Create the docker container (if needed) and start
.PHONY: docker
docker:
ifeq ($(DOCKER_RUNNING),)
	@docker build -t riscv-gnu-toolchain .
	@docker create -it -v $(ROOT_DIR):/src --name boredcore riscv-gnu-toolchain
endif
	@docker start boredcore

# Unit testing (i.e. sub-module testing)
.PHONY: unit
unit: build-dir $(IVERILOG_PLAIN_OBJS) $(IVERILOG_ASM_OBJS) $(IVERILOG_MEMH_OBJS)
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
