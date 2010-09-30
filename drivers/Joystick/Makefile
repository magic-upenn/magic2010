OBJECTS  = Xbee.o XbeeFrame.o ErrorMessage.o

TARGETS = JoystickLogitechX3dAPI.$(MEXEXT)

include $(MAGIC_DIR)/Makefile.mk

JoystickLogitechX3dAPI.$(MEXEXT) : JoystickLogitechX3dAPI.cc ErrorMessage.o Joystick.o
	mex -O $^ $(INCLUDES) $(LIB_DIRS) $(LIBS) -lpthread


ErrorMessage.o: ../../common/ErrorMessage.cc
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^
