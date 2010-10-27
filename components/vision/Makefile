# Makefile used to build mex files

TARGETS = all clean
.PHONY: $(TARGETS)

ifndef OSTYPE
  OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
  #export OSTYPE
endif

ifeq ($(OSTYPE),linux)
  MEXSUFFIX = mexglx
endif
ifeq ($(OSTYPE),darwin)
  MEXSUFFIX = mexmaci
endif

MEX = mex
CXXFLAGS = -O 

all: cjpeg djpeg connected_regions

uvcCam: uvcCam.cpp v4l2.cpp
	$(MEX) $(CXXFLAGS) $^

cjpeg: cjpeg.cpp
	$(MEX) $(CXXFLAGS) $^ -ljpeg

djpeg: djpeg.cpp
	$(MEX) $(CXXFLAGS) $^ -ljpeg

connected_regions: connected_regions.cc RegionProps.o ConnectRegions.o
	$(MEX) $(CXXFALGS) $^ 

clean:
	rm -f *.$(MEXSUFFIX) *.o
