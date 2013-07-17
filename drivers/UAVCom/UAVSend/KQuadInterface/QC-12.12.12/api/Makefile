MEX_EXT = $(shell mexext)
include ../common.mk

TARGETS : kBotPacket2API.$(MEX_EXT) SerialDeviceAPI.$(MEXSUFFIX)

kBotPacket2API.$(MEX_EXT) : kBotPacket2API.cc kBotPacket2.o crc32.o 
	mex $^ -o $@ $(INCLUDES)

SerialDeviceAPI.$(MEXSUFFIX) : SerialDevice.o SerialDeviceAPI.cc
	mex -O SerialDeviceAPI.cc SerialDevice.o  $(INCLUDES)

clean:
	rm -rf *~ *.o *.$(MEX_EXT)

