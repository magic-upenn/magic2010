include $(MAGIC_DIR)/Makefile.mk

CFLAGS   = -Wall -fPIC

OBJFILES := $(patsubst %.cc,%.o,$(wildcard *.cc))

libgz.a: $(OBJFILES)
	ar -rcs $@ $^
	cp $@ $(MAGIC_LIB_DIR)
	cp *.hh $(MAGIC_INCLUDE_DIR)
	

all : libgz.a

%.o: %.cc
	g++ -c -o $@ $^ $(CFLAGS) $(INCLUDES)

clean:
	rm -f *~ *.o *.a
