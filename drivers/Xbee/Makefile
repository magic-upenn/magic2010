OBJECTS  = Xbee.o XbeeFrame.o ErrorMessage.o

TARGETS = fakeEstop testXbeeSend testXbeeReceive XbeeAPI.$(MEXEXT) uvcCam cjpeg djpeg

include $(MAGIC_DIR)/Makefile.mk

fakeEstop: fakeEstop.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

XbeeAPI.$(MEXEXT): XbeeAPI.cc Xbee.o XbeeFrame.o ErrorMessage.o
	mex -O $^ $(INCLUDES) $(LIB_DIRS) $(LIBS)

testXbeeSend: testXbeeSend.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

testXbeeReceive: testXbeeReceive.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

ErrorMessage.o: ../../common/ErrorMessage.cc
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

uvcCam: uvcCam.cpp v4l2.cpp
	mex -O $^

cjpeg: cjpeg.cpp
	mex -O $^ -ljpeg

djpeg: djpeg.cpp
	mex -O $^ -ljpeg

