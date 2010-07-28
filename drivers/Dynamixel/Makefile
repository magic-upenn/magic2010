MEX_EXT = $(shell mexext)

OBJECTS  = Dynamixel.o #ErrorMessage.o SerialDevice.o 
TARGETS = dynamixelAPI.$(MEX_EXT) dynamixelAPI_1.$(MEX_EXT) dynamixelAPI_2.$(MEX_EXT)

include $(MAGIC_DIR)/Makefile.mk



%.$(MEX_EXT) : dynamixelAPI.cc $(OBJECTS)
	mex $^ $(INCLUDES) $(LIB_DIRS) $(LIBS) -o $@

