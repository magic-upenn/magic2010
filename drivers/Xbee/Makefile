OBJECTS  = Xbee.o XbeeFrame.o ErrorMessage.o

TARGETS = testXbeeSend testXbeeReceive XbeeAPI.$(MEXEXT) JoystickLogitechX3dAPI.$(MEXEXT)

include $(MAGIC_DIR)/Makefile.mk

JoystickLogitechX3dAPI.$(MEXEXT) : JoystickLogitechX3dAPI.cc ErrorMessage.o Joystick.o
	mex -O $^ $(INCLUDES) $(LIB_DIRS) $(LIBS) -lpthread

XbeeAPI.$(MEXEXT): XbeeAPI.cc Xbee.o XbeeFrame.o ErrorMessage.o
	mex -O $^ $(INCLUDES) $(LIB_DIRS) $(LIBS)

testXbeeSend: testXbeeSend.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

testXbeeReceive: testXbeeReceive.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

ErrorMessage.o: ../../common/ErrorMessage.cc
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^
