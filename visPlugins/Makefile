include $(MAGIC_DIR)/Makefile.mk

LIB_DIRS +=  -L$(VIS_DIR)/lib
CXXFLAGS = -O2 -Wall -fPIC -shared
LIBS += -lvis
INCLUDES += -I$(VIS_DIR)/include $(shell pkg-config --cflags OGRE) -include "Vis.hh"

OBJECTS = VehicleDynamics2D.o $(VIS_DIR)/plugins/so/Lidar2DVisual.so

TARGETS = MagicLidarScanPublisher.so MagicPlatformSim.so MagicLidarScan2VisLidarData.so

all: $(TARGETS)

%.so: %.cc $(OBJECTS)
	g++ -o $@ $^ $(INCLUDES) $(CXXFLAGS) $(LIB_DIRS) $(LIBS)

%.o: %.cc
	g++ -c -o $@ $^ $(INCLUDES) $(CXXFLAGS)

clean:
	rm -r *~ *.so

