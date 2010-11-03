OBJECTS = 
TARGETS = defineSensorMessages
LIBS    = 

include $(MAGIC_DIR)/Makefile.mk

defineSensorMessages: defineSensorMessages.cc $(OBJECTS)
	g++ $(INCLUDES) $(LIB_DIRS) $(CPP_FLAGS) -o $@ $^ $(LIBS)