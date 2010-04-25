INCLUDES = $(shell xml2-config --cflags)
CFLAGS   = -Wall -fPIC
LIB_DIR = ../../lib
HEADER_DIR = ../../include

OBJFILES := $(patsubst %.cc,%.o,$(wildcard *.cc))

libgz.a: $(OBJFILES)
	ar -rcs $@ $^
	cp $@ $(LIB_DIR)
	cp *.hh $(HEADER_DIR)
	

all : libgz.a

%.o: %.cc
	g++ -c -o $@ $^ $(CFLAGS) $(INCLUDES)

clean:
	rm -f *~ *.o *.a
