include $(MAGIC_DIR)/Makefile.mk

OBJFILES  = ErrorMessage.o CircularBuffer.o DataLogger.o DeviceInterface.o \
		DataPlayback.o DataPlaybackDB.o IpcLoggerDB.o PointerQueueBuffer.o \
		DataLoggerQueue.o DbWrite.o DataLoggerQueueDB.o IpcHelper.o \
		SerialDevice.o IpcWrapper.o 

TARGETS = libSerialDevice.a

all: $(TARGETS)

libSerialDevice.a: $(OBJFILES)
	ar -rcs $@ $^
	cp $@ $(MAGIC_LIB_DIR)
	cp *.hh $(MAGIC_INCLUDE_DIR)


%.o: %.cpp
	g++ -O2 -Wall -c -o $@ $^ -fPIC $(INCLUDES)

%.o: %.c
	g++ -O2 -Wall -c -o $@ $^ -fPIC $(INCLUDES)

%.o: %.cc 
	g++ -O2 -Wall -c -o $@ $^ -fPIC $(INCLUDES)

clean:
	rm -rf *.o *~ $(TARGETS)

