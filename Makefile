CC      := iverilog
SIM_DIR := ./sim_build
FLAGS   := -Wall
FLAGS   += -I..

# Gather sources to set-up objects/output bins
TEST_BASE := ./tests
vpath %.v $(TEST_BASE)
SOURCES	:= $(shell find $(TEST_BASE) -type f -name "*.v" -exec basename {} \;)
OUTPUTS := $(SOURCES:%.v=$(SIM_DIR)/%)

$(SIM_DIR)/%: %.v
	@mkdir -p $(SIM_DIR) $(dir $@)
	$(CC) $(FLAGS) -o $@ $^

.PHONY: all
all:
	@echo "TODO: NOP build recipe for now - need to have this run full synth, PnR, etc later..."

.PHONY: tests
tests: $(OUTPUTS)
# TODO: Move this somewhere else later...
ifdef DOCKER
	@echo "Using Docker for test-prep..."
else
	@echo ""
endif
	@echo "All done."

.PHONY: vcd
vcd: FLAGS += -DDUMP_VCD
vcd: tests

.PHONY: clean
clean:
	rm -rf $(SIM_DIR) 2> /dev/null || true