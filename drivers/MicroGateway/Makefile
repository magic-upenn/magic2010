OBJECTS  = MicroGateway2.o ErrorMessage.o DynamixelController.o 

TARGETS = runMicroGateway2 #runMicroGateway readIMU

include $(MAGIC_DIR)/Makefile.mk

#runMicroGateway: runMicroGateway.cc $(OBJECTS)
#	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

runMicroGateway2: runMicroGateway2.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)


readIMU: readIMU.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

ErrorMessage.o: ../../common/ErrorMessage.cc
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

