INCLUDES = -I/usr/local/BerkeleyDB.4.8/include -I../../include $(shell xml2-config --cflags)

OBJFILES  = Hokuyo.o HokuyoCircular.o HokuyoCircularHardware.o 

LIB_DIR = ../../lib
HEADER_DIR = ../../include
LIB_DIRS = -L$(LIB_DIR)
LIBS = -ldb_cxx -lipc -lpthread -lgz -lSerialDevice

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

