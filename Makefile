SHELL:=/bin/bash

MEM_FLAG=-D MEM_SUB

BSC_FLAGS= -aggressive-conditions -keep-fires -show-schedule -check-assert $(MEM_FLAG) -D PROC_FINAL_PROJ -D PROC +RTS -K1G -RTS -steps-max-intervals 10000000 

.PHONY: all clean ProcessorIPC ProcessorRuntime
all: ProcessorIPC ProcessorRuntime

define compileProc
$(1): $(1).bsv
	mkdir -p build_dir/$(1)
	bsc $(BSC_FLAGS) -bdir build_dir/$(1) -simdir build_dir/$(1) -sim -u -g mkProcessor $(1).bsv
	bsc $(BSC_FLAGS) -bdir build_dir/$(1) -simdir build_dir/$(1) -sim -u -e mkProcessor -o  $(1)
endef

$(eval $(call compileProc,ProcessorIPC))
$(eval $(call compileProc,ProcessorRuntime))


clean:
	rm -rf *.v *.ba *.cxx *.o *.h *.so *.sched synthDir testout
	rm -rf test_out 
	rm -rf build_dir
	rm -rf  ProcessorIPC ProcessorRuntime

superclean: clean
	make -C sw clean

auto-test:
	@echo > testout
	@./grade.sh "1 2 3" testout

grade:
	@./grader-mandatory.py testout

