#include <stdint.h>
#ifndef GP_HEADER
#define GP_HEADER

#define GP_DATA_FORM "{int, double, double, double, double, double, double, double, int, int, double, double, <short:1>, <double:1>, <double:1>, <double:1>, <double:9,10>, <uchar:9,10>, int, int, <double:19,20>}"	
#define GP_DATA_MSG "Global_Planner_DATA"

typedef struct {
	// parameters
	int NR;             // number of robots
	double GP_PLAN_TIME; // seconds to allow for planning
	double DIST_GAIN;
	double MIN_RANGE;	// desired min and max ranges to nearest other robot in the same region
	double MAX_RANGE; 
	double DIST_PENALTY;		// penalty per cell for being outside desird range (delta cells * DIST_PENALTY)
	double REGION_PENALTY;		// penalty for being in the same region as another robot (does not apply for outside)
	// map sizes
	double map_cell_size;	// size of map cell in meters
	int map_size_x;		// size of sent map in x dimension in cells 
	int map_size_y;		// size of sent map in y dimension in cells 
	double UTM_x;		// UTM x offset in meters
	double UTM_y;		// UTM y offset in meters
	// robot poses and availability
	int16_t *avail;			// flag for availability of each robot
	double *x;			// x position of robot reference point in meters
	double *y;			// y position of robot reference point in meters
	double *theta; 		// robot heading referenced to 0 = positive x-axis
	// maps
	double *map;		// map of uncertainty in measurements
	unsigned char *region_map;     // map of labeled regions with 0 being outdoors
    int num_regions;    // number of regions in lookup table
    int num_states;     // number of states (number of robots +2)
    double *bias_table; // look up table with region bias values

	static const char*  getIPCFormat() { return GP_DATA_FORM; };

#ifdef MEX_IPC_SERIALIZATION
  INSERT_SERIALIZATION_DECLARATIONS
#endif
  
} GP_DATA, *GP_DATA_PTR;



#define GP_TRAJ_FORM "{int, <short:1>, int, <double:3>, <double:3>, <double:3>}"	
#define GP_TRAJ_MSG "Global_Planner_TRAJ"

typedef struct {
//parameters
  	int NR;             // number of robots
	uint16_t *traj_size;		// start of trajectories for each robot
	int total_size;		//total number of trajectory points
	double *POSEX;		// x coordinates in UTM meters
	double *POSEY;		// y coordinates in UTM meters
	double *POSETHETA;	// theta in radians 0-2*pi

		static const char*  getIPCFormat() { return GP_TRAJ_FORM; };

#ifdef MEX_IPC_SERIALIZATION
  INSERT_SERIALIZATION_DECLARATIONS
#endif
  
} GP_TRAJ, *GP_TRAJ_PTR;
#endif

