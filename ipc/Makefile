MEXEXT=$(shell mexext)
MEX=mex

default_targets: ipcAPI.$(MEXEXT) ipcWrapperAPI.$(MEXEXT)

ipcAPI.$(MEXEXT): ipcAPI.cc
	$(MEX) -O ipcAPI.cc -L. -lipc
	cp ipcAPI.$(MEXEXT) ipcAPI1.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI2.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI3.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI4.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI5.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI6.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI7.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI8.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI9.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI10.$(MEXEXT)

ipcWrapperAPI.$(MEXEXT): ipcWrapperAPI.cc IpcWrapper.cc
	$(MEX) -O $^ -I../include -L../lib -lSerialDevice -lipc
clean:
	rm -f *.mex* *~
