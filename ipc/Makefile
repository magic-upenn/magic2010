MEXEXT=$(shell mexext)
MEX=mex

default_targets: ipcAPI.$(MEXEXT) ipcWrapperAPI.$(MEXEXT)

ipcAPI.$(MEXEXT): ipcAPI.cc
	$(MEX) -O ipcAPI.cc -L. -lipc
	cp ipcAPI.$(MEXEXT) ipcAPI1.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI2.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI3.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI4.$(MEXEXT)

ipcWrapperAPI.$(MEXEXT): ipcWrapperAPI.cc IpcWrapper.cc
	$(MEX) -O $^ -I../include -L../lib -lSerialDevice -lipc
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI1.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI2.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI3.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI4.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPIVision.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPIMaster.$(MEXEXT)
clean:
	rm -f *.mex* *~
