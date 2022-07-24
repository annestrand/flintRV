CC      := iverilog
OUT_DIR := ../obj_dir/sub/soc
FLAGS   := -Wall
FLAGS   += -DSIM
FLAGS   += -I..
ifdef VCD
FLAGS   += -DDUMP_VCD
endif # VCD

# Gather sources to set-up objects/output bins
TEST_BASE := ./tests
vpath %.v $(TEST_BASE)
SOURCES := $(shell find $(TEST_BASE) -maxdepth 1 -type f -name "*.v" -exec basename {} \;)
OUTPUTS := $(SOURCES:%.v=$(OUT_DIR)/%)

$(OUT_DIR)/%: %.v
	$(CC) $(FLAGS) -o $@ $^

.PHONY: all
all:
	@echo "TODO..."

.PHONY: sub
sub: set-up $(OUTPUTS)

.PHONY: set-up
set-up:
	@mkdir -p $(OUT_DIR)
