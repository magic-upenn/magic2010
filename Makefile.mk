MAGIC_LIB_DIR    = $(MAGIC_DIR)/lib
MAGIC_INCLUDE_DIR = $(MAGIC_DIR)/include

INCLUDES = -I/usr/local/BerkeleyDB.4.8/include -I../../include $(shell xml2-config --cflags) -I$(MAGIC_INCLUDE_DIR)
LIB_DIRS = -L$(MAGIC_LIB_DIR) -L/usr/local/BerkeleyDB.4.8/lib
LIBS     = -ldb_cxx -lipc -lpthread -lgz -lSerialDevice
