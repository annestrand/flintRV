ifdef TC_TRIPLE
TOOLCHAIN_PREFIX    := $(TC_TRIPLE)
else
TOOLCHAIN_PREFIX    := riscv64-unknown-elf
endif
CC                  := $(TOOLCHAIN_PREFIX)-gcc
AS                  := $(TOOLCHAIN_PREFIX)-as
OBJCOPY             := $(TOOLCHAIN_PREFIX)-objcopy
OBJDUMP             := $(TOOLCHAIN_PREFIX)-objdump

IVERILOG_FLAGS      := -Wall
IVERILOG_FLAGS      += -Ihdl
IVERILOG_FLAGS      += -DSIM
IVERILOG_FLAGS      += -DDUMP_VCD

ROOT_DIR            := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ifdef DOCKER
DOCKER_CMD          := docker exec -u user -w /src boredcore
DOCKER_RUNNING      := $(shell docker ps -a -q -f name=boredcore)
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
TEST_PY_MEM         := $(shell find scripts -type f -name "unit_*.mem.py" -exec basename {} \;)
TEST_PY_ASM         := $(shell find scripts -type f -name "unit_*.asm.py" -exec basename {} \;)

VERILATOR_SRCS      := $(shell find tests/cpu -type f -name "*.cc")
VERILATOR_PY_SRCS	:= $(shell find scripts -type f -name "cpu_*.asm.py" -exec basename {} \;)
VERILATOR_TEST_SRCS	:= $(VERILATOR_PY_SRCS:%.asm.py=obj_dir/%.s)
VERILATOR_TEST_ELF	:= $(VERILATOR_TEST_SRCS:%.s=%.elf)
VERILATOR_TEST_MEM	:= $(VERILATOR_TEST_ELF:%.elf=%.mem)

IVERILOG_ALL_SRCS   := $(shell find tests/units -type f -name "*.v" -exec basename {} \;)
IVERILOG_MEMH_SRCS  := $(TEST_PY_MEM:unit_%.mem.py=%.v)
IVERILOG_MEMH_OBJS  := $(IVERILOG_MEMH_SRCS:%.v=out/%.mem.out)
IVERILOG_ASM_SRCS   := $(TEST_PY_ASM:unit_%.asm.py=%.v)
IVERILOG_ASM_OBJS   := $(IVERILOG_ASM_SRCS:%.v=out/%.asm.out)
IVERILOG_PLAIN_SRCS := $(filter-out $(IVERILOG_MEMH_SRCS) $(IVERILOG_ASM_SRCS), $(IVERILOG_ALL_SRCS))
IVERILOG_PLAIN_OBJS := $(IVERILOG_PLAIN_SRCS:%.v=out/%.out)

out/unit_%.mem: unit_%.mem.py
	python3 $<

out/unit_%.s: unit_%.asm.py
	python3 $<

obj_dir/cpu_%.s: scripts/cpu_%.asm.py
	python3 $<

.SECONDARY:
out/unit_%.elf: out/unit_%.s
	$(DOCKER_CMD) $(AS) -o $@ $<

.SECONDARY:
out/unit_%.mem: out/unit_%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

out/%.out: tests/units/%.v hdl/%.v
	iverilog $(IVERILOG_FLAGS) -o $@ $<

out/%.mem.out: tests/units/%.v hdl/%.v out/unit_%.mem
	iverilog $(IVERILOG_FLAGS) -o $@ $<

out/%.asm.out: tests/units/%.v hdl/%.v out/unit_%.mem
	iverilog $(IVERILOG_FLAGS) -o $@ $<

obj_dir/%.cpp: $(VERILATOR_SRCS) $(HDL_SRCS)
	verilator $(VERILATOR_FLAGS) --exe tests/cpu/boredcore.cc --top-module boredcore -cc $(HDL_SRCS)

obj_dir/cpu_%.elf: obj_dir/cpu_%.s
	$(DOCKER_CMD) $(AS) -o $@ $<

obj_dir/cpu_%.mem: obj_dir/cpu_%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

# Remove these ones later
obj_dir/%.elf: tests/cpu/src/%.s
	$(DOCKER_CMD) $(AS) -o $@ $<

obj_dir/%.mem: obj_dir/%.elf
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

# Main build is simulating CPU with Verilator
.PHONY: all
all: build-dir $(VERILATOR_TEST_MEM) obj_dir/test_asm.mem obj_dir/Vboredcore.cpp
	@$(MAKE) -C obj_dir -f Vboredcore.mk Vboredcore
	@printf "\nAll done building cpu-tests.\n"

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
	@mkdir -p out
	@mkdir -p obj_dir

.PHONY: clean
clean:
	rm -rf out/ 2> /dev/null || true
	rm -rf obj_dir 2> /dev/null || true

.PHONY: soc-unit
soc-unit:
	$(MAKE) unit -C ./soc
