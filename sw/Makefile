# This looks for riscv32-unknown-elf-gcc or riscv64-unknown-elf-gcc and sets
# RISCV_TARGET accordingly. The check_for_riscv_target variable is used to
# abort compilation if no RISC-V compiler was found.
RVNE_EXISTS:=$(shell command -v riscv-none-embed-gcc 2> /dev/null)
check_for_riscv_target=$(error No RISC-V compiler found. \
		       Expecting riscv-none-embed-gcc. \
		       Please restart terminal to update tools.)

ifdef RVNE_EXISTS
RISCV_TARGET=$(shell dirname $(RVNE_EXISTS))/riscv-none-embed-
check_for_riscv_target=
endif

ifndef CL_BYTES
CL_BYTES=64
endif

CFLAGS=-mcmodel=medany -nostdlib -nostartfiles -march=rv32i -mabi=ilp32 -mstrict-align -static -fvisibility=hidden
LDFLAGS=-march=rv32i -nostdlib -nostartfiles -Wl,-Ttools/bare-link.ld
OBJDUMPFLAGS=-s -d -Mno-aliases -Mnumeric

MICROTESTS_VMH=$(patsubst microtests/%.S, build/microtests/%.vmh, $(wildcard microtests/*.S))
MICROTESTS_DUMP=$(patsubst microtests/%.S, build/microtests/%.dump, $(wildcard microtests/*.S))
GCDTESTS_VMH=$(patsubst gcdtests/%.S, build/gcdtests/%.vmh, $(wildcard gcdtests/*.S))
GCDTESTS_DUMP=$(patsubst gcdtests/%.S, build/gcdtests/%.dump, $(wildcard gcdtests/*.S))
FULLASMTESTS_VMH=$(patsubst fullasmtests/%.S, build/fullasmtests/%.vmh, $(wildcard fullasmtests/*.S))
FULLASMTESTS_DUMP=$(patsubst fullasmtests/%.S, build/fullasmtests/%.dump, $(wildcard fullasmtests/*.S))

PIPETESTS_VMH=$(patsubst pipetests/%.S, build/pipetests/%.vmh, $(wildcard pipetests/*.S))
PIPETESTS_DUMP=$(patsubst pipetests/%.S, build/pipetests/%.dump, $(wildcard pipetests/*.S))


all: microtests gcdtests fullasmtests pipetests sort # benchmarks 

microtests: $(MICROTESTS_VMH) $(MICROTESTS_DUMP)

gcdtests: $(GCDTESTS_VMH) $(GCDTESTS_DUMP)

fullasmtests: $(FULLASMTESTS_VMH) $(FULLASMTESTS_DUMP)

pipetests: $(PIPETESTS_VMH) $(PIPETESTS_DUMP)

# benchmarks: build/benchmarks
sort: build/sort


# mircotests targets

build/microtests/%.riscv: microtests/%.S
	$(call check_for_riscv_target)
	@mkdir -p build/microtests
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) $^ -o $@

build/microtests/%.vmh: build/microtests/%.riscv tools/elf2hex/elf2hex
	./tools/elf2hex/elf2hex $< 0 16K $(CL_BYTES) $@

build/microtests/%.dump: build/microtests/%.riscv
	$(call check_for_riscv_target)
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) $^ > $@

# gcdtests targets

build/gcdtests/%.riscv: gcdtests/%.S
	$(call check_for_riscv_target)
	@mkdir -p build/gcdtests
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) $^ -o $@

build/gcdtests/%.vmh: build/gcdtests/%.riscv tools/elf2hex/elf2hex
	./tools/elf2hex/elf2hex $< 0 16K $(CL_BYTES) $@

build/gcdtests/%.dump: build/gcdtests/%.riscv
	$(call check_for_riscv_target)
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) $^ > $@

# fullasmtests targets

build/fullasmtests/%.riscv: fullasmtests/%.S
	$(call check_for_riscv_target)
	@mkdir -p build/fullasmtests
	$(RISCV_TARGET)gcc $(CFLAGS) -I fullasmtests $(LDFLAGS) $^ -o $@

build/fullasmtests/%.vmh: build/fullasmtests/%.riscv tools/elf2hex/elf2hex
	./tools/elf2hex/elf2hex $< 0 16K $(CL_BYTES) $@

build/fullasmtests/%.dump: build/fullasmtests/%.riscv
	$(call check_for_riscv_target)
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) $^ > $@

# pipetests targets

build/pipetests/%.riscv: pipetests/%.S
	$(call check_for_riscv_target)
	@mkdir -p build/pipetests
	$(RISCV_TARGET)gcc $(CFLAGS) $(LDFLAGS) $^ -o $@

build/pipetests/%.vmh: build/pipetests/%.riscv tools/elf2hex/elf2hex
	./tools/elf2hex/elf2hex $< 0 16K $(CL_BYTES) $@

build/pipetests/%.dump: build/pipetests/%.riscv
	$(call check_for_riscv_target)
	$(RISCV_TARGET)objdump $(OBJDUMPFLAGS) $^ > $@

# benchmark targets

# build/benchmarks:
# 	make -C benchmarks

# sort targets
build/sort: sort/sort.S
	mkdir -p build/sort
	make -C sort -j
	cp sort/*.vmh build/sort/.
	cp sort/*.dump build/sort/.	

# Technically this should be a phony target, but we're assuming this tool
# will not change often.
tools/elf2hex/elf2hex:
	make -C tools/elf2hex

clean:
	rm -rf build __pycache__ tools/__pycache__
	rm -f *.dump *.vmh *.x86
	make -C sort clean
	make -C sort_opt clean

.PHONY: all microtests gcdtests fullasmtests clean
