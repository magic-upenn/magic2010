all : gethostname gettime array_match array_scale array_threshold subs_asgn subs_accum

gethostname: gethostname.c
	mex -O $<

gettime: gettime.cpp
	mex -O $<

array_match: array_match.cpp
	mex -O $<

array_scale: array_scale.cpp
	mex -O $<

array_threshold: array_threshold.cpp
	mex -O $<

subs_asgn: subs_asgn.cpp
	mex -O $<

subs_accum: subs_accum.cpp
	mex -O $<

clean:
	rm *.mex*

