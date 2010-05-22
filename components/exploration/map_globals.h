#ifndef _MAP_GLOBALS_JMB
#define _MAP_GLOBALS_JMB

// flag to determine if unknown cells are allowed to be traversed (unknown are set to obstacles if not)
#define UNKNOWN_ARE_PASSABLE false

extern float coverage_cell_size; // size of cell in meters
extern float cost_cell_size; // size of cell in meters
extern float elev_cell_size; // size of cell in meters
extern int coverage_size_x; // x and y dimension of coverage map
extern int coverage_size_y;
extern int cost_size_x;// x and y dimension of cost map
extern int cost_size_y;
extern int elev_size_x; // x and y dimension of elevation map
extern int elev_size_y;

extern float sensor_radius; // sensor radius in meters
extern int16_t sensor_height; // sensor height in centimeters
extern int NUMVECTORS;

const int MINFLAG = 251; // value of lowest FLAG
const int OBSTACLE = 250; // value of OBSTACLES on cost map
const int UNKOBSTACLE = 251; // value for UNKNOWN cells on obstacle map
const int UNKNOWN = 0; // value for unknown on coverage map
const int KNOWN = 249; // value for known on coverage map
//const int UNKSCORE = 256; // score to assign for UNKNOWN (NOT USED)	
const int DIJKSTRA_LIMIT = 10000000; // value above which cells are not reachable
extern int HIGH_IG_THRES; // value of IG below which search is pure greedy

// 8 connected moves and costs
enum {MOVERIGHT, MOVEUPRIGHT, MOVEUP, MOVEUPLEFT, MOVELEFT, MOVEDOWNLEFT, MOVEDOWN, MOVEDOWNRIGHT, NOMOVE};
const int dir[3][3] = {{MOVEDOWNLEFT, MOVELEFT, MOVEUPLEFT}, {MOVEDOWN, NOMOVE, MOVEUP}, {MOVEDOWNRIGHT, MOVERIGHT, MOVEUPRIGHT}};
const double stepcost[3][3] = {{1.414213562, 1, 1.414213562}, {1, 0, 1}, {1.414213562, 1, 1.414213562}};

// struct used internally for trajectories
#define GP_TRAJ_DIM 6 
struct Traj_pt_s {
	int x;
	int y;
	float theta;
	float velocity;
	float right_pan;
	float left_pan;

	Traj_pt_s() {
		x = 0;
		y = 0;
		theta = 0.0;
		velocity = 1.0;
		right_pan = 0.0;
		left_pan = 0.0;
		}

	Traj_pt_s(int a, int b, float c, float d, float e, float f) {
		x = a;
		y = b;
		theta = c;
		velocity = d;
		right_pan = e;
		left_pan = f;
	}
};

#endif
