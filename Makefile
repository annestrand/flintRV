CC      := iverilog
SIM_DIR := ./sim_build
FLAGS   := -Wall
FLAGS   += -I..
ifdef VCD
FLAGS	+= -DDUMP_VCD
endif
LINE	:= =====================================================================================

# Gather sources to set-up objects/output bins
TEST_BASE := ./tests
vpath %.v $(TEST_BASE)
SOURCES	:= $(shell find $(TEST_BASE) -type f -name "*.v" -exec basename {} \;)
OUTPUTS := $(SOURCES:%.v=$(SIM_DIR)/%)

#ifdef DOCKER
#	@printf "Using Docker for test-prep..."
#else
#	@printf ""
#endif

$(SIM_DIR)/%: %.v
	@mkdir -p $(SIM_DIR) $(dir $@)
	$(CC) $(FLAGS) -o $@ $^

.PHONY: all
all:
	@printf "TODO: NOP build recipe for now - need to have this run full synth, PnR, etc later...\n"

.PHONY: tests
tests: $(OUTPUTS)
	@printf "\nAll done building tests.\n"

# Maybe I should just use/try VUnit at this point 😅
.PHONY: runtests
runtests: tests
	@printf "Running tests...\n"
	@for out in $(OUTPUTS); do \
	    printf "\n[ $$out ]\n$(LINE)\n"; \
		./$$out; \
		printf "$(LINE)\n"; \
	done

.PHONY: clean
clean:
	rm -rf $(SIM_DIR) 2> /dev/null || true