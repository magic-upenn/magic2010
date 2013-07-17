OSNAME = $(shell uname)

ifeq '$(OSNAME)' 'Linux'
  LINUX=1;
else
  OSX=1;
endif
#QC_ROOT_PATH = $(shell pwd)

MEXEXT = $(shell mexext)
INCLUDES += -I$(QC_ROOT_PATH)/include
CPP_FLAGS = -O2 -fPIC -Wall

ifdef OSX
#CPP_FLAGS += -arch i386
endif

all : TARGETS

%.o: %.cc
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

DynamixelPacket.o : $(QC_ROOT_PATH)/src/DynamixelPacket.c
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

kBotPacket.o : $(QC_ROOT_PATH)/src/kBotPacket.c
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

kBotPacket2.o : $(QC_ROOT_PATH)/src/kBotPacket2.c
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

crc32.o : $(QC_ROOT_PATH)/src/crc32.c
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

SerialDevice.o : $(QC_ROOT_PATH)/src/SerialDevice.cc
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

SerialDeviceReader.o : $(QC_ROOT_PATH)/src/SerialDeviceReader.cc
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

clean:
	rm -rf *.o *~


