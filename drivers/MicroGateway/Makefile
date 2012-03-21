OBJECTS  =  ErrorMessage.o DynamixelController.o

TARGETS = runMicroGateway2 runMicroGateway3 MicroConfig readIMU GetMicroId #runMicroGateway 

include $(MAGIC_DIR)/Makefile.mk

INCLUDES += -I$(VIS_DIR)/include
LIBS+= -lvis -lipc
LIB_DIRS+=-L$(VIS_DIR)/lib

#runMicroGateway: runMicroGateway.cc $(OBJECTS)
#	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

runMicroGateway2: runMicroGateway2.cc $(OBJECTS) MicroGateway2.o
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

runMicroGateway3: runMicroGateway3.cc $(OBJECTS) MicroGateway3.o
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

MicroConfig: MicroConfig.cc $(OBJECTS) MicroParams.o MicroGateway2.o
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

GetMicroId : GetMicroId.cc $(OBJECTS) MicroGateway2.o
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)


readIMU: readIMU.cc $(OBJECTS)
	g++ -Wall -o $@ $^ $(CPP_FLAGS) $(INCLUDES) $(LIB_DIRS) $(LIBS)

ErrorMessage.o: ../../common/ErrorMessage.cc
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

