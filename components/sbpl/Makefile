SUBDIRS = cmake_build

all:
	for i in $(SUBDIRS) ; do if (cd $$i && make); then :; else exit; fi ; done

clean:
	rm -f *~
	for i in $(SUBDIRS) ; do ( cd $$i ; make clean ) ; done


