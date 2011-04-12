TARGETS = map_accum.$(MEXEXT) map_filter.$(MEXEXT) map_assign.$(MEXEXT) \
	scan_correlation.cpp scan_icp.cpp

include $(MAGIC_DIR)/Makefile.mk

map_accum.$(MEXEXT) : map_accum.cpp
	mex -O $^

map_filter.$(MEXEXT) : map_filter.cpp
	mex -O $^

map_assign.$(MEXEXT) : map_assign.cpp
	mex -O $^

scan_correlation.$(MEXEXT) : scan_correlation.cpp
	mex -O $^

scan_icp.$(MEXEXT) : scan_icp.cpp
	mex -O $^
