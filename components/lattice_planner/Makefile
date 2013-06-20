OBJECTS  = envMagic.o mapConverter.o 
TARGETS = lattice_planner_mex
MEXEXT = $(shell mexext)
include $(MAGIC_DIR)/Makefile.mk
LIBS += -lsbpl

lattice_planner: main.cpp $(OBJECTS)
	g++ $(INCLUDES) $(LIB_DIRS) $(CPP_FLAGS) -o $@ $^ $(LIBS)

lattice_planner_mex.$(MEXEXT): lattice_planner_mex.cpp
	mex $^ *.o -I. -L. -L../../lib -lsbpl