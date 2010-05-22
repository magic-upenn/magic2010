#ifndef _TESTPLANNER_JMB
#define _TESTPLANNER_JMB

//const int MAP_X_M = 198;  // size in meters  %%%%%%%%%%%%%%%%%%%% remove const requirement
//const int MAP_Y_M = 198;
const float CELL_SIZE = .1; // cell size in meters
const int MAP_X = 600;//1947; // number of cells in each dimension
const int MAP_Y = 600;//1947;
const int MAP_S = MAP_X*MAP_Y; 
static unsigned char coverage_map[MAP_S], cost_map[MAP_S]; // allocate maps
const float SENSOR_VALUE = 5.0;  // in meters

#endif
