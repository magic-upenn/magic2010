INCS := `pkg-config --cflags opencv`
LIBS := -ljpeg -pthread `pkg-config --libs opencv`

C_FLAGS := -O3 -Wall
CXX_FLAGS := -O3 -Wall
LD_FLAGS :=

all: receive_data

receive_data: receive_data.o udp.o jpeg_decompress.o imgproc.o
	$(CXX) $(CXX_FLAGS) $(INCS) $^ $(LIBS) $(LD_FLAGS) -o $@

%.o: %.cpp
	$(CXX) $(CXX_FLAGS) $(INCS) -c $^

%.o: %.cc
	$(CXX) $(CXX_FLAGS) $(INCS) -c $^

%.o: %.c
	$(CC) $(C_FLAGS) $(INCS) -c $^

clean:
	rm -f *.o receive_data
