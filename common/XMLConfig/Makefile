OBJECTS := $(patsubst %.cc,%.o,$(wildcard *.cc))
TARGETS = libgz.a
include $(MAGIC_DIR)/Makefile.mk

libgz.a: $(OBJECTS)
	ar -rcs $@ $^
	cp $@ $(MAGIC_LIB_DIR)
	cp *.hh $(MAGIC_INCLUDE_DIR)
	