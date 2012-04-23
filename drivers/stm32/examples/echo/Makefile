KQUAD_ROOT_PATH = ../../..
STM32_ROOT_PATH = $(KQUAD_ROOT_PATH)/stm32

RESET_BAUDRATE = 115200
STM32_DEVICE_TYPE = -DSTM32F10X_HD

include ../../common.mk

STM32_OBJECTS = main.o interrupts.o system_stm32f10x.o startup_stm32f10x_md.o uart1.o uart2.o uart3.o systick.o kBotPacket.o

main.out: $(STM32_OBJECTS)
	$(STM32_LD) $(STM32_LFLAGS) -o $@ $^ $(STM32_LIBS)
	$(STM32_CP) $(STM32_CPFLAGS) main.out main.bin
	$(STM32_OD) $(STM32_ODFLAGS) main.out > main.list

clean:
	rm -f $(STM32_OBJECTS) main.out main.bin main.list *.o

