MEXEXT=$(shell mexext)
MEX=mex

TARGETS=ipcAPI.$(MEXEXT) ipcWrapperAPI.$(MEXEXT)

include $(MAGIC_DIR)/Makefile.mk

default_targets: $(TARGETS)

ipcAPI.$(MEXEXT): ipcAPI.cc
	$(MEX) -O ipcAPI.cc -L. -lipc
	cp ipcAPI.$(MEXEXT) ipcAPI1.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI2.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI3.$(MEXEXT)
	cp ipcAPI.$(MEXEXT) ipcAPI4.$(MEXEXT)

ipcWrapperAPI.$(MEXEXT): ipcWrapperAPI.cc IpcWrapper.cc
	$(MEX) -O $^ -I../include -L. -L../lib -lSerialDevice -lipc #-lipc_nokill
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI1.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI2.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI3.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI4.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI5.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI6.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI7.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI8.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI9.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPI10.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPIVision.$(MEXEXT)
	cp ipcWrapperAPI.$(MEXEXT) ipcWrapperAPIMaster.$(MEXEXT)
clean:
	rm -f *.mex* *~
