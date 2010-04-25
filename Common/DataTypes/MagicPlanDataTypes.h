#ifndef MAGIC_PLAN_DATA_TYPES
#define MAGIC_PLAN_DATA_TYPES

#include <stdint.h>

//Global Planner Interface v1.3 1 Feb 2010
// The following specification is based on the IPC1 protocol, but can be adopted for any messaging system desired.
//
//Initialization
//
//Map Initialization 
//Types:
#define GP_MAP_DATA_FORM "{double, int, int, int, int, int, int, float, float, float}"
#define GP_MAP_DATA_MSG "Global Planner Map Initialization"

typedef struct {
	double timestamp;			// time when new map values go into effect
	int cost_size_x;  		// x size of cost_map in cells
	int cost_size_y;  		// y size of cost_map in cells
	int elev_size_x;  		// x size of elev_map in cells
	int elev_size_y;  		// y size of elev_map in cells
	int coverage_size_x;		// x size of coverage_map in cells
	int coverage_size_y;		// y size of coverage_map in cells
	float cost_cell_size;		// size of cost_map cell in meters
	float elev_cell_size;		// size of elev_map cell in meters
	float coverage_cell_size;	// size of coverage_map cell in meters
  
  static const char*  getIPCFormat() { return GP_MAP_DATA_FORM; };
  
  
#ifdef MEX_IPC_SERIALIZATION
  INSERT_SERIALIZATION_DECLARATIONS
#endif
  
} GP_MAP_DATA, *GP_MAP_DATA_PTR;


//
//Variables:
//double timestamp
//Time when measurement was taken for position updates, time of last data point for map updates, and time of configuration change for initialization messages.  (Variable used in all sections, but for brevity the description is not repeated).
//
//int cost_size_x, cost_size_y
//Two variables passed at startup (or as needed) indicating the x and y dimensions of the traversability/cost map in cells.
//
//int elev_size_x, elev_size_y
//Two variables passed at startup (or as needed) indicating the x and y dimensions of the elevation map in cells.
//
//int coverage_size_x, coverage_size_y
//Two variables passed at startup (or as needed) indicating the x and y dimensions of the coverage map in cells.
//
//float cost_cell_size, elev_cell_size,  coverage_cell_size
//Three variables indicating the discretization sizes of the cost, elevation and coverage maps, respectively, in meters.
//
//Messages:
//"global_planner_map_init" with data type GP_MAP_DATA_FORM
//Message sent at system startup and when change in discretization is made.  Message uses the GP_MAP_DATA structure to pass relevant map parameters.  Subsequent calls to this function will update and reallocate any internal storage as necessary.  MUST BE FOLLOWED BY FULL MAP UPDATE MESSAGE .  Unspecified results will occur if the map size passed does not match the most recent stored values.
//
//
//Robot Initialization 
//Types:

#define GP_ROBOT_PARAMETER_FORM "{float, float, int, int, float, short, <double:3,4>}"
#define GP_ROBOT_PARAMETER_MSG "Global Planner Robot Parameters"

typedef struct{
	float MAX_VELOCITY;		// maximum velocity in m/s (1)
	float MAX_TURN_RATE;		// maximum turn rate in radians per second (2)
	int I_DIMENSION;			// number of points in perimeter (3)	
	int J_DIMENSION; 			// number of dimensions (should be 2) (4)
	float sensor_radius;		// sensing radius of robot
	int16_t sensor_height;		// sensing height of robot
	double *PerimeterArray;		// array of points, one point per row
  
  
  static const char*  getIPCFormat() { return GP_ROBOT_PARAMETER_FORM; };
  
#ifdef MEX_IPC_SERIALIZATION
  INSERT_SERIALIZATION_DECLARATIONS
#endif
  
} GP_ROBOT_PARAMETER, *GP_ROBOT_PARAMETER_PTR;


//
//Variables:
//float MAX_VELOCITY, MAX_TURN_RATE
//Two floating point variables with the maximum velocity and turning rate of the robot in meters per second and radians per second respectively.  
//
//double PerimeterArray
//A list of points specifying the vertices on the robot perimeter, one point per row.  Specified in meters from the origin, using the base robot coordinate frame (the same reference point as the perception system uses and the point the global planner bases all plans from).
//
//int I_DIMENSION, int J_DIMENSION
//The length and width of the array.  The width should be 2, with one point per row.  
//
//Messages:
//"global_planner_robot_init" with data type GP_ROBOT_PARAMETER_FORM
//Message contains robot parameters and a list of points defining the perimeter vertices of the robot.  
//
//
//Each Timestep (System -> Global Planner)
//
//Send Position and Map Update
//Types:

