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
OUTPUT 	            := build
FLAGS               := -Wall
FLAGS               += -I..
ifdef VCD
FLAGS	            += -DDUMP_VCD
endif
DOCKER_CMD          := docker exec -w /src pineapplecore-toolchain
LINE	:= =====================================================================================

# Gather sources to set-up objects/output bins
vpath %.v     tests
vpath %.py    scripts
TB_SOURCES    := $(shell find tests -type f -name "*.v" -exec basename {} \;)
TB_OUTPUTS    := $(TB_SOURCES:%.v=$(OUTPUT)/%.sim)

# Test assembly files
SCRIPTS      := $(shell find scripts -type f -name "*_tb.py" -exec basename {} \;)
TEST_ASM     := $(SCRIPTS:%.py=$(OUTPUT)/%.py.s)
TEST_ELFS    := $(SCRIPTS:%.py=$(OUTPUT)/%.py.elf)
TEST_MEMH    := $(SCRIPTS:%.py=$(OUTPUT)/%.py.mem)

# Testbench ASM
$(TEST_ASM): $(SCRIPTS)
	$(PYTHON) $<

# Testbench ELF
$(TEST_ELFS): $(TEST_ASM)
ifdef DOCKER
	$(DOCKER_CMD) $(AS) -o $@ $<
else
	$(AS) -o $@ $<
endif

# Testbench Objcopy
$(TEST_MEMH): $(TEST_ELFS)
ifdef DOCKER
	$(DOCKER_CMD) $(OBJCOPY) -O verilog --verilog-data-width=4 $< $@
else
	$(OBJCOPY) -O verilog --verilog-data-width=4 $< $@
endif

# Testbench iverilog
$(TB_OUTPUTS): $(TB_SOURCES) $(TEST_MEMH)
	$(TB_CC) $(FLAGS) -o $@ $<

.PHONY: all
all:
	@printf "TODO: NOP build recipe for now - need to have this run full synth, PnR, etc later...\n"

.PHONY: build-dir
build-dir:
	@mkdir -p $(OUTPUT)

.PHONY: tests
tests: build-dir $(TB_OUTPUTS)
	@printf "\nAll done building tests.\n"

# Maybe I should just use/try VUnit at this point 😅
.PHONY: runtests
runtests: tests
	@printf "Running tests...\n"
	@for out in $(TB_OUTPUTS); do \
	    printf "\n[ $$out ]\n$(LINE)\n"; \
		./$$out; \
		printf "$(LINE)\n"; \
	done

.PHONY: clean
clean:
	rm -rf $(OUTPUT) 2> /dev/null || true