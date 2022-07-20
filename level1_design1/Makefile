# See LICENSE.vyoma for details

TOPLEVEL_LANG ?= verilog
PWD=$(shell pwd)
VERILOG_SOURCES 	= $(PWD)/mux.v
TOPLEVEL 			:= mux          # design
MODULE   			:= test_mux     # test

include $(shell cocotb-config --makefiles)/Makefile.sim

## RULES
.PHONY: clean_all run_debug

run_debug:
	@make COCOTB_LOG_LEVEL=DEBUG

clean_all: clean
	@rm -rf *.xml sim_build __pycache__ 
