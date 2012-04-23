CC      = arm-none-eabi-gcc
LD      = arm-none-eabi-ld -v
AR      = arm-none-eabi-ar
AS      = arm-none-eabi-as
CP      = arm-none-eabi-objcopy
OD		  = arm-none-eabi-objdump
  
CFLAGS  =  -I../include -c -fno-common -O3 -mcpu=cortex-m3 -mthumb 
DEFINES = -DUSE_STDPERIPH_DRIVER -DSTM32F10X_MD -DHSE_VALUE=16000000 #medium density device

OBJECTS = core_cm3.o misc.o stm32f10x_adc.o stm32f10x_bkp.o stm32f10x_can.o stm32f10x_cec.o \
          stm32f10x_crc.o stm32f10x_dac.o stm32f10x_dbgmcu.o stm32f10x_dma.o stm32f10x_exti.o \
          stm32f10x_flash.o stm32f10x_fsmc.o stm32f10x_gpio.o stm32f10x_i2c.o stm32f10x_iwdg.o \
          stm32f10x_pwr.o stm32f10x_rcc.o stm32f10x_rtc.o stm32f10x_sdio.o stm32f10x_spi.o \
          stm32f10x_tim.o stm32f10x_usart.o stm32f10x_wwdg.o system_stm32f10x.o

libstm32f10x.a : $(OBJECTS)
	$(AR) -rcs $@ $^
	cp $@ ../lib/

clean:
	rm -f $(OBJECTS)

%.o: %.c
	$(CC) $(CFLAGS) $(DEFINES) -o $@ $^

