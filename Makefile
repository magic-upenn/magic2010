TARGETS = copyHeaders

all: $(TARGETS)

copyHeaders:
	cd common/dataTypes; cp *.h *.hh ../../include
	cd common/XMLConfig; make
	cd drivers; make
	cd mexTools; make
	cd matlab/serialization; make

clean:
	rm -rf include/*.h include/*.hh
	rm -rf lib/*.a
	cd common/XMLConfig; make clean
	cd drivers; make clean
	cd mexTools; make clean
	cd matlab/serialization; make

