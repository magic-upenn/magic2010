MEXEXT = $(shell mexext)

TARGETS = getch.$(MEXEXT) serialize.$(MEXEXT) deserialize.$(MEXEXT) GetUnixTime.$(MEXEXT) nmeaChecksum.$(MEXEXT) zlibCompress.$(MEXEXT) zlibUncompress.$(MEXEXT)

all: $(TARGETS)


%.$(MEXEXT): %.c
	mex -O $^

%.$(MEXEXT): %.cc
	mex -O $^ -lz

clean:
	rm -f $(TARGETS)
