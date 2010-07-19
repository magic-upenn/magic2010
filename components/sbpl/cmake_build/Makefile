OBJECTS  = environment_nav2D.o environment_navxythetalat.o environment_nav2Duu.o environment_XXX.o \
           environment_robarm.o araplanner.o adplanner.o viplanner.o ppcpplanner.o rstarplanner.o \
           heap.o mdp.o utils.o 2Dgridsearch.o

TARGETS = libsbpl.a

include $(MAGIC_DIR)/Makefile.mk

libsbpl.a: $(OBJECTS)
	ar -rcs $@ $^
	cp $@ $(MAGIC_LIB_DIR)
	cp ../src/sbpl/headers.h $(MAGIC_INCLUDE_DIR)

environment_nav2D.o: ../src/discrete_space_information/nav2d/environment_nav2D.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

environment_navxythetalat.o: ../src/discrete_space_information/navxythetalat/environment_navxythetalat.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

environment_nav2Duu.o: ../src/discrete_space_information/nav2d_uu/environment_nav2Duu.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

environment_XXX.o: ../src/discrete_space_information/template/environment_XXX.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

environment_robarm.o: ../src/discrete_space_information/robarm/environment_robarm.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

araplanner.o: ../src/planners/ARAStar/araplanner.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

adplanner.o: ../src/planners/ADStar/adplanner.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

viplanner.o: ../src/planners/VI/viplanner.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

ppcpplanner.o: ../src/planners/PPCP/ppcpplanner.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

rstarplanner.o: ../src/planners/RStar/rstarplanner.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

heap.o: ../src/utils/heap.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

mdp.o: ../src/utils/mdp.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

utils.o: ../src/utils/utils.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

2Dgridsearch.o: ../src/utils/2Dgridsearch.cpp
	g++ $(INCLUDES) $(CPP_FLAGS) -c -o $@ $^

