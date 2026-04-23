PREFIX	?= arm-none-eabi
CC		= $(PREFIX)-gcc
LD		= $(PREFIX)-gcc
AR		= $(PREFIX)-ar
OBJCOPY	= $(PREFIX)-objcopy
OBJDUMP	= $(PREFIX)-objdump
GDB		= $(PREFIX)-gdb

PLATFORM ?=STM32F4

ifeq ($(PLATFORM),STM32F4)

LDSCRIPT = common/stm32f4/LinkerScript.ld

exclude_c = # c files to filter out
cfiles_base =$(filter-out $(exclude_c), $(wildcard *.c))
cfiles = $(cfiles_base)
hfiles = $(wildcard *.h)
cfiles-o = $(addprefix obj/,$(addsuffix .o,$(cfiles)))

HALPATH = ./common
include ./common/stm32f4/Makefile.stm32f4

make_stm32f4_objs = $(addprefix obj/common/stm32f4/,$(addsuffix .o,$(1)))
src-o = $(call make_stm32f4_objs,$(SRC)) # SRC defined in Makefile.stm32f4
src-o += obj/common/hal-stm32f4.c.o
asrc-o = $(call make_stm32f4_objs,$(ASRC))

LINKDEPS += $(cfiles-o) $(src-o) $(asrc-o) $(hfiles) $(LDSCRIPT)
CFLAGS += $(addprefix -I,$(EXTRAINCDIRS)) # extra includes defined in Makefile.stm32f4
CFLAGS += -Icommon -mcpu=cortex-m4 -DSS_VER=1 $(CDEFS)# CDEFS defined in Makefile.stm32f4

all: hex/stm.hex

endif

# Generic rules

obj/_ELFNAME_%.o: $(LINKDEPS)
	@echo "  GEN     $@"
	$(Q)echo "const char _elf_name[] = \"$(ELFNAME)\";" | \
		$(CC) -x c -c -o $@ $(filter-out -g3,$(CFLAGS)) -

elf/%.elf: obj/_ELFNAME_%.elf.o $(LINKDEPS)
	@echo "  LD      $@"
	$(Q)[ -d $(@D) ] || mkdir -p $(@D)
	$(Q)$(LD) $(CFLAGS) $(LDFLAGS) -o $@ $(filter %.o,$^) -Wl,--start-group $(LDLIBS) -Wl,--end-group

obj/%.a:
	@echo "  AR      $@"
	$(Q)[ -d $(@D) ] || mkdir -p $(@D)
	$(Q)$(AR) rcs $@ $(filter %.o,$^)

bin/%.bin: elf/%.elf
	@echo "  OBJCOPY $@"
	$(Q)[ -d $(@D) ] || mkdir -p $(@D)
	$(Q)$(OBJCOPY) -Obinary $< $@

hex/%.hex: elf/%.elf
	@echo "  OBJCOPY $@"
	$(Q)[ -d $(@D) ] || mkdir -p $(@D)
	$(Q)$(OBJCOPY) -Oihex $< $@

obj/%.c.o: %.c
	@echo "  CC      $@"
	$(Q)[ -d $(@D) ] || mkdir -p $(@D)
	$(Q)$(CC) -c -o $@ $(CFLAGS) $<

obj/%.S.o: %.S
	@echo "  AS      $@"
	$(Q)[ -d $(@D) ] || mkdir -p $(@D)
	$(Q)$(CC) -c -o $@ $(CFLAGS) $<

obj/%.s.o: %.s
	@echo "  AS      $@"
	$(Q)[ -d $(@D) ] || mkdir -p $(@D)
	$(Q)$(CC) -c -o $@ $(CFLAGS) $<


clean:
	find . -name \*.o -type f -exec rm -f {} \;
	find . -name \*.d -type f -exec rm -f {} \;
	rm -rf obj/ bin/ elf/ hex/
