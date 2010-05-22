#ifndef LATTICE_DATA_TYPES
#define LATTICE_DATA_TYPES

#define LP_PATH_FORM "{int, int, <double:1,2>}"
#define LP_PATH_MSG "Lattice Planner Path"

typedef struct {
	int size_points;
	int size_point_dim;
  double** path;
  static const char*  getIPCFormat() { return LP_PATH_FORM; };
  
  
#ifdef MEX_IPC_SERIALIZATION
  INSERT_SERIALIZATION_DECLARATIONS
#endif
  
} LP_PATH_DATA, *LP_PATH_PTR;

#endif
