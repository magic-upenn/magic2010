
TARGETS : SendKBotPacket2 SerialTerm

include ../common.mk
LIBS += -lpthread

SerialTerm : SerialTerm.cc SerialDevice.o
	g++ -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIBS)


SendKBotPacket2 : SendKBotPacket2.cc kBotPacket2.o SerialDevice.o crc32.o
	g++ -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIBS)


%.o: %.cpp
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

%.o: %.c
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

%.o: %.cc 
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)


clean:
	rm -rf *.o *~ SendKBotPacket2 SerialTerm

