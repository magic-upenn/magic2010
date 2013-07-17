MEXEXT=$(shell mexext)
MEX=mex

default_targets: ipcAPI.$(MEXEXT)

ipcAPI.$(MEXEXT): ipcAPI.cc
	$(MEX) -O ipcAPI.cc -L. -lipc

clean:
	rm -f *.mex* *~

