INCLUDES = -I/usr/local/BerkeleyDB.4.8/include -I../../include $(shell xml2-config --cflags)

OBJFILES  = ErrorMessage.o CircularBuffer.o DataLogger.o DeviceInterface.o \
		DataPlayback.o DataPlaybackDB.o IpcLoggerDB.o PointerQueueBuffer.o \
		DataLoggerQueue.o DbWrite.o DataLoggerQueueDB.o IpcHelper.o \
		SerialDevice.o IpcWrapper.o 

LIB_DIR = ../../lib
HEADER_DIR = ../../include

TARGETS = libSerialDevice.a

all: $(TARGETS)

libSerialDevice.a: $(OBJFILES)
	ar -rcs $@ $^
	cp $@ $(LIB_DIR)
	cp *.hh $(HEADER_DIR)


%.o: %.cpp
	g++ -O2 -Wall -c -o $@ $^ -fPIC $(INCLUDES)

%.o: %.c
	g++ -O2 -Wall -c -o $@ $^ -fPIC $(INCLUDES)

%.o: %.cc 
	g++ -O2 -Wall -c -o $@ $^ -fPIC $(INCLUDES)

clean:
	rm -rf *.o *~ $(TARGETS)

