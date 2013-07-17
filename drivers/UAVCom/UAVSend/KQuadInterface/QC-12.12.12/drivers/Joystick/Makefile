
TARGETS: KillSwitch
OBJECTS = Joystick.o SerialDevice.o

include ../../common.mk

LIBS += -lpthread -lipc

KillSwitch : KillSwitch.cc  $(OBJECTS)
	g++ $(CPP_FLAGS)  $(INCLUDES) -o $@ $^ $(LIBS)


clean:
	rm -rf *~ *.o KillSwitch

