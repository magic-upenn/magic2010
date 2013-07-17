MEXEXT = $(shell mexext)

TARGETS : usleep.$(MEXEXT) GetUnixTime.$(MEXEXT) \
          serialize.$(MEXEXT) deserialize.$(MEXEXT)

include ../../common.mk

%.$(MEXEXT): %.cc
	mex -O $^

%.$(MEXEXT): %.c
	mex -O $^

%.$(MEXEXT): %.cpp
	mex -O $^

clean:
	rm -f  *~ *.o *.mex*

