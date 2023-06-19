BUILD_DIR=../build/
include $(BUILD_DIR)/software/include/generated/variables.mak
include $(SOC_DIRECTORY)/software/common.mak

# Permit TFTP_SERVER_PORT override from shell environment / command line
ifdef TFTP_SERVER_PORT
CFLAGS += -DTFTP_SERVER_PORT=$(TFTP_SERVER_PORT)
endif

OBJECTS = boot-helper.o	\
	  boot.o			\
	  helpers.o			\
	  cmd_bios.o		\
	  cmd_mem.o			\
	  cmd_boot.o		\
	  cmd_i2c.o			\
	  cmd_spiflash.o	\
	  cmd_litedram.o	\
	  cmd_liteeth.o		\
	  cmd_litesdcard.o  \
	  cmd_litesata.o    \
	  sim_debug.o		\
	  main.o
#OBJECTS += complete.o
#OBJECTS += readline.o
OBJECTS += readline_simple.o
CFLAGS += -DBIOS_CONSOLE_NO_AUTOCOMPLETE
CFLAGS += -DBIOS_CONSOLE_NO_HISTORY
CFLAGS += -DBIOS_CONSOLE_LITE
LSCRIPT = linker.ld

all: bios.bin
	$(PYTHON) -m litex.soc.software.memusage bios.elf $(CURDIR)/../build/software/include/generated/regions.ld $(TRIPLE)

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@


vpath %.a $(PACKAGES:%=../build/software/%)

bios.elf: crt0.o $(OBJECTS)
	$(CC) $(LDFLAGS) -T $(LSCRIPT) -N -o $@ \
		crt0.o \
		$(OBJECTS) \
		$(PACKAGES:%=-L../build/software/%) \
		-Wl,--whole-archive \
		-Wl,--gc-sections \
		-Wl,-Map,$@.map \
		$(LIBS:lib%=-l%)

# pull in dependency info for *existing* .o files
-include $(OBJECTS:.o=.d)

VPATH = .:cmds:$(CPU_DIRECTORY)

%.o: %.c
	$(compile)

%.o: %.S
	$(assemble)

clean:
	$(RM) $(OBJECTS) bios.elf bios.bin .*~ *~ *.d *.map crt0.o

.PHONY: all clean
