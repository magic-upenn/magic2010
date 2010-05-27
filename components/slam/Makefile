MEX_EXT = $(shell mexext)

TARGETS = ScanMatch2D.$(MEX_EXT) getMapCellsFromRay.$(MEX_EXT)

all: $(TARGETS)

ScanMatch2D.$(MEX_EXT): ScanMatch2D.cc
	mex -O $^

getMapCellsFromRay.$(MEX_EXT): getMapCellsFromRay.cpp
	mex -O $^


clean:
	rm -rf $(TARGETS) *~
	
