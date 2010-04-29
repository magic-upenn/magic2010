OBJECTS  = ErrorMessage.o CircularBuffer.o DataLogger.o DeviceInterface.o \
		DataPlayback.o DataPlaybackDB.o IpcLoggerDB.o PointerQueueBuffer.o \
		DataLoggerQueue.o DbWrite.o DataLoggerQueueDB.o IpcHelper.o \
		SerialDevice.o IpcWrapper.o 

TARGETS = libSerialDevice.a

include $(MAGIC_DIR)/Makefile.mk

libSerialDevice.a: $(OBJECTS)
	ar -rcs $@ $^
	cp $@ $(MAGIC_LIB_DIR)
	cp *.hh $(MAGIC_INCLUDE_DIR)




