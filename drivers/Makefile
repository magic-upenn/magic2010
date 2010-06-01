SUBDIRS = SerialDevice Hokuyo MicroGateway Logging

all:
	for i in $(SUBDIRS) ; do if (cd $$i && make -j 4); then :; else exit; fi ; done

clean:
	rm -f *~
	for i in $(SUBDIRS) ; do ( cd $$i ; make clean ) ; done


