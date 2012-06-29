STM32_CC            = arm-none-eabi-gcc
STM32_LD            = arm-none-eabi-ld
STM32_AR            = arm-none-eabi-ar
STM32_AS            = arm-none-eabi-as
STM32_CP            = arm-none-eabi-objcopy
STM32_OD            = arm-none-eabi-objdump

STM32_LD_PATH       = $(STM32_ROOT_PATH)/ld
STM32_INCLUDES      = -I. -I$(STM32_ROOT_PATH)/include -I$(STM32_ROOT_PATH)/include
STM32_LIB_PATH      = $(STM32_ROOT_PATH)/lib
STM32_SRC_PATH      = $(STM32_ROOT_PATH)/src
GCC_STM32_LIB_PATH  = -L$(STM32_GCC_ROOT)/arm-none-eabi/lib/ -L$(STM32_GCC_ROOT)/../lib/gcc/arm-none-eabi/4.5.2/ 
  
STM32_CFLAGS        =  $(STM32_INCLUDES) -c -fno-common -O2 -mcpu=cortex-m3 -mthumb -nostartfiles #-Wall
STM32_LFLAGS        = -T$(STM32_LD_PATH)/stm32f10x_flash.ld

ifndef STM32_DEVICE_TYPE
  STM32_DEVICE_TYPE = -DSTM32F10X_MD
endif

STM32_DEFINES       = $(STM32_DEVICE_TYPE) -DHSE_VALUE=16000000 #medium density device
STM32_LIBS          =  -L$(STM32_LIB_PATH) $(GCC_STM32_LIB_PATH) -lstm32f10x --start-group -lgcc -lc -lgloss-linux -lnosys -lIQmath -lm --end-group

STM32_CPFLAGS       = -Obinary
STM32_ODFLAGS	      = -S

target : main.out

%.o: %.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

system_stm32f10x.o : $(STM32_SRC_PATH)/system_stm32f10x.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

startup_stm32f10x_md.o : $(STM32_SRC_PATH)/startup_stm32f10x_md.s
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

uart1.o : $(STM32_SRC_PATH)/uart1.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

uart1_dma.o : $(STM32_SRC_PATH)/uart1_dma.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

uart2.o : $(STM32_SRC_PATH)/uart2.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

uart3.o : $(STM32_SRC_PATH)/uart3.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

uart4.o : $(STM32_SRC_PATH)/uart4.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

uart5.o : $(STM32_SRC_PATH)/uart5.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

rs485.o : $(STM32_SRC_PATH)/rs485.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

systick.o : $(STM32_SRC_PATH)/systick.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

DynamixelPacket.o : $(STM32_ROOT_PATH)/src/DynamixelPacket.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

kBotPacket.o : $(STM32_ROOT_PATH)/src/kBotPacket.c
	$(STM32_CC) $(STM32_CFLAGS) $(STM32_DEFINES) -o $@ $^

install_reset: main.out
	SendDynamixelPacket /dev/ttyUSB0 $(RESET_BAUDRATE) 0 201 "FLASH_ME"
	sleep 0.5
	stm32flash -w main.bin /dev/ttyUSB0 -b 115200

install_reset0: main.out
	SendDynamixelPacket /dev/ttyUSB0 $(RESET_BAUDRATE) 0 201 "FLASH_ME"
	sleep 0.5
	stm32flash -w main.bin /dev/ttyUSB0 -b 115200

install_reset1: main.out
	SendDynamixelPacket /dev/ttyUSB1 $(RESET_BAUDRATE) 0 201 "FLASH_ME"
	sleep 0.5
	stm32flash -w main.bin /dev/ttyUSB1 -b 115200

install: main.out
	stm32flash -w main.bin /dev/ttyUSB0 -b 115200

