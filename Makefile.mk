OSNAME = $(shell uname)

ifeq '$(OSNAME)' 'Linux'
  MAGIC_LINUX=1;
else
  MAGIC_OSX=1;
endif

MEXEXT = $(shell mexext)

MAGIC_LIB_DIR    = $(MAGIC_DIR)/lib
MAGIC_INCLUDE_DIR = $(MAGIC_DIR)/include

INCLUDES += $(shell xml2-config --cflags) -I$(MAGIC_INCLUDE_DIR)
LIB_DIRS += -L$(MAGIC_LIB_DIR) -L$(MAGIC_DIR)/ipc
LIBS     += -lpthread -lSerialDevice -ldb_cxx -lgz -lipc $(shell xml2-config --libs)

CPP_FLAGS += -g -O2 -Wall -fPIC

ifdef MAGIC_OSX
  ARCH = -arch i386
  CPP_FLAGS += $(ARCH)
endif

all: $(TARGETS)

%.o: %.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

%.o: %.c
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

%.o: %.cc 
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

clean:
	rm -rf *.o *~ $(TARGETS)
