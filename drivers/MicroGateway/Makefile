OBJECTS  = MicroGateway.o ErrorMessage.o DynamixelController.o 

TARGETS = runMicroGateway readIMU

include $(MAGIC_DIR)/Makefile.mk

runMicroGateway: runMicroGateway.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPPFLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

readIMU: readIMU.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPPFLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

ErrorMessage.o: ../../common/ErrorMessage.cc
	g++ $(INCLUDES) $(CPPFLAGS) -c -o $@ $^

