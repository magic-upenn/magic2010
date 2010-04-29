OSNAME = $(shell uname)

ifeq '$(OSNAME)' 'Linux'
  MAGIC_LINUX=1;
else
  MAGIC_OSX=1;
endif

MAGIC_LIB_DIR    = $(MAGIC_DIR)/lib
MAGIC_INCLUDE_DIR = $(MAGIC_DIR)/include

INCLUDES += -I/usr/local/BerkeleyDB.4.8/include -I../../include $(shell xml2-config --cflags) -I$(MAGIC_INCLUDE_DIR)
LIB_DIRS += -L$(MAGIC_LIB_DIR) -L/usr/local/BerkeleyDB.4.8/lib
LIBS     += -ldb_cxx -lpthread -lgz -lSerialDevice -lipc

ifdef MAGIC_OSX
  ARCH = -arch i386
endif

CPPFLAGS += -O2 -Wall -fPIC $(ARCH)

all: $(TARGETS)

%.o: %.cpp
	g++ $(INCLUDES) $(CPPFLAGS) -c -o $@ $^

%.o: %.c
	g++ $(INCLUDES) $(CPPFLAGS) -c -o $@ $^

%.o: %.cc 
	g++ $(INCLUDES) $(CPPFLAGS) -c -o $@ $^

clean:
	rm -rf *.o *~ $(TARGETS)
