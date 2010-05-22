#ifndef LATTICE_PLAN_DATA_TYPES
#define LATTICE_PLAN_DATA_TYPES

#include <stdint.h>

#define LP_PATH_FORM "{int, int, <double:1,2>}"
#define LP_PATH_MSG "Lattice Planner Path"

typedef struct {
	int size_points;
	int size_point_dim;
  double* path;
  
} LP_PATH_DATA, *LP_PATH_PTR;

#endif

//#define LP_MAPS_FORM "{int, int, <ubyte:1,2>, <float:1,2>, <float:1,2>}"
#define LP_MAPS_FORM "{int, int, <ubyte:1,2>}"
#define LP_MAPS_MSG "Lattice Planner Maps"

typedef struct {
  int size_y;
  int size_x;
  unsigned char* costmap;
  //float* obsmap;
  //float* trajmap;
                    
} LP_MAPS_DATA, *LP_MAPS_PTR;

