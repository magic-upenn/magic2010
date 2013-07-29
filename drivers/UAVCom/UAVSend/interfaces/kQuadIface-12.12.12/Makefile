LIBS+= -lpthread
OBJECTS += kQuadInterface.o SerialDevice.o kBotPacket2.o crc32.o kBotPacketParser.o kQuadInterfaceDataTypes.o

include ../../common.mk

TARGETS : testSendQuadCmd1 testSendQuadCmd2 testSendQuadCmd3 testSendQuadCmd4 testReceiveFeedback kQuadInterfaceAPI.$(MEXEXT) 

kQuadInterfaceAPI.$(MEXEXT) : kQuadInterfaceAPI.cc $(OBJECTS)
	mex -O $^ $(LIBS) $(INCLUDES)

testSendQuadCmd1 : testSendQuadCmd1.cc $(OBJECTS)
	g++ -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIBS)

testSendQuadCmd2 : testSendQuadCmd2.cc $(OBJECTS)
	g++ -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIBS)

testSendQuadCmd3 : testSendQuadCmd3.cc $(OBJECTS)
	g++ -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIBS)

testSendQuadCmd4 : testSendQuadCmd4.cc $(OBJECTS)
	g++ -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIBS)

testReceiveFeedback : testReceiveFeedback.cc $(OBJECTS)
	g++ -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIBS)

clean:
	rm -rf *.o *~ *.$(MEXEXT) testSendQuadCmd1 testSendQuadCmd2 testSendQuadCmd3 testSendQuadCmd4 testReceiveFeedback
