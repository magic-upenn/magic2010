TARGETS = copyHeaders

all: $(TARGETS)

copyHeaders:
	cd common/dataTypes; cp *.h *.hh ../../include
	cd common/XMLConfig; make
	cd drivers; make

clean:
	rm -rf include/*.h include/*.hh
	rm -rf lib/*.a
	cd common/XMLConfig; make clean
	cd drivers; make clean

