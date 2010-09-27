OBJECTS  = Xbee.o XbeeFrame.o ErrorMessage.o

TARGETS = testXbeeSend testXbeeReceive

include $(MAGIC_DIR)/Makefile.mk

testXbeeSend: testXbeeSend.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

testXbeeReceive: testXbeeReceive.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

ErrorMessage.o: ../../common/ErrorMessage.cc
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^