#define GP_POSITION_UPDATE_FORM "{double, float, float, float}"	
#define GP_POSITION_UPDATE_MSG "Global Planner Position Update"
typedef struct {
	double timestamp;		// timestamp of when position was accurate
	float x;			// x position of robot reference point in meters
	float y;			// y position of robot reference point in meters
	float theta; 		// robot heading referenced to 0 = positive x-axis
  
  static const char*  getIPCFormat() { return GP_POSITION_UPDATE_FORM; };
  
#ifdef MEX_IPC_SERIALIZATION
  INSERT_SERIALIZATION_DECLARATIONS
#endif
  
} GP_POSITION_UPDATE, *GP_POSITION_UPDATE_PTR;


#define GP_FULL_UPDATE_FORM "{double, int, int, int, int, int, int, <ubyte: 2, 3>, <ubyte: 4, 5>, <short: 6, 7>}"
#define GP_FULL_UPDATE_MSG "Global Planner Full Update"
typedef struct {
	double timestamp;		// timestamp for map update
// following  sizes refer to what is actually transmitted
	int sent_cover_x;		// size of sent coverage map in x dimension in cells 
	int sent_cover_y;		// size of sent coverage map in y dimension in cells 
	int sent_cost_x;		// size of sent cost map in x dimension in cells 
	int sent_cost_y;		// size of sent cost map in y dimension in cells 
	int sent_elev_x;		// size of sent elevation map in x dimension in cells 
	int sent_elev_y;		// size of sent elevation map in y dimension in cells 
	unsigned char *coverage_map;		// map of uncertainty in measurements
	unsigned char *cost_map;		// map of traversibility costs
	int16_t *elev_map;				// map of elevations
  
  static const char*  getIPCFormat() { return GP_FULL_UPDATE_FORM; };

#ifdef MEX_IPC_SERIALIZATION
  INSERT_SERIALIZATION_DECLARATIONS
#endif
  
}  GP_FULL_UPDATE, *GP_FULL_UPDATE_PTR;


#define GP_SHORT_UPDATE_FORM "{double, int, int, int, int, int, int, int, int, int, int, int, int, <ubyte: 2, 3>, <ubyte: 4, 5>, <short: 6,7>}"
#define GP_SHORT_UPDATE_MSG "Global Planner Short Update"
typedef struct {
	double timestamp;		// timestamp of map update
				// following  sizes refer to what is actually transmitted
	int sent_cover_x;		// size of sent coverage map in x dimension in cells 
	int sent_cover_y;		// size of sent coverage map in y dimension in cells 
	int sent_cost_x;		// size of sent cost map in x dimension in cells 
	int sent_cost_y;		// size of sent cost map in y dimension in cells 
	int sent_elev_x;		// size of sent elevation map in x dimension in cells 
	int sent_elev_y;		// size of sent elevation map in y dimension in cells 
				// following values are in cells referenced to the full map
	int x_cover_start;	//global x-coordinate of the [0][0] entry of coverage map
	int y_cover_start;	//global y-coordinate of the [0][0] entry of coverage map
	int x_cost_start;		//global x-coordinate of the [0][0] entry of cost map
	int y_cost_start;		//global y-coordinate of the [0][0] entry of cost map
	int x_elev_start;		//global x-coordinate of the [0][0] entry of elev map
	int y_elev_start;		//global y-coordinate of the [0][0] entry of elev map
	unsigned char *coverage_map;		// map of uncertainty in measurements	
	unsigned char *cost_map;		// map of traversibility costs
	int16_t *elev_map;				// map of elevations
  
  
  static const char*  getIPCFormat() { return GP_SHORT_UPDATE_FORM; };
  

#ifdef MEX_IPC_SERIALIZATION
  INSERT_SERIALIZATION_DECLARATIONS
#endif
 
}  GP_SHORT_UPDATE, *GP_SHORT_UPDATE_PTR;


