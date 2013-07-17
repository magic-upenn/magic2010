#! /bin/make
# -*- sh -*-
OSTYPE := $(shell uname | cut -d _ -f 1 | tr [:upper:] [:lower:])
HOSTTYPE := $(shell uname -m)

#-------------------------------------------
ifeq ($(HOSTTYPE),i686)
	NATIVE=x86
else
	NATIVE=$(HOSTTYPE)
	ifeq ($(NATIVE),x86_64)
		EXTRA_TARGET=x86
	endif
	ifeq ($(NATIVE),ppc64)
		EXTRA_TARGET=ppc
	endif
endif

SUBDIRS = $(NATIVE) ppc_6xx arm $(EXTRA_TARGET) armv7a

#-------------------------------------------
.PHONY:
	$(SUBDIRS) all build new info ipk clean armv7a

#-------------------------------------------
all info ipk:
	@for dir in $(SUBDIRS) ; do mkdir -p $$dir ; $(MAKE) -C $$dir -f ../Makefile.inc $@ || exit $$?; done

#-------------------------------------------
native:
	@mkdir -p $(NATIVE)
	$(MAKE) -C $(NATIVE) -f ../Makefile.inc all || exit $$?

#-------------------------------------------
ppc ppc_6xx x86 x86_64 arm armv7a:
	@mkdir -p $@
	$(MAKE) -C $@ -f ../Makefile.inc all || exit $$?

#-------------------------------------------
clean:
	@rm -rf $(SUBDIRS)

#-------------------------------------------
build new: clean
	@for dir in $(SUBDIRS) ; do mkdir -p $$dir; $(MAKE) -C $$dir -f ../Makefile.inc $@ || exit $$?; done

#-------------------------------------------
strip:
	@for dir in $(SUBDIRS);										\
	do															\
		if test -d $$dir;										\
		then													\
			$(MAKE) -C $$dir -f ../Makefile.inc $@ || exit $$?;	\
		fi;														\
	done
