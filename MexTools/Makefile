MEXEXT = $(shell mexext)

TARGETS = getch.$(MEXEXT) serialize.$(MEXEXT) deserialize.$(MEXEXT) GetUnixTime.$(MEXEXT)

all: $(TARGETS)


%.$(MEXEXT): %.c
	mex -O $^

%.$(MEXEXT): %.cc
	mex -O $^

clean:
	rm -r $(TARGETS)
