CXX=/usr/bin/g++
CC=/usr/bin/gcc
LD=/usr/bin/g++
STRIP=/usr/bin/strip
MEX=/usr/local/bin/mex

LIBS=	-lm

CXXFLAGS= \
	-O2 \
	-I/usr/local/include \
	-Wall

.PHONY: all install clean

all: libdc1394 triclopsAPI

%.o: %.cc
	$(CXX) $(CXXFLAGS) -o $@ -c $<

%.o: %.c
	$(CC) $(CXXFLAGS) -o $@ -c $<

libdc1394: libdc1394.cc
	$(MEX) -O libdc1394.cc -I/usr/local/include -ldc1394

triclopsAPI: triclopsAPI.cc
	$(MEX) -O triclopsAPI.cc -I/usr/local/include -ltriclops -lpnmutils

clean:
	rm -f *.o
	rm -f *.so
	rm -f main

