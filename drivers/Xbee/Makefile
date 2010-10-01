OBJECTS  = Xbee.o XbeeFrame.o ErrorMessage.o

TARGETS = testXbeeSend testXbeeReceive XbeeAPI.$(MEXEXT) UdpSendAPI.$(MEXEXT) UdpReceiveAPI.$(MEXEXT)

include $(MAGIC_DIR)/Makefile.mk

XbeeAPI.$(MEXEXT): XbeeAPI.cc Xbee.o XbeeFrame.o ErrorMessage.o
	mex -O $^ $(INCLUDES) $(LIB_DIRS) $(LIBS)

testXbeeSend: testXbeeSend.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

testXbeeReceive: testXbeeReceive.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

ErrorMessage.o: ../../common/ErrorMessage.cc
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^


UdpSendAPI.$(MEXEXT) : UdpSendAPI.cc
	mex -O $^

UdpReceiveAPI.$(MEXEXT) : UdpReceiveAPI.cc
	mex -O $^ -lpthread