//Variables:
//float x, y, theta
//Robot pose variables with x and y in meters and theta in radians (0 angle corresponds to the positive x direction on the map).
//
//int sent_cost_x, sent_cost_y, sent_elev_x, sent_elev_y, sent_cover_x, sent_cover_y
//Dimensions of the map portion actually transmitted in cells.  For full map updates these values should match the values specified during initialization.  During partial map updates, these values may be any value between 1 and the actual dimension.  
//
//unsigned char cost_map[sent_cost_x*sent_cost_y]
//An array of char's indicating the traversability, cost and status of each cell where each cell has the following numbers:
//0-249 - number indicating cost of to traverse with 0 being no cost to traverse and 249 being very difficult/costly/slow to traverse
//250 - impassable2 terrain 
//251-255 - reserved for future use
//
//float elev_map[sent_elev_x*sent_elev_y]
//An array of floats representing height of each cell in meters.
//
//unsigned char coverage_map[sent_cover_x*sent_cover_y]
//an array of char's indicating the uncertainty in coverage of each cell where each cell has the following numbers:
//0-249 - confidence in coverage with 0 being uncertain and 249 being certain/no doubt .  This value should be an aggregate score of the individual coverage values for the 3-D stack of cells vertically over each 2-D (x,y) position (i.e. if a portion of the stack has not yet been seen while other portions have been, the stack should have an aggregate value higher than a stack that has been seen from top to bottom).
//250-255 reserved for future use
//
//int x_cost_start, y_cost_start, x_elev_start, y_elev_start, x_cover_start, y_cover_start
//The location of transmitted map[0][0] expressed in cells referenced to the full map.  (i.e. what is the sent map[0][0] coordinates in the full map).
//
//Messages:
//"global_planner_full_update" with data type GP_UPDATE_FORM
//Message contains the current robot pose as well as all three full maps.  Used to send the initial map or whenever changing map dimensions.
//
//"global_planner_short_update" with data type GP_UPDATE_SHORT_FORM
//Message contains current robot pose and smaller section of the map.  This is the normal message for each timestep and should typically include either a rectangle incorporating all of the areas changed since the last timestep or a 30m x 30m square centered on the robot.  Since it does not include the entire map, it contains six extra parameters referencing the coordinates of the transmitted maps [0][0] position in the full map.
//
//Each Timestep (Global Planner -> System)
//
//Return Planned Trajectory
//Types:


#define GP_TRAJECTORY_FORM "{int, int, <float: 1, 2>}"
#define GP_TRAJECTORY_MSG "Global Planner Trajectory"
typedef struct {
	int num_traj_pts;	  // number of points in the trajectory (1)
	int traj_dim;	  // width of trajectory array (x,y,theta, velocity, panr, 				  // panl) (2)
	float *traj_array;  // 2-D array of trajectory points (num_traj_pts x traj_dim)
  
  
  static const char*  getIPCFormat() { return GP_TRAJECTORY_FORM; };
  
#ifdef MEX_IPC_SERIALIZATION
  INSERT_SERIALIZATION_DECLARATIONS
#endif

}  GP_TRAJECTORY, *GP_TRAJECTORY_PTR;

//
//Variables:
//float trajectory[number_of_points *number of dimensions]
//A 2-d array of trajectory points with each point being expressed as traj_dim contiguous elements.   The first 2 elements  are the x, y position expressed in meters, followed by the heading in radians, and the velocity in meters per second, with the last 2 elements reflecting the right and left limits of the requested pan angle for the sensors at this location (pan angles are given as 0 for straight ahead, negative for camera pointing to the robots right, and positive for the camera pointing to the robots left).  The pan angle limits will not change more than once per 10 meters of forward travel with the exception that the pan angles will be set to 0, 0 if the global planner is attempting to transit during a particular section of the trajectory and does not require any specific sensor orientation.  For path segments that the planner does not have a recommended heading or velocity, a value of -1 will be returned.  
//
//ex. { 456.23 765.23 1.35 1.5 -0.17 0.78}, {458.34 769.32 1.43 1.5 -0.17 0.78}
//This trajectory contains two points (456.23, 765.23) and (458.34, 769.32) with a steady right and left pan of approximately  10 degrees to the right and 45 degrees to the left.  The robot is making a slight left hand turn at constant velocity.
//
//Messages:
//"global_planner_trajectory" with data type GP_TRAJECTORY_FORM
//Message contains the trajectory points and associated requested pan angles.  This message is transmitted each timestep by the global planner based on the current location of the robot and updated map.


#endif //MAGIC_PLAN_DATA_TYPES

