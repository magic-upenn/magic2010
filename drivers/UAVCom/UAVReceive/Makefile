INCS := `pkg-config --cflags opencv` -I$(MAGIC_DIR)/ipc
LIBS := -L$(MAGIC_DIR)/ipc -ljpeg -pthread `pkg-config --libs opencv`

APRIL_PATH := ${MAGIC_DIR}/drivers/Vision/apriltags/build/lib/pkgconfig

C_FLAGS := -O3 -Wall
CXX_FLAGS := -O3 -Wall `PKG_CONFIG_PATH=${APRIL_PATH} pkg-config --cflags apriltags`
LD_FLAGS := `PKG_CONFIG_PATH=${APRIL_PATH} pkg-config --libs apriltags` `pkg-config --libs opencv` -lipc 
SOURCES=receive_data apriltagDetect

all: $(SOURCES) 

receive_data: receive_data.o udp.o jpeg_decompress.o imgproc.o
	$(CXX) $(CXX_FLAGS) $(INCS) $^ $(LIBS) $(LD_FLAGS) -o $@

apriltagDetect: apriltagDetect.o udp.o jpeg_decompress.o imgproc.o
	$(CXX) $(CXX_FLAGS) $(INCS) $^ $(LIBS) $(LD_FLAGS) -o $@

%.o: %.cpp
	$(CXX) $(CXX_FLAGS) $(INCS) -c $^

%.o: %.cc
	$(CXX) $(CXX_FLAGS) $(INCS) -c $^

%.o: %.c
	$(CC) $(C_FLAGS) $(INCS) -c $^

clean:
	rm -f *.o receive_data
