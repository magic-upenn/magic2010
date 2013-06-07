all : gethostname gettime array_match array_scale array_threshold subs_asgn subs_accum
MEXEXT=$(shell mexext)
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

