OBJECTS  = Dynamixel.o #ErrorMessage.o SerialDevice.o 
TARGETS = dynamixelAPI

include $(MAGIC_DIR)/Makefile.mk

dynamixelAPI : dynamixelAPI.cc $(OBJECTS)
	mex $^ $(INCLUDES) $(LIB_DIRS) $(LIBS)

