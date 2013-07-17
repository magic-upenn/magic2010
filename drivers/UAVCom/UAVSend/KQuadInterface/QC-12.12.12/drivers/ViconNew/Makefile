INCLUDES  = -I.
CPP_FLAGS = -O2 -fPIC -Wall
LIBS      = -lViconDataStreamSDK_CPP

all: testViconDriver2 ViconAPI2

testViconDriver2: testViconDriver2.cc ViconDriver2.cc 
	g++ -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIBS)

%.o: %.cc
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

%.o: %.cpp
	g++ -c -o $@ $^ $(CPP_FLAGS) $(INCLUDES)

ViconAPI2: ViconAPI2.cc ViconDriver2.cc
	mex -O $^ $(INCLUDES) $(LIBS)

clean:
	rm -rf *~ testViconDriver2 *.mex*

