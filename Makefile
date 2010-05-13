TARGETS = all

all: $(TARGETS)

all:
	cd common/dataTypes; cp *.h *.hh ../../include
	cd common/XMLConfig; make -j
	cd drivers; make
	cd matlab/mexTools; make
	cd matlab/serialization; make
	cd visPlugins; make -j

clean:
	rm -rf include/*.h include/*.hh
	rm -rf lib/*.a
	cd common/XMLConfig; make clean
	cd drivers; make clean
	cd matlab/mexTools; make clean
	cd matlab/serialization; make clean
	cd visPlugins; make clean
	rm -f *~

