MEXEXT=$(shell mexext)

all : gethostname.$(MEXEXT) gettime.$(MEXEXT) array_match.$(MEXEXT) array_scale.$(MEXEXT) array_threshold.$(MEXEXT) subs_asgn.$(MEXEXT) subs_accum.$(MEXEXT)

gethostname.$(MEXEXT): gethostname.c
	mex -O $<

gettime.$(MEXEXT): gettime.cpp
	mex -O $<

array_match.$(MEXEXT): array_match.cpp
	mex -O $<

array_scale.$(MEXEXT): array_scale.cpp
	mex -O $<

array_threshold.$(MEXEXT): array_threshold.cpp
	mex -O $<

subs_asgn.$(MEXEXT): subs_asgn.cpp
	mex -O $<

subs_accum.$(MEXEXT): subs_accum.cpp
	mex -O $<

clean:
	rm *.mex*

