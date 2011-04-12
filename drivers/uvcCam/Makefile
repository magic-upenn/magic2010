OBJECTS  = Xbee.o XbeeFrame.o ErrorMessage.o

TARGETS = uvcCam yuyv2rgbm #cjpeg djpeg

include $(MAGIC_DIR)/Makefile.mk


uvcCam: uvcCam.cpp v4l2.cpp
	mex -O $^

yuyv2rgbm: yuyv2rgbm.cc
	mex -O $^

cjpeg: cjpeg.cpp
	mex -O $^ -ljpeg

djpeg: djpeg.cpp
	mex -O $^ -ljpeg

