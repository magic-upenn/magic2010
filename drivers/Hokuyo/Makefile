include $(MAGIC_DIR)/Makefile.mk
OBJFILES  = Hokuyo.o HokuyoCircular.o HokuyoCircularHardware.o 

TARGETS = runHokuyo

all: $(TARGETS)

runHokuyo: runHokuyo.cc $(OBJFILES)
	g++ -O2 -Wall -o $@ $^ $(INCLUDES) $(LIB_DIRS) $(LIBS)


%.o: %.cpp
	g++ -O2 -Wall -c -o $@ $^ -fPIC $(INCLUDES)

%.o: %.c
	g++ -O2 -Wall -c -o $@ $^ -fPIC $(INCLUDES)

%.o: %.cc 
	g++ -O2 -Wall -c -o $@ $^ -fPIC $(INCLUDES)

clean:
	rm -rf *.o *~ $(TARGETS)

