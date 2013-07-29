INCS := `pkg-config --cflags opencv` -I$(MAGIC_DIR)/ipc
LIBS := -L$(MAGIC_DIR)/ipc -ljpeg -pthread `pkg-config --libs opencv`

APRIL_PATH := ${MAGIC_DIR}/drivers/Vision/apriltags/build/lib/pkgconfig

C_FLAGS := -g -O0  -Wall
CXX_FLAGS := -g -O0 -Wall `PKG_CONFIG_PATH=${APRIL_PATH} pkg-config --cflags apriltags`
LD_FLAGS := `PKG_CONFIG_PATH=${APRIL_PATH} pkg-config --libs apriltags` `pkg-config --libs opencv` -lipc 
SOURCES=receive_data quadDataPublish apriltags

all: $(SOURCES) 

apriltags: apriltags.cpp imgproc.o
	$(CXX) $(CXX_FLAGS) $(INCS) $^ $(LIBS) $(LD_FLAGS) -o $@

receive_data: receive_data.o udp.o jpeg_decompress.o imgproc.o
	$(CXX) $(CXX_FLAGS) $(INCS) $^ $(LIBS) $(LD_FLAGS) -o $@

quadDataPublish: quadDataPublish.o udp.o jpeg_decompress.o imgproc.o
	$(CXX) $(CXX_FLAGS) $(INCS) $^ $(LIBS) $(LD_FLAGS) -o $@

%.o: %.cpp
	$(CXX) $(CXX_FLAGS) $(INCS) -c $^

%.o: %.cc
	$(CXX) $(CXX_FLAGS) $(INCS) -c $^

%.o: %.c
	$(CC) $(C_FLAGS) $(INCS) -c $^

clean:
	rm -f *.o $(SOURCES)