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

CFLAGS+=-mcmodel=medany -nostdlib -nostartfiles -march=rv32i -mabi=ilp32 -mstrict-align
LDFLAGS=-march=rv32i -nostdlib -nostartfiles -Wl,-Tsrc/riscv-link.ld

# Specify source files
files = sort
assemblyFiles = crt0
cFiles = main
# Targets
assemblyObjects = $(addsuffix .o, $(assemblyFiles))
fileObjects = $(addsuffix .o, $(files))

targets = sort
vmhs =  $(addsuffix .vmh, $(targets))
dumps = sort.dump


all: $(vmhs) $(dumps)

$(assemblyObjects): %.o: src/%.S
	$(call check_for_riscv_target)
	$(RISCV_TARGET)gcc $(CFLAGS) -c $< -o $@

$(fileObjects): %.o: %.S
	$(call check_for_riscv_target)
	$(RISCV_TARGET)gcc $(CFLAGS) -c $< -o $@


main_sort.o:  src/main.c
	$(call check_for_riscv_target)
	$(RISCV_TARGET)gcc $(CFLAGS)  -c $< -o $@

%.riscv: main_%.o crt0.o sort.o
	$(call check_for_riscv_target)
	$(RISCV_TARGET)gcc $(LDFLAGS) $^ -o $@

%.vmh: %.riscv ../tools/elf2hex/elf2hex
	mkdir -p $(dir $@)
	../tools/elf2hex/elf2hex $< 0 64K 4 $@

%.dump: %.riscv
	$(call check_for_riscv_target)
	mkdir -p $(dir $@)
	$(RISCV_TARGET)objdump -s -d $^ > $@

# Technically this should be a phony target, but we're assuming this tool
# will not change often.
../tools/elf2hex/elf2hex:
	make -C ../tools/elf2hex

clean:
	rm -rf build __pycache__ tools/__pycache__ tools/*.pyc
	rm -f *.dump *.vmh *.x86 *.o

.PHONY: all clean
