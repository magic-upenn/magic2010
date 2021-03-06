# Name: Makefile
# Author: <insert your name here>
# Copyright: <insert your copyright message here>
# License: <insert your license reference here>

# This is a prototype Makefile. Modify it according to your needs.
# You should at least check the settings for
# DEVICE ....... The AVR device you compile for
# CLOCK ........ Target AVR clock rate in Hertz
# OBJECTS ...... The object files created from your source files. This list is
#                usually the same as the list of source files with suffix ".o".
# PROGRAMMER ... Options to avrdude which define the hardware you use for
#                uploading to the AVR and the interface where this hardware
#                is connected.
# FUSES ........ Parameters for avrdude to flash the fuses appropriately.

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
  #export OSTYPE
endif

ifeq ($(OSTYPE),linux)
  USBDEVICE = /dev/ttyUSB0
endif
ifeq ($(OSTYPE),darwin)
  USBDEVICE = $(shell ls /dev/cu.usbserial*)
endif

DEVICE     = atmega1280
CLOCK      = 16000000

PROGRAMMER = -c stk500v1 -P $(USBDEVICE) -b 57600 -D

OBJECTS    = uart0.o rs485.o timer2.o timer1.o timer5.o uart3.o MotorControllerHBridge.o MotorControllerPwm.o DynamixelPacket.o adc.o HostInterface.o main.o
FUSES      = -U hfuse:w:0xdf:m -U lfuse:w:0x62:m

# ATMega8 fuse bits (fuse bits for other devices are different!):
# Example for 8 MHz internal oscillator
# Fuse high byte:
# 0xd9 = 1 1 0 1   1 0 0 1 <-- BOOTRST (boot reset vector at 0x0000)
#        ^ ^ ^ ^   ^ ^ ^------ BOOTSZ0
#        | | | |   | +-------- BOOTSZ1
#        | | | |   +---------- EESAVE (set to 0 to preserve EEPROM over chip erase)
#        | | | +-------------- CKOPT (clock option, depends on oscillator type)
#        | | +---------------- SPIEN (if set to 1, serial programming is disabled)
#        | +------------------ WDTON (if set to 0, watchdog is always on)
#        +-------------------- RSTDISBL (if set to 0, RESET pin is disabled)
# Fuse low byte:
# 0x24 = 0 0 1 0   0 1 0 0
#        ^ ^ \ /   \--+--/
#        | |  |       +------- CKSEL 3..0 (8M internal RC)
#        | |  +--------------- SUT 1..0 (slowly rising power)
#        | +------------------ BODEN (if 0, brown-out detector is enabled)
#        +-------------------- BODLEVEL (if 0: 4V, if 1: 2.7V)

# Example for 12 MHz external crystal:
# Fuse high byte:
# 0xc9 = 1 1 0 0   1 0 0 1 <-- BOOTRST (boot reset vector at 0x0000)
#        ^ ^ ^ ^   ^ ^ ^------ BOOTSZ0
#        | | | |   | +-------- BOOTSZ1
#        | | | |   +---------- EESAVE (set to 0 to preserve EEPROM over chip erase)
#        | | | +-------------- CKOPT (clock option, depends on oscillator type)
#        | | +---------------- SPIEN (if set to 1, serial programming is disabled)
#        | +------------------ WDTON (if set to 0, watchdog is always on)
#        +-------------------- RSTDISBL (if set to 0, RESET pin is disabled)
# Fuse low byte:
# 0x9f = 1 0 0 1   1 1 1 1
#        ^ ^ \ /   \--+--/
#        | |  |       +------- CKSEL 3..0 (external >8M crystal)
#        | |  +--------------- SUT 1..0 (crystal osc, BOD enabled)
#        | +------------------ BODEN (if 0, brown-out detector is enabled)
#        +-------------------- BODLEVEL (if 0: 4V, if 1: 2.7V)


# Tune the lines below only if you know what you are doing:

AVRDUDE = avrdude $(PROGRAMMER) -p $(DEVICE)
COMPILE = avr-gcc -Wall -O3 -DF_CPU=$(CLOCK) -mmcu=$(DEVICE) $(INCLUDES)
ATMEL_COMMON_PATH = ../Common
MAGIC_COMMON_PATH = ../../../common/dataTypes

INCLUDES   = -I. -I$(MAGIC_COMMON_PATH) -I$(ATMEL_COMMON_PATH)

# symbolic targets:
all:	main.bin

.c.o:
	$(COMPILE) -c $< -o $@ $(INCLUDES)

DynamixelPacket.o: $(MAGIC_COMMON_PATH)/DynamixelPacket.c
	$(COMPILE) -c $< -o $@

HostInterface.o: $(ATMEL_COMMON_PATH)/HostInterface.c
	$(COMPILE) -c $< -o $@

uart0.o: $(ATMEL_COMMON_PATH)/uart0.c
	$(COMPILE) -c $< -o $@

uart1.o: $(ATMEL_COMMON_PATH)/uart1.c
	$(COMPILE) -c $< -o $@

uart2.o: $(ATMEL_COMMON_PATH)/uart2.c
	$(COMPILE) -c $< -o $@

uart3.o: $(ATMEL_COMMON_PATH)/uart3.c
	$(COMPILE) -c $< -o $@

rs485.o: $(ATMEL_COMMON_PATH)/rs485.c
	$(COMPILE) -c $< -o $@

GpsInterface.o: $(ATMEL_COMMON_PATH)/GpsInterface.c
	$(COMPILE) -c $< -o $@

BusInterface.o: $(ATMEL_COMMON_PATH)/BusInterface.c
	$(COMPILE) -c $< -o $@


.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $@
# "-x assembler-with-cpp" should not be necessary since this is the default
# file type for the .S (with capital S) extension. However, upper case
# characters are not always preserved on Windows. To ensure WinAVR
# compatibility define the file type manually.

.c.s:
	$(COMPILE) -S $< -o $@

flash:	all
	$(AVRDUDE) -U flash:w:main.hex:i

fuse:
	$(AVRDUDE) $(FUSES)

# Xcode uses the Makefile targets "", "clean" and "install"
#install: flash fuse
install: flash

# if you use a bootloader, change the command below appropriately:
load: all
	bootloadHID main.hex

clean:
	rm -f main.bin main.hex main.elf $(OBJECTS)

# file targets:
main.elf: $(OBJECTS)
	$(COMPILE) -o main.elf $(OBJECTS) -lm

main.bin: main.hex
	avr-objcopy -O binary -I ihex main.hex main.bin

main.hex: main.elf
	rm -f main.hex
	avr-objcopy -j .text -j .data -O ihex main.elf main.hex
# If you have an EEPROM section, you must also create a hex file for the
# EEPROM and add it to the "flash" target.

# Targets for code debugging and analysis:
disasm:	main.elf
	avr-objdump -d main.elf

cpp:
	$(COMPILE) -E main.c
