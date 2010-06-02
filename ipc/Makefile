MEXEXT=$(shell mexext)
MEX=mex

default_targets: ipcAPI.$(MEXEXT)

ipcAPI.$(MEXEXT): ipcAPI.cc
	$(MEX) -O ipcAPI.cc -L. -lipc
	cp ipcAPI.$(MEXEXT) ipcAPI1.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI2.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI3.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI4.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI5.$(MEXEXT)

clean:
	rm -f *.mex* *~
