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

all: uvcCam

uvcCam: uvcCam.cpp v4l2.cpp
	$(MEX) $(CXXFLAGS) $^

clean:
	rm -f *.$(MEXSUFFIX) *.o
