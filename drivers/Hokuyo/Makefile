OBJECTS  = Hokuyo.o HokuyoCircular.o HokuyoCircularHardware.o 
TARGETS = runHokuyo

include $(MAGIC_DIR)/Makefile.mk
CPP_FLAGS+=-DHOKUYO_LOW_LEVEL_DEBUG
runHokuyo: runHokuyo.cc $(OBJECTS)
	g++ $(INCLUDES) $(LIB_DIRS) $(CPP_FLAGS) -o $@ $^ $(LIBS)


