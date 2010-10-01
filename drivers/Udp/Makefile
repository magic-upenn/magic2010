OBJECTS  = Xbee.o XbeeFrame.o ErrorMessage.o

TARGETS = UdpSendAPI.$(MEXEXT) UdpReceiveAPI.$(MEXEXT)

include $(MAGIC_DIR)/Makefile.mk

UdpSendAPI.$(MEXEXT) : UdpSendAPI.cc
	mex -O $^

UdpReceiveAPI.$(MEXEXT) : UdpReceiveAPI.cc
	mex -O $^ -lpthread

