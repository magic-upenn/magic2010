#! /bin/make include file
# -*- sh -*-
# global configuration settings for all impact Makefiles

## defaults

ifeq ($(TARGET),)
	TARGET=ppc603e
endif

##--- (cross/native) compiler homes -----------------------------

GCC_$(HOSTTYPE)Xarm = /usr/local/angstrom/arm

###
