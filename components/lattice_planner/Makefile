OBJECTS  = envMagic.o mapConverter.o 
TARGETS = lattice_planner

include $(MAGIC_DIR)/Makefile.mk
LIBS += -lsbpl

lattice_planner: main.cpp $(OBJECTS)
	g++ $(INCLUDES) $(LIB_DIRS) $(CPPFLAGS) -o $@ $^ $(LIBS)

