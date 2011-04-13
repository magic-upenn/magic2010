ifndef MATLAB_DIR
	MATLAB_DIR=/opt/matlab
endif

MEX=$(MATLAB_DIR)/bin/mex
MEXSUFFIX=$(shell $(MATLAB_DIR)/bin/mexext)
MEXFLAGS = -I$(MATLAB_DIR)/extern/include


INCLUDES = -I.

default_targets: serialDeviceAPI.$(MEXSUFFIX)

testSerialDevice: testSerialDevice.cc SerialDevice.o
	g++ -O2 -Wall testSerialDevice.cc SerialDevice.o -o testSerialDevice $(INCLUDES)

SerialDevice.o : SerialDevice.cc
	g++ -O2 -Wall SerialDevice.cc -c -DSERIAL_DEVICE_DEBUG -fPIC $(INCLUDES)


serialDeviceAPI.$(MEXSUFFIX) : SerialDevice.o serialDeviceAPI.cc
	$(MEX) -O serialDeviceAPI.cc SerialDevice.o $(MEXFLAGS) $(INCLUDES)

clean :
	rm -rf testSerialDevice *.o *.mex*

