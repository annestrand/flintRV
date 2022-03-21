
VERILOG_SOURCES		:= $(ROOT_DIR)/decode.v
VERILOG_SOURCES		+= $(ROOT_DIR)/execute.v

COCOTB_RESULTS_FILE	:= $(ROOT_DIR)/sim_build/results.xml
COMPILE_ARGS		:= -I$(ROOT_DIR)
SIM_BUILD			:= $(ROOT_DIR)/sim_build
SIM					?= icarus

TOPLEVEL			?= ImmGen
MODULE 				:= immgen
include $(shell cocotb-config --makefiles)/Makefile.sim
