all:
	mkdir -p include
	cd common/dataTypes; cp *.h *.hh ../../include
	cd common; cp *.hh ../include
	cd common/XMLConfig; make -j 4
	cd drivers; make
	cd components; make
	cd ipc; make
	cd matlab/mexTools; make
	cd utils; make
	cd matlab/serialization; make
	cd visPlugins; make -j 4

clean:
	rm -rf include/*.h include/*.hh
	rm -rf lib/*.a
	cd common/XMLConfig; make clean
	cd drivers; make clean
	cd components; make clean
	cd ipc; make clean
	cd matlab/mexTools; make clean
	cd utils; make clean
	cd matlab/serialization; make clean
	cd visPlugins; make clean
	rm -f *~

