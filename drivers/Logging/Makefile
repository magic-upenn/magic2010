OBJECTS  = 
TARGETS = logIpcDB playIpcDB
LIBS = $(shell xml2-config --libs)

include $(MAGIC_DIR)/Makefile.mk

logIpcDB: logIpcDB.cc $(OBJECTS)
	g++ $(INCLUDES) $(LIB_DIRS) $(CPP_FLAGS) -o $@ $^ $(LIBS)

playIpcDB: playIpcDB.cc $(OBJECTS)
	g++ $(INCLUDES) $(LIB_DIRS) $(CPP_FLAGS) -o $@ $^ $(LIBS)

