#include "common_headers.h"
using namespace std;

#include "filetransfer.h"
#include "/opt/ros/boxturtle/stacks/motion_planners/sbpl/src/sbpl/headers.h" // SBPL

//#define MODULE_NAME "Global Planner Linux"
#define DEFAULTMAP 1

// Module written by Jonathan Michael Butzke
//	serves as the main subroutine to determine a path.
// number of robots

timeval tv_start, tv_stop, tv_prev;
double time_ms, elap_time_ms;

GPLAN::GPLAN() {
	map_sizex_m = 0;
	map_sizey_m = 0;
	map_cell_size = 0;
	map_size_x = 0;
	map_size_y = 0;

	//map variables
	int NUMROBOTS = 1;
	ROBOTAVAIL = new bool[NUMROBOTS];
	for (int idx=0; idx < NUMROBOTS; idx++) { ROBOTAVAIL[idx]= true;}
	robot_goals = new int[NUMROBOTS*2];

	// robot variables
	POSEX = new double[NUMROBOTS];
	POSEY = new double[NUMROBOTS];
	POSETHETA = new double[NUMROBOTS];
	robot_xx = 1;
	robot_yy = 1; // float posit of robot
	robot_x = 1;
	robot_y = 1; // x and y cell coordinates of robot
	theta = 0;
	sensor_radius = 10.0; // distance sensors can see in m
	sensor_height = 120; // sensor height in cm
	SENSORWIDTH = (double)(240 * M_PI / 180); // sensor width in radians used to determine start and finish vectors for ray tracing
	inflation_size = 0; //size in cells to inflate obstacles
	SOFT_PAD_DIST = 1.0;

	//map variables
	cover_map = new unsigned char[DEFAULTMAP];
	cost_map = new unsigned char[DEFAULTMAP];
	elev_map = new int16_t[DEFAULTMAP]; 
	region_map = new unsigned char[DEFAULTMAP];
	real_cover_map = new unsigned char[DEFAULTMAP];
//	real_cost_map = new unsigned char[DEFAULTMAP];
	inflated_cost_map = new unsigned char[DEFAULTMAP];
	cost_map_pa = new unsigned char*[DEFAULTMAP]; // ptr to first element of each row
	inf_cost_map_pa = new unsigned char*[DEFAULTMAP]; //ptr to first element of each row for inflated map

	// planner variables
	GP_PLAN_TIME = 1.0; // seconds to allow for planning
	DIST_GAIN = .5; // factor to switch between greedy and IG
	WRITE_FILES = false; // flag to write files out
	DISPLAY_OUTPUT = false; // flag to display any output
	THETA_BIAS = 1;// can not equal zero
	MIN_RANGE = 0;
	MAX_RANGE = 10000000;
	DIST_PENALTY = 0;
	REGION_PENALTY = 0;

	// sensor variables
	NUMVECTORS = 0;
}

GPLAN::~GPLAN() {
	delete [] ROBOTAVAIL;
	delete [] POSEX;
	delete [] POSEY;
	delete [] POSETHETA;
	delete [] cover_map;
	delete [] cost_map;
	delete [] elev_map;
	delete [] region_map;
	delete [] real_cover_map;
	delete [] inflated_cost_map;
	delete [] inf_cost_map_pa;
	delete [] cost_map_pa;
}

void GPLAN::setPixel(int x, int y) {
	unsigned int locptr = 0;
	double tempangle = atan2((double) y, (double) x);

	if (tempangle < 0) {
		tempangle += (2.0 * M_PI);
	}

	if (rayendpts.size() == 0) {
		rayendpts.push_back(RAY_TEMPLATE_PT(x, y, tempangle));
	} else {
		while ((locptr < rayendpts.size()) && (rayendpts[locptr].angle <= tempangle)) {
			locptr++;
		}
		if (locptr == 0) {
			rayendpts.insert(rayendpts.begin(),	RAY_TEMPLATE_PT(x, y, tempangle));
		} else if (rayendpts[locptr - 1].angle != tempangle) {
			if (locptr == rayendpts.size()) {
				rayendpts.push_back(RAY_TEMPLATE_PT(x, y, tempangle));
			} else {
				rayendpts.insert(rayendpts.begin() + locptr, RAY_TEMPLATE_PT(x,	y, tempangle));
			}
		}
	}
}

void GPLAN::rasterCircle(int radius) {
	// "Midpoint circle algorithm." Wikipedia, The Free Encyclopedia. 6 Jul 2009, 03:19 UTC. 6 Jul 2009 <http://en.wikipedia.org/w/index.php?title=Midpoint_circle_algorithm&oldid=300524864>.

	// centerpoint and radius are inputs
	int f = 1 - radius;
	int ddF_x = 1;
	int ddF_y = -2 * radius;
	int x = 0;
	int y = radius;

	rayendpts.clear();

	setPixel(0, radius);
	setPixel(0, -radius);
	setPixel(radius, 0);
	setPixel(-radius, 0);
	setPixel((int) (sqrt(.5) * radius), (int) (sqrt(.5) * radius));
	setPixel((int) (sqrt(.5) * radius), -(int) (sqrt(.5) * radius));
	setPixel(-(int) (sqrt(.5) * radius), (int) (sqrt(.5) * radius));
	setPixel(-(int) (sqrt(.5) * radius), -(int) (sqrt(.5) * radius));

	while (x < y) {

		if (f >= 0) {
			y--;
			ddF_y += 2;
			f += ddF_y;
		}
		x++;
		ddF_x += 2;
		f += ddF_x;
		setPixel(x, y);
		setPixel(-x, y);
		setPixel(x, -y);
		setPixel(-x, -y);
		setPixel(y, x);
		setPixel(-y, x);
		setPixel(y, -x);
		setPixel(-y, -x);
	}
	NUMVECTORS = rayendpts.size();
	cout << "Number of rays in template: " << NUMVECTORS << endl;
}

int GPLAN::ValidVec(int vec) {
	// verifies that the vector is within limits
	if (vec < 0) {
		vec = NUMVECTORS + vec;
	} else if (vec >= NUMVECTORS) {
		vec = vec - NUMVECTORS;
	}
	return vec;
}

bool GPLAN::OnMap(int x, int y) {
	// function to determine if a point is on the map
	if ((x < map_size_x) && (x >= 0) && (y < map_size_y) && (y >= 0)) {
		return true;
	} else {
		return false;
	}
}

double GPLAN::return_path(int x_target, int y_target, const int dijkstra[],
		vector<Traj_pt_s> & trajectory, int RID) {
	// function to return the optimal path to a target location given a dijkstra map

	Traj_pt_s current;
	vector<Traj_pt_s> inv_traj;
	int x_val, y_val, best_x_val, best_y_val;
	double cost = 0;
	x_val = current.x = x_target;
	y_val = current.y = y_target;

	inv_traj.clear();
	inv_traj.push_back(current);
	int min_val;
	double temp_cost;
	if (dijkstra[x_val + map_size_x * y_val + map_size_x*map_size_y*RID] < DIJKSTRA_LIMIT) {
		while ((x_val != robot_x) || (y_val != robot_y)) {
			min_val = DIJKSTRA_LIMIT + 10;// 90000000;
			temp_cost = 0;
			for (int x = -1; x < 2; x++) {
				for (int y = -1; y < 2; y++) {
					if (OnMap(x + x_val, y + y_val) && !((x == 0) && (y == 0))) {
						int val = dijkstra[(x + x_val) + (map_size_x * (y
									+ y_val))+ map_size_x*map_size_y*RID];
						if (val < min_val) {
							min_val = val;
							best_y_val = y_val + y;
							best_x_val = x_val + x;
							temp_cost = (stepcost[x + 1][y + 1])*(double)(inflated_cost_map[best_x_val+map_size_x*best_y_val]+1);
						} // if val
					} // if onmap
				} // y
			} //x

			cost += temp_cost;
			current.x = x_val = best_x_val;
			current.y = y_val = best_y_val;
			inv_traj.push_back(current);
		}
		// invert the trajectory to send back
		trajectory.clear();
		while (inv_traj.size() != 0) {
			current.x = inv_traj.back().x;
			current.y = inv_traj.back().y;
			trajectory.push_back(current);
			inv_traj.pop_back();
		}
		return (cost * map_cell_size);
	} else {
		cout << "WARNING: Invalid goal location - "<< x_target << " " << y_target << endl;
		return (-1);
	}
}

bool GPLAN::map_alloc(void) {
	//remove old storage

	delete[] cover_map;
	delete[] cost_map;
	delete[] elev_map;
	delete[] region_map;
	delete[] inflated_cost_map;
	delete[] cost_map_pa;
	delete[] inf_cost_map_pa;
	delete [] real_cover_map;
//	delete [] real_cost_map;

	//allocate new storage
	cost_map = new unsigned char[map_size_x * map_size_y];
	elev_map = new int16_t[map_size_x * map_size_y];
	cover_map = new unsigned char[map_size_x * map_size_y];
	region_map = new unsigned char[map_size_x*map_size_y];
	real_cover_map = new unsigned char[map_size_x*map_size_y];
//	real_cost_map = new unsigned char[map_size_x*map_size_y];
	inflated_cost_map = new unsigned char[map_size_x * map_size_y];

	// set up pointer to array of pointers for [][] indexing of cost map
	cost_map_pa = new unsigned char*[map_size_y];
	inf_cost_map_pa = new unsigned char*[map_size_y];
	for (int j = 0; j < map_size_y; j++) {
		cost_map_pa[j] = &cost_map[j * map_size_x];
		inf_cost_map_pa[j] = &inflated_cost_map[j * map_size_x];
	}

	// false if any map is null
	if ((cover_map != NULL) && (cost_map != NULL) && (elev_map != NULL) && (region_map !=NULL)
			&& (inflated_cost_map != NULL) && (cost_map_pa != NULL) && (inf_cost_map_pa != NULL)) {
		return true;
	} else {
		return false;
	}
}

void GPLAN::sample_point(int &x_target, int &y_target) {
	// fxn to pick possible target points

	static int prev_x = 0, prev_y = 0;
	x_target = -1;
	y_target = -1;

	if(!frontier.empty()) {	
		x_target = frontier.top().x;
		y_target = frontier.top().y;
		frontier.pop();
	}
}

void GPLAN::calc_all_IG(unsigned int IG_map[]) {
	// function calculates the IG for each point on the coverage map and updates IG_map
	// value represents the sum of the lack of knowledge (KNOWN - cover_map[]) for all points with 
	// indicies less than or equal to a given cell

	//initialize bottom row to 0's
	for (int i = 0; i < map_size_x; i++) {
		IG_map[i] = 0;
	}

	//initialize x=0 edge to 0's
	for (int j = 0; j < map_size_y; j++) {
		IG_map[map_size_x * j] = 0;
	}

	//calc remaining values
	for (int j = 1; j < map_size_y; j++) {
		for (int i = 1; i < map_size_x; i++) {
			if (cost_map[i + map_size_x * j] == OBSTACLE) {
				IG_map[i + map_size_x * j] 
					= IG_map[(i - 1)+ map_size_x * j] 
					+ IG_map[i + map_size_x* (j - 1)]
					- IG_map[(i - 1) + map_size_x * (j - 1)];
			} else {
				IG_map[i + map_size_x * j] 
					= IG_map[(i - 1)+ map_size_x * j] 
					+ IG_map[i + map_size_x * (j - 1)]
					- IG_map[(i - 1) + map_size_x * (j - 1)]
					- (int) cover_map[i + map_size_x * j] + KNOWN;
			}
		}
	}
}

unsigned int GPLAN::get_IG(unsigned int IG_map[], int x, int y, int dim) {
	// function returns the IG in a box +/- dim from point (x,y)

	int t, r, l, b; // top right left and bottom dimensions
	t = min((map_size_y - 1), y + dim);
	b = max(0, y - dim);
	l = max(0, x - dim);
	r = min((map_size_x - 1), x + dim);

	return (IG_map[r + map_size_x * t] - IG_map[r + map_size_x * b]
			+ IG_map[l + map_size_x * b] - IG_map[l + map_size_x * t]);
}

double GPLAN::IG_dist_ratio(int IG, double dist) {
	// fxn to calc  weighted distance to IG ratio
	return ((IG*DIST_GAIN) / (dist*(1.0-DIST_GAIN)));
}


double GPLAN::bias(int RID, int x, int y) {
	// fxn takes robot number and potential endpoint and returns a double bias amount 
	// based on distance outside range in cells * DIST_PENALTY
	// no penalty applies if the points are in different regions
	// fxn to calc a heading bias to prefer points closer to "straight ahead"

//	double theta_pt = atan2((double)(y-POSEY[RID]), (double)(x-POSEX[RID]));
//	double theta_diff = theta_pt - theta;

	//normalize between -pi and pi
//	if (theta_diff > M_PI) { theta_diff -= 2*M_PI;}
//	if (theta_diff < -M_PI) { theta_diff += 2*M_PI;}

//	double heading_bias =  ((1.0+cos(THETA_BIAS*theta_diff))/2.0);

	int min_dist2 = (map_size_x+map_size_y) * (map_size_x+map_size_y) ;
	double dist_bias = 1;
	bool robot_in_region = false;
	bool region_zero = true;
	double region_bias = 1.0;
	double delta = 0;
	double same_bonus = 1.0;

	for (int ridx = 0; ridx < NUMROBOTS; ridx++) {
		int xx = robot_goals[ridx*2];
		int yy = robot_goals[ridx*2+1];
		if (ridx != RID) {
			if (region_map[xx + map_size_x*yy] == region_map[x + map_size_x*y]) { 
				robot_in_region = true;
				int dist2 = ((x-xx)*(x-xx) + (y-yy)*(y-yy));
			//	cout << "dist2  from " << ridx << " is " << dist2;
				if (dist2 < min_dist2) { min_dist2 = dist2; }
			}
		}
		else {
			if ((xx == x) && (yy = y)) { same_bonus = 2.0; }
		}
	}

	// if robot is in same region calc bias
	if (robot_in_region) {
		double dist;
	
		// determine if in region zero and if not (since we are in this block) apply the penalty for sharing regions
		if (region_map[x + map_size_x*y] != 0) {region_bias =  REGION_PENALTY;} else { region_bias = REGION_PENALTY*10;}

		// determine distance and delta from desired range
		dist = sqrt((double)(min_dist2)) * map_cell_size;
//		cout << " dist " << dist;
		if (dist < MIN_RANGE) { delta = dist/MIN_RANGE; }
		else if (dist > MAX_RANGE) {delta = MAX_RANGE/dist; }

		// calculate bias
		dist_bias = (delta) * DIST_PENALTY;
	//	if (dist_bias < 0.1) {dist_bias = 0.1; }
//		region_bias =  (double)(!region_zero) * REGION_PENALTY;
	}
	double bias = dist_bias * region_bias * same_bonus;// *  heading_bias ;
//	cout << " penalties for " << x << "," << y << " d: " << delta << " "<<  dist_bias << " r0: " << region_bias << " h: " << heading_bias << " t: " << bias << endl;
	return bias;
}

//double GPLAN::calc_score(int x, int y, int RID, int IG, double dist) {


void GPLAN::find_frontier(unsigned int IG_map[], int dijkstra[], int RID) {
	// function scans coverage map and populates the frontier queue with frontier points
	
int dim = (int)(sqrt((sensor_radius* SENSORWIDTH)/(2*M_PI*map_cell_size)));

	while (!frontier.empty()) {
		frontier.pop();
	}
	for (int j = 1; j < map_size_y - 1; j++) {
		for (int i = 1; i < map_size_x - 1; i++) {
			if (dijkstra[i + map_size_x * j+ map_size_x*map_size_y*RID] < DIJKSTRA_LIMIT) {
				if ((real_cover_map[i + map_size_x * j] == KNOWN)
						&& ((real_cover_map[(i + 1) + map_size_x * (j)] != KNOWN) 
							|| (real_cover_map[(i - 1) + map_size_x * (j)] != KNOWN)
							|| (real_cover_map[(i) + map_size_x * (j + 1)] != KNOWN) 
							|| (real_cover_map[(i) + map_size_x * (j - 1)] != KNOWN))) {
					frontier_pts temp(i,j, bias(RID,i,j)*IG_dist_ratio(get_IG(IG_map, i, j, dim), dijkstra[i + map_size_x * j + map_size_x*map_size_y*RID]));
					
					//frontier_pts temp(i, j, heading_bias(i,j)*get_IG(IG_map, i, j, dim),
					//		dijkstra[i + map_size_x * j + map_size_x*map_size_y*RID], DIST_GAIN);
					frontier.push(temp);
					//cout << i << "," << j << " is on the frontier " << endl;
				}
			}
		}
	}
}
//
//void denoise(unsigned char src[], int strel, int mapm, int mapn) {
//	// performs morphological open
//	int xx = strel / 2;
//	int yy = strel / 2;
//
//	unsigned char *temp = new unsigned char[mapm * mapn];
//	unsigned char *dest = new unsigned char[mapm * mapn];
//
//	for (int j = 0; j < mapn; j++) {
//		for (int i = 0; i < mapm; i++) {
//			temp[i + j * mapm] = UNKNOWN;
//			dest[i + j * mapm] = KNOWN;
//		}
//	}
//
//	//perform dilation of known areas
//	for (int j = 0; j < mapn; j++) {
//		for (int i = 0; i < mapm; i++) {
//			if (src[i + mapm * j] != UNKNOWN) {
//				for (int x = 0; x < strel; x++) {
//					for (int y = 0; y < strel; y++) {
//						if (OnMap(x + i - xx, y + j - yy)) {
//							temp[x + i - xx + (y + j - yy) * mapm] = KNOWN;
//						}
//					}
//				}
//			}
//		}
//	}
//
//	// perform erosion on temp map to return known areas to size
//	for (int j = 0; j < mapn; j++) {
//		for (int i = 0; i < mapm; i++) {
//			if (temp[i + mapm * j] == UNKNOWN) {
//				for (int x = 0; x <= strel; x++) {
//					for (int y = 0; y <= strel; y++) {
//						if (OnMap(x + i - xx, y + j - yy)) {
//							dest[x + i - xx + (y + j - yy) * mapm] = UNKNOWN;
//						}
//					}
//				}
//			}
//		}
//	}
//
//	// copy the dest array back onto the original src array
//	memcpy((void *)src,(void *) dest, sizeof(unsigned char)*mapm*mapn);
//	delete[] dest;
//	delete[] temp;
//
//}

void GPLAN::fix_cover(int robot_id) {
	// function to make checked coverage map include the other robots estimated maps
	if (DISPLAY_OUTPUT) {printf(" fix cover for %d\n", robot_id);}
	//delete [] cover_map;
	//cover_map = new unsigned char[map_size_x * map_size_y];	// non-const storage for each possible goal
	//memcpy((void *)cover_map, (void *)real_cover_map, map_size_x*map_size_y * (sizeof(unsigned char)));

	robot_xx = POSEX[robot_id];
	robot_x = (int)(robot_xx/map_cell_size);
	robot_yy = POSEY[robot_id];
	robot_y = (int)(robot_yy/map_cell_size);
	theta = POSETHETA[robot_id];

//	DIST_GAIN = BASE_DIST_GAIN + robot_id*DIST_GAIN_DELTA;

	if (DISPLAY_OUTPUT) {cout << "robot " << robot_id << " is at UTM " << robot_xx << "," << robot_yy << " cell " << robot_x << "," << robot_y << endl;}

	//	for (int id=0; id < NUMROBOTS; id++) {
	//	cout << "looking at map " << id << endl;
/*	if (robot_id>0) {
		for (int y=0; y < map_size_y; y++) {
			for (int x=0; x < map_size_x; x++) {
				if (cover_map[x + map_size_x*y] != real_cover_map[x + map_size_x*y]) {
					inflated_cost_map[x+map_size_x*y]= max(cost_map[x+map_size_x*y], (unsigned char)OBSTACLE);
					cost_map[x+map_size_x*y]= max(cost_map[x+map_size_x*y], (unsigned char)OBSTACLE);
				}
				//cout !?!< << "." ;
			}
			//cout << " y @ " << y << endl;
		}
	}*/
	//	}
	if (DISPLAY_OUTPUT) {cout << "done with fix cover" << endl;}
}

void GP_threads::SearchFxn(int RID, int dijkstra[], int r_robot_x, int r_robot_y, GPLAN * gplanner) {
	cout << "s" <<  RID << endl;

	int sx = gplanner->map_size_x;
	int sy = gplanner->map_size_y;
	// ensure that the robot cell is not an obstacle and clear a little box if there is
	int rad = (int)ceil(gplanner->inflation_size + 1);
	float rad_2 = pow(gplanner->inflation_size + 1, 2);
	gplanner->cover_map[r_robot_x + sx * r_robot_y] = KNOWN;
	//cost_map[robot_x + map_size_x * robot_y] = 0;
	/*	if (cost_map[robot_x + map_size_x * robot_y] >= OBSTACLE) {
		for (int xxx = -rad; xxx < rad; xxx++) {
		for (int yyy = -rad; yyy < rad; yyy++) {
		if (OnMap(robot_x + xxx, robot_y + yyy) && ((xxx * xxx + yyy

	 * yyy) < rad_2)) {
	 cost_map[robot_x + xxx + map_size_x * (robot_y + yyy)]
	 = min((int) cost_map[robot_x + xxx + map_size_x
	 * (robot_y + yyy)], OBSTACLE - ((rad * rad)
	 / (1 + xxx * xxx + yyy * yyy)));

	 cover_map[robot_x + xxx + map_size_x * (robot_y + yyy)]
	 = KNOWN;
	 }
	 }
	 }

	 }*/
	if (gplanner->inflated_cost_map[r_robot_x + sx * r_robot_y] >= OBSTACLE) {
		for (int xxx = -rad; xxx < rad; xxx++) {
			for (int yyy = -rad; yyy < rad; yyy++) {
				if (gplanner->OnMap(r_robot_x + xxx, r_robot_y + yyy) && ((xxx*xxx + yyy*yyy) < rad_2)) {
					if (gplanner->cost_map[r_robot_x + xxx + (sx * (r_robot_y+yyy))] !=OBSTACLE) {
						gplanner->inflated_cost_map[r_robot_x + xxx + (sx * (r_robot_y + yyy))] 
							= min((int) gplanner->inflated_cost_map[r_robot_x + xxx+ (sx * (r_robot_y + yyy))],
									OBSTACLE - ((3	* rad * rad) / (1 + xxx * xxx + yyy * yyy)));
					}
				}
			}
		}
	}

	// setup search environment
	SBPL2DGridSearch search(sy, sx, gplanner->map_cell_size);
	search.setOPENdatastructure(SBPL_2DGRIDSEARCH_OPENTYPE_HEAP);
	//search.setOPENdatastructure(SBPL_2DGRIDSEARCH_OPENTYPE_SLIDINGBUCKETS);

	// dijkstra map to get cost to all points
	search.search(gplanner->inf_cost_map_pa, OBSTACLE, r_robot_y, r_robot_x, r_robot_y + 1,r_robot_x + 1, SBPL_2DGRIDSEARCH_TERM_CONDITION_ALLCELLS);

	// get distance to each accessable point on inflated map

	for (int j = 0; j < sy; j++) {
		for (int i = 0; i < sx; i++) {
			dijkstra[i + sx * j + sx * sy * RID] = (int) (search.getlowerboundoncostfromstart_inmm(j, i));
		}
	}
	cout << "d" << RID << endl;
}

void GPLAN::global_planner(double goal_x, double goal_y, double goal_theta) {
	// function provides a traj to best found goal point to (nearest or most valuable)
	printf("Started exploration planner\n");

	float *obs_array = new float[map_size_x * map_size_y];
	float **obs_ptr_array = new float*[map_size_y];
	float *nonfree_array = new float[map_size_x * map_size_y];
	float **nonfree_ptr_array = new float*[map_size_y];

	gettimeofday(&tv_stop, NULL);
	time_ms=(tv_stop.tv_sec-tv_start.tv_sec)*1000+(tv_stop.tv_usec-tv_start.tv_usec)/1000;
	cout << time_ms << "                                            time @ start "  << endl;
	tv_prev = tv_stop;

	// set up array of pointers
	for (int j = 0; j < map_size_y; j++) {
		obs_ptr_array[j] = &obs_array[j * map_size_x];
		nonfree_ptr_array[j] = &nonfree_array[j * map_size_x];
	}

	// remove obstacles from unknown areas
	for (int j = 0; j < map_size_y; j++) {
		for (int i = 0; i < map_size_x; i++) {
			if (cover_map[i + map_size_x * j] == UNKNOWN) {
				elev_map[i + map_size_x * j] = -OBS16;
				cost_map[i + map_size_x * j] = 0;
			}
		}
	}

	// inflate map
	computeDistancestoNonfreeAreas(cost_map_pa, map_size_y, map_size_x, OBSTACLE, obs_ptr_array, nonfree_ptr_array);
	int dim = (int)(sensor_radius / (2.0 * map_cell_size));

	//update inflated map based on robot size and make unknown areas obstacles w/o inflation
	for (int j = 0; j < map_size_y; j++) {
		for (int i = 0; i < map_size_x; i++) {
			if (((!UNKNOWN_ARE_PASSABLE) && (cover_map[i + map_size_x * j]	== UNKNOWN)) || (obs_ptr_array[j][i] <= inflation_size)) {
				if ((!UNKNOWN_ARE_PASSABLE) && (cover_map[i + map_size_x * j]	== UNKNOWN)) {
					inflated_cost_map[i + map_size_x * j] = UNKOBSTACLE;
				}
				if (obs_ptr_array[j][i] <= inflation_size) {
					inflated_cost_map[i + map_size_x * j] = OBSTACLE;
				}
			}
			//if(obs_ptr_array[j][i]<=inflation_size) { inflated_cost_map[i+map_size_x*j] = OBSTACLE; 	}
			else {
				int pad_dist = (int)(SOFT_PAD_DIST/map_cell_size); 
				int buffer = (pad_dist - (int)inflation_size);
				//printf("%i %i %f\n", pad_dist, buffer, inflation_size);
				inflated_cost_map[i + map_size_x * j] = (unsigned char) max((double) (cost_map[i + map_size_x * j]) , (double)((pad_dist - obs_ptr_array[j][i])*200/buffer));
				//printf("(%4.2f", (double)((pad_dist - obs_ptr_array[j][i])*200/buffer));
				//		 	inflated_cost_map[i + map_size_x * j] = (unsigned char) max( 0.0, 
				//					(double) (cost_map[i + map_size_x * j]) 
				//					- (double)(get_IG(IG_map, i, j, dim)) / (4.0 * dim * dim)
				//					);

			}
		}
	}

	// ensure map boundaries are solid
	for (int i = 0; i < map_size_x; i++) {
		elev_map[i] = OBS16;
		elev_map[i + map_size_x * (map_size_y - 1)] = OBS16;
		cost_map[i] = OBSTACLE;
		cost_map[i + map_size_x * (map_size_y -1)] = OBSTACLE;
		cover_map[i] = KNOWN;
		cover_map[i + map_size_x * (map_size_y -1)] = KNOWN;
	}

	for (int j = 0; j < map_size_y; j++) {
		elev_map[j * map_size_x] = OBS16;
		elev_map[(map_size_x - 1) + j * map_size_x] = OBS16;
		cost_map[j * map_size_x] = OBSTACLE;
		cost_map[(map_size_x - 1) + j * map_size_x] = OBSTACLE;
		cover_map[j * map_size_x] = KNOWN;
		cover_map[(map_size_x - 1) + j * map_size_x] = KNOWN;
	}

//	memcpy((void *)real_cost_map, (void *)cost_map, map_size_x*map_size_y * (sizeof(unsigned char)));
	memcpy((void *)real_cover_map, (void *)cover_map, map_size_x*map_size_y * (sizeof(unsigned char)));

	gettimeofday(&tv_stop, NULL);
	time_ms=(tv_stop.tv_sec-tv_start.tv_sec)*1000+(tv_stop.tv_usec-tv_start.tv_usec)/1000;
	elap_time_ms=(tv_stop.tv_sec-tv_prev.tv_sec)*1000+(tv_stop.tv_usec-tv_prev.tv_usec)/1000;
	cout << time_ms << " elapsed " <<  elap_time_ms << "                                            time before dijkstra "  << endl;
	tv_prev = tv_stop;			

	int * dijkstra = new int[map_size_x * map_size_y * NUMROBOTS];

	GP_threads calc_dijkstra[NUMROBOTS];

	cout << " start thread for robot " <<endl;
	for (int RID=0; RID < NUMROBOTS; RID++) {
		calc_dijkstra[RID].start(RID,  dijkstra,  (int)(POSEX[RID]/map_cell_size),  (int)(POSEY[RID]/map_cell_size), this);
	}

	// wait for all threads to finish
	//for (int RID=0; RID < NUMROBOTS; RID++) {
	//calc_dijkstra[RID].join();
	//}

	gettimeofday(&tv_stop, NULL);
	time_ms=(tv_stop.tv_sec-tv_start.tv_sec)*1000+(tv_stop.tv_usec-tv_start.tv_usec)/1000;
	elap_time_ms=(tv_stop.tv_sec-tv_prev.tv_sec)*1000+(tv_stop.tv_usec-tv_prev.tv_usec)/1000;
	cout << time_ms << " elapsed " <<  elap_time_ms << "                                            time after dijkstra "  << endl;
	tv_prev = tv_stop;

	for (int RID = 0; RID < NUMROBOTS; RID++) {
		if (ROBOTAVAIL[RID]) {
			// make sure this thread is complete
			calc_dijkstra[RID].join();
			cout << endl << endl << "Starting planning for robot number " << RID << endl << endl;

			gettimeofday(&tv_stop, NULL);
			time_ms=(tv_stop.tv_sec-tv_start.tv_sec)*1000+(tv_stop.tv_usec-tv_start.tv_usec)/1000;
			elap_time_ms=(tv_stop.tv_sec-tv_prev.tv_sec)*1000+(tv_stop.tv_usec-tv_prev.tv_usec)/1000;
			cout << time_ms << " elapsed " <<  elap_time_ms << "                                            time begin each RID loop "  << endl;
			tv_prev = tv_stop;

			// update position and adjust cover map if desired
			fix_cover(RID);

			unsigned int * IG_map = new unsigned int[map_size_x * map_size_y];

			//calculate the IG at each point based on current coverage map
			//bool IG_above_thres;
			calc_all_IG(IG_map);

			find_frontier(IG_map, dijkstra, RID);

			if (DISPLAY_OUTPUT) {cout << "Robot pose x= " << robot_x << " xx=" << robot_xx << " y=" << robot_y << " yy=" << robot_yy << endl;}

			//	for (int qq = -5; qq <= 5; qq++) {
			//		for (int ww = -5; ww <= 5; ww++) {
			//			cout << (int)cost_map[robot_x+qq+map_size_x*(robot_y+ww)] << "/"<< (int)cover_map[robot_x+qq+map_size_x*(robot_y+ww)] << "/" << (int)inflated_cost_map[robot_x+qq+map_size_x*(robot_y+ww)] << " ";
			//		}
			// cout << endl;
			//}

			double best_score = 0; // tracks best score this run
			int x_target, y_target;//, best_x, best_y;
			vector<Traj_pt_s> test_traj; // temp trajectory
			//vector<int> traj_score_l; // storage for score at each point along trajectory for post processing
			//vector<int> traj_score_r;
			unsigned char * temp_cover_map = new unsigned char[map_size_x * map_size_y]; // non-const storage for each possible goal

			clock_t start, finish;
			start = finish = clock();

			// support for calculating path to desired goal (do we need?)
			//		if (goal_x != -1) {
			// set goal
			//			if (DISPLAY_OUTPUT) {cout << "determining path to assigned goal" << endl;}
			//			return_path((int) (goal_x / map_cell_size), (int) (goal_y / map_cell_size), dijkstra, traj[RID], RID);

			//		} else {
			//find good point
			//clear old traj
			traj[RID].clear();
			//		}
			gettimeofday(&tv_stop, NULL);
			time_ms=(tv_stop.tv_sec-tv_start.tv_sec)*1000+(tv_stop.tv_usec-tv_start.tv_usec)/1000;
			elap_time_ms=(tv_stop.tv_sec-tv_prev.tv_sec)*1000+(tv_stop.tv_usec-tv_prev.tv_usec)/1000;
			cout << time_ms << " elapsed " <<  elap_time_ms << "                                            time after frontier before timed loop "  << endl;
			tv_prev = tv_stop;
	
			bool first_run_flag = true;

			while (finish-start < GP_PLAN_TIME*CLOCKS_PER_SEC) { // while less than plan time  (XP should not have 0.5)
			
				cout << ".";// << IG_above_thres;

				// temp map for tracking changes during runs
				memcpy((void *) temp_cover_map, (void *) cover_map, map_size_x	* map_size_y * (sizeof(unsigned char)));

				if (!first_run_flag) {	sample_point(x_target, y_target);if (DISPLAY_OUTPUT) {cout << "normal flag " << x_target  << "," << y_target << endl;} }
				else {
					first_run_flag = false;
					int rx = robot_goals[RID*2];
					int ry = robot_goals[RID*2+1];

				if (DISPLAY_OUTPUT)	{ cout << "goals 1st time " << rx << "," << ry << endl;}
					if ((dijkstra[rx + map_size_x * ry + map_size_x*map_size_y*RID] < DIJKSTRA_LIMIT) 
							&& (real_cover_map[rx + map_size_x * ry] == KNOWN)
								&& ((real_cover_map[(rx + 1) + map_size_x * (ry)] != KNOWN) 
									|| (real_cover_map[(rx - 1) + map_size_x * (ry)] != KNOWN)
									|| (real_cover_map[(rx) + map_size_x * (ry + 1)] != KNOWN) 
									|| (real_cover_map[(rx) + map_size_x * (ry - 1)] != KNOWN)) ) {
						x_target = rx;
						y_target = ry;
						if (DISPLAY_OUTPUT) {cout << "going for previous" << endl;}

					}
					else { sample_point(x_target, y_target); if (DISPLAY_OUTPUT) {cout << "normal 1st " << x_target  << "," << y_target << endl;} }
				}


						if (DISPLAY_OUTPUT) {cout << x_target << "," << y_target << " is potential goal";}

				// if return is -1, -1 then no more points found return null trajectory
				if ((x_target == -1) && (y_target == -1)) {
					cout << " No valid goal.  Break from timed while loop " << endl;
					break;
				}

				// determine path to each goal point
				double dist;
				dist = return_path(x_target, y_target, dijkstra, test_traj, RID);

				if (DISPLAY_OUTPUT) {cout << " and the distance is " << dist;}

				// determine gain from each possible goal point
				double temp_score = 0;
				for (int current_loc = 1; current_loc < test_traj.size(); current_loc++) {
					// determine the direction of travel in each axis
					int x_dir = test_traj[current_loc].x - test_traj[current_loc - 1].x + 1;
					int y_dir = test_traj[current_loc].y - test_traj[current_loc - 1].y + 1;
					int direction = dir[x_dir][y_dir];
					if (direction != NOMOVE) {
						// pass current location and inflated map to raycaster returns score
						temp_score += cast_all_rays(test_traj[current_loc].x,
								test_traj[current_loc].y, temp_cover_map, elev_map,
								SVR[direction], FVL[direction]);
						//					temp_score += cast_all_rays(test_traj[current_loc].x,
						//							test_traj[current_loc].y, temp_cover_map, elev_map,
						//							SVL[direction], FVL[direction]);
					} // if !NOMOVE
				} //for current_loc

				// store as traj if best score per distance traveled
				//if ((heading_bias(x_target, y_target)*((temp_score*DIST_GAIN)+1.0)/ (dist*(1.0-DIST_GAIN)+0.1)) > best_score) {


				if (bias(RID, x_target, y_target) *IG_dist_ratio((int)temp_score, dist) > best_score) {
					cout << "****";
					//traj = test_traj;
					best_score = bias(RID, x_target, y_target)*IG_dist_ratio((int)temp_score, dist);
					traj[RID].swap(test_traj);
					//	best_score =(heading_bias(x_target, y_target)*((temp_score*DIST_GAIN)+1.0)/ (dist*(1.0-DIST_GAIN)+0.1));
					//if (DISPLAY_OUTPUT) {
					cout << endl << "pt " << x_target << "," << y_target << " with ray score:" << temp_score << " dist:" << dist << " bias:" << bias(RID, x_target, y_target) << " and IG/dist ratio:" << IG_dist_ratio((int)temp_score, dist) << " region:" << (int)region_map[x_target + map_size_x*y_target] << " total score:" << best_score <<endl;// bias(RID, x_target, y_target)*IG_dist_ratio((int)temp_score, dist) << endl;



				}
				if (DISPLAY_OUTPUT) {
					cout << "pt " << x_target << "," << y_target << " with ray score:" << temp_score << " dist:" << dist << " bias:" << bias(RID, x_target, y_target) << " and IG/dist ratio:" << IG_dist_ratio((int)temp_score, dist) << " region:" << (int)region_map[x_target + map_size_x*y_target] << " total score:" << bias(RID, x_target, y_target)*IG_dist_ratio((int)temp_score, dist) << endl;
				}
				//finish time
				finish = clock();
				} // while time remaining
			if (DISPLAY_OUTPUT) {cout << "GP done looking at points" << endl;}
			//	} // else find good point
			// select highest scoring trajectory after XX seconds
			//best_score = 0;
			if (traj[RID].empty()) {
				cout << " traj is empty - no valid trajectory" << endl;
				return;
			} else {
				cout << "final best goal " << traj[RID].back().x << "," << traj[RID].back().y
					<< " size " << traj[RID].size() << endl;
			}

			// save goal locations 
			robot_goals[RID*2] = traj[RID].back().x;
			robot_goals[RID*2+1] = traj[RID].back().y;

			traj[RID][0].xx = traj[RID][0].x * map_cell_size;
			traj[RID][0].yy = traj[RID][0].y * map_cell_size;

			for (int current_loc = 1; current_loc < traj[RID].size(); current_loc++) {
				//cout << "loc " <<  traj[current_loc].x << "," << traj[current_loc].y << endl;
				// determine the direction of travel in each axis
				int x_dir = traj[RID][current_loc].x - traj[RID][current_loc - 1].x + 1;
				int y_dir = traj[RID][current_loc].y - traj[RID][current_loc - 1].y + 1;
				int direction = dir[x_dir][y_dir];

				//cout << direction << ": dir 0 is along x-axis" << SVR[direction] << " " << FVR[direction] << " " << FVL[direction] << endl;
				if (direction != NOMOVE) {
					// pass current location and inflated map to raycaster returns score
					cast_all_rays(traj[RID][current_loc].x,	traj[RID][current_loc].y, cover_map, elev_map,SVR[direction], FVL[direction]);
				
					traj[RID][current_loc].xx = traj[RID][current_loc].x * map_cell_size;
					traj[RID][current_loc].yy = traj[RID][current_loc].y * map_cell_size;

				} // if !NOMOVE
			} //for current_loc

			if (!traj[RID].empty())
				if (DISPLAY_OUTPUT) {
					cout << "goal point " << traj[RID].back().x << "," << traj[RID].back().y
						<< " cost val = " << (int) cost_map[traj[RID].back().x + map_size_x* traj[RID].back().y];
				}

			// write results to disk - cover map shows what was presumed to have been seen during traversal
			if (WRITE_FILES) {
				if (DISPLAY_OUTPUT) {printf(" writing map files to disk\n");}
			//	writefiles(cover_map, inflated_cost_map, elev_map, "Map_out.txt",
			//			map_size_x, map_size_y);
				writefileextra(dijkstra, "Map_extra.txt", map_size_x, map_size_y);
			//	writefiletraj(best_score, traj[RID], "Map_traj.txt");
			char str[50];
			sprintf(str, "Map%d.bmp", RID);
				writeBMP(cover_map, inflated_cost_map, &dijkstra[map_size_x*map_size_y*RID], map_size_x, map_size_y , traj[RID], str) ;
			}

			// set variables and allocate new storage for trajectory array of floats
			//gp_traj.num_traj_pts = traj[RID].size();
			//gp_traj.traj_dim = GP_TRAJ_DIM;

			//	delete[] gp_traj.traj_array;
			//	gp_traj.traj_array = new float[gp_traj.num_traj_pts * GP_TRAJ_DIM];

			//set traj data into array of floats
			//	for (int q = 0; q < gp_traj.num_traj_pts; q++) {
			//		gp_traj.traj_array[q * GP_TRAJ_DIM] = (float) traj[RID][q].x
			//				* map_cell_size;
			//		gp_traj.traj_array[q * GP_TRAJ_DIM + 1] = (float) traj[RID][q].y
			//				* map_cell_size;
			//		gp_traj.traj_array[q * GP_TRAJ_DIM + 2] = traj[RID][q].theta;
			//		gp_traj.traj_array[q * GP_TRAJ_DIM + 3] = traj[RID][q].velocity;
			//		gp_traj.traj_array[q * GP_TRAJ_DIM + 4] = traj[RID][q].right_pan;
			//		gp_traj.traj_array[q * GP_TRAJ_DIM + 5] = traj[RID][q].left_pan;
			//	}

			//publish message to screen and to server
			//IPC_printData(IPC_msgFormatter (GP_TRAJECTORY_MSG), stdout, &gp_traj);
			//	IPC_publishData(GP_TRAJECTORY_MSG, &gp_traj); // needed for XP

			// frees recalculated arrays
			delete [] temp_cover_map;
			delete [] IG_map;
			//printf("done deleting temp storage\n");
	}	// if robot is available
	else { printf("Robot %d is not avail\n", RID); }
	gettimeofday(&tv_stop, NULL);
	time_ms=(tv_stop.tv_sec-tv_start.tv_sec)*1000+(tv_stop.tv_usec-tv_start.tv_usec)/1000;
	elap_time_ms=(tv_stop.tv_sec-tv_prev.tv_sec)*1000+(tv_stop.tv_usec-tv_prev.tv_usec)/1000;
	cout << time_ms << " elapsed " <<  elap_time_ms << "                                            time after loop " <<  endl;
	tv_prev = tv_stop;

} // for all robots
// frees un-needed arrays

delete [] dijkstra;
delete [] obs_array;
delete [] nonfree_array;
delete [] obs_ptr_array;
delete [] nonfree_ptr_array;
}

bool GPLAN::gplan_init(GP_PLANNER_PARAMETER * gp_planner_param_p) {
//		GP_ROBOT_PARAMETER * gp_robot_parameter_p) {
//		GP_FULL_UPDATE * gp_full_update_p) {
	// function to initialize map and robot data, read in initial full map, and set highlevel planning parameters
	//function to handle map and robot parameters and loads full map

	//update planner variables
	GP_PLAN_TIME = gp_planner_param_p->GP_PLAN_TIME; // seconds to allow for planning
		cout << ">GP_PLAN_TIME = " << GP_PLAN_TIME << endl;
	WRITE_FILES = gp_planner_param_p->WRITE_FILES; // flag to write files out
		cout << " WRITE_FILES = " << WRITE_FILES << endl;
	DISPLAY_OUTPUT = gp_planner_param_p->DISPLAY_OUTPUT; // flag to display any output
		cout << " DISPLAY_OUTPUT = " << DISPLAY_OUTPUT << endl;
	if (abs(gp_planner_param_p->SENSORWIDTH) < 2*M_PI) {SENSORWIDTH = abs(gp_planner_param_p->SENSORWIDTH);}
		cout << " SENSORWIDTH = " << SENSORWIDTH << endl;
	if ((gp_planner_param_p->DIST_GAIN >=0) && (gp_planner_param_p->DIST_GAIN <1)) {DIST_GAIN = gp_planner_param_p->DIST_GAIN;}
		cout << " DIST_GAIN = " << DIST_GAIN << endl;
	if ((gp_planner_param_p->THETA_BIAS >=0) && (gp_planner_param_p->THETA_BIAS <=1)) {THETA_BIAS = gp_planner_param_p->THETA_BIAS;}
		cout << " THETA_BIAS = " << THETA_BIAS << endl;
	// desired min and max ranges to nearest other robot in the same region
	if (gp_planner_param_p->MIN_RANGE >=0) {MIN_RANGE = gp_planner_param_p->MIN_RANGE;}
		cout << " MIN_RANGE = " << MIN_RANGE << endl;
	if (gp_planner_param_p->MAX_RANGE >=0) {MAX_RANGE = gp_planner_param_p->MAX_RANGE;}
		cout << " MAX_RANGE = " << MAX_RANGE << endl;
	// penalty per cell for being outside desird range (delta cells * DIST_PENALTY)
	//if (gp_planner_param_p->DIST_PENALTY >=0)  
	DIST_PENALTY = gp_planner_param_p->DIST_PENALTY;
	cout << " DIST_PENALTY = " << DIST_PENALTY << endl;
	// penalty for being in the same region as another robot (does not apply for outside)
	if (gp_planner_param_p->REGION_PENALTY >=0) {REGION_PENALTY = gp_planner_param_p->REGION_PENALTY;}
		cout << " REGION_PENALTY = " << REGION_PENALTY << endl;

	// update number of robots and associated variables
	NUMROBOTS = gp_planner_param_p->NR;
	cout << "There are " << NUMROBOTS << " robots" << endl;
	delete [] ROBOTAVAIL;
	ROBOTAVAIL = new bool[NUMROBOTS];
	for (int idx=0; idx < NUMROBOTS; idx++) { ROBOTAVAIL[idx] = 0;}

	delete [] robot_goals;
	robot_goals = new int[NUMROBOTS*2];
	for (int idx=0; idx < NUMROBOTS*2; idx++) { robot_goals[idx] = 1;}

	delete [] POSEX;
	delete [] POSEY;
	delete [] POSETHETA;
	POSEX = new double[NUMROBOTS];
	POSEY = new double[NUMROBOTS];
	POSETHETA = new double[NUMROBOTS];

	traj.resize(NUMROBOTS);

	//update size variables
	map_cell_size = gp_planner_param_p->map_cell_size;
	cout << " Cells are " << map_cell_size <<  "m square" << endl;

	//update size variables
	map_size_x = gp_planner_param_p->map_size_x;
	map_size_y = gp_planner_param_p->map_size_y;
	cout << "The maps are " << map_size_x << " x " << map_size_y << endl;

	//stores new robot parameters
	sensor_radius = gp_planner_param_p->sensor_radius;
	sensor_height = gp_planner_param_p->sensor_height;
	//	cout << " The robot can go " << MAX_VELOCITY << " m/s and turn at " << MAX_TURN_RATE << " rad/sec.  The sensor is " << sensor_height << " cm high and can see " << sensor_radius << " m" << endl;

	// establish sensor endpoints
//	int sensor_int_radius = (int) (sensor_radius / map_cell_size);
	rasterCircle((int) (sensor_radius / map_cell_size));

	//determine start and stop vector numbers for each direction
	int delta_vec = (int)(NUMVECTORS * SENSORWIDTH / (4.0 * M_PI)); // half viewing angle width of vectors
	int cardinal_vec = (int)(NUMVECTORS / 8.0); // 45 degrees worth of vectors
	for (int i = 0; i < 8; i++) {
		FVR[i] = SVL[i] = ValidVec(cardinal_vec * i);
		FVL[i] = ValidVec(cardinal_vec * i + delta_vec);
		SVR[i] = ValidVec(cardinal_vec * i - delta_vec);
		cout << " vectors " << SVR[i] << " " << FVR[i] << " " << SVL[i] << " "
			<< FVL[i] << endl;
	}

	//for nomove set the start and finish vectors to a full circle
	SVR[8] = SVL[8] = 0;
	FVR[8] = FVL[8] = NUMVECTORS - 1;

	//determines outer bounding circle of robot for inflation purposes
	double max_dist = 0;
	//for (int i = 0; i < gp_robot_parameter_p->I_DIMENSION; i++) {
		//double dist = sqrt(pow(gp_robot_parameter_p->PerimeterArray[i
					//* gp_robot_parameter_p->J_DIMENSION], 2) + pow(
						//gp_robot_parameter_p->PerimeterArray[i
						//* gp_robot_parameter_p->J_DIMENSION + 1], 2));
		//cout << " data point " << i << " is " << dist << " away" << endl;
		//if (dist > max_dist) {
			//max_dist = dist;
		//}
	//}

	max_dist = gp_planner_param_p->perimeter_radius;
	inflation_size = max_dist / map_cell_size;

	//allocate memory for the maps according to the size variables
	bool val = map_alloc();

	cout << "done alloc ";
/*
	// copy data to local map
	memcpy((void *) cover_map, (void *) gp_full_update_p->coverage_map,	map_size_x * map_size_y * sizeof(unsigned char));
	memcpy((void *) real_cover_map, (void *) gp_full_update_p->coverage_map, map_size_x * map_size_y * sizeof(unsigned char));
	memcpy((void *) cost_map, (void *) gp_full_update_p->cost_map, map_size_x * map_size_y * sizeof(unsigned char));
	memcpy((void *) elev_map, (void *) gp_full_update_p->elev_map, map_size_x * map_size_y * sizeof(int16_t));
	memcpy((void *) region_map, (void *) gp_full_update_p->region_map, map_size_x * map_size_y * sizeof(unsigned char));
*/
	cout << "done" << endl;
}

vector < vector<Traj_pt_s> > GPLAN::gplan_plan(GP_POSITION_UPDATE * gp_position_update_p,
		GP_FULL_UPDATE * gp_full_update_p) {
	cout << "starting library planning cycle" << endl;
	//function replans based on updated short map and position update
	gettimeofday(&tv_start, NULL);

	cout << "copying data into static storage" << endl;
	//place data into the correct arrays
	memcpy((void *) cover_map, (void *) gp_full_update_p->coverage_map,	map_size_x * map_size_y * sizeof(unsigned char));
//	memcpy((void *) real_cover_map, (void *) gp_full_update_p->coverage_map, map_size_x * map_size_y * sizeof(unsigned char));
	memcpy((void *) cost_map, (void *) gp_full_update_p->cost_map, map_size_x * map_size_y * sizeof(unsigned char));
	memcpy((void *) elev_map, (void *) gp_full_update_p->elev_map, map_size_x * map_size_y * sizeof(int16_t));
	memcpy((void *) region_map, (void *) gp_full_update_p->region_map, map_size_x * map_size_y * sizeof(unsigned char));
	//for (int idx = 0; idx < NUMROBOTS; idx++) { 
	//		memcpy((void *)&robot_cover_map[idx*map_size_x*map_size_y], (void *)real_cover_map, map_size_x*map_size_y*sizeof(unsigned char));
	//	}

	cout << "prepping other variables" << endl;
	

		//map variables
	for (int idx=0; idx < NUMROBOTS; idx++) { ROBOTAVAIL[idx]= (bool)gp_position_update_p->avail[idx];}

	//updates the stored robot position
	for (int idx = 0; idx < NUMROBOTS; idx++) {
	POSEX[idx] = gp_position_update_p->x[idx];
	POSEY[idx] = gp_position_update_p->y[idx];
		POSETHETA[idx] = gp_position_update_p->theta[idx];
		traj[idx].reserve(300);	
		//cout << idx << " traj size =" << traj[idx].size() << endl;
		cout << "robot " << idx << " is at " << POSEX[idx] << "," << POSEY[idx] << endl;
	}

	cout << "starting actual planner" << endl;
	global_planner(-1, -1, -1);
	cout << endl;  
	//cout << "traj size " << traj.size();
	for (int idx = 0; idx < NUMROBOTS; idx++) {
		cout << " " << idx << "-" << traj[idx].size();
	}
	cout << endl;  

	gettimeofday(&tv_stop, NULL);
	time_ms=(tv_stop.tv_sec-tv_start.tv_sec)*1000+(tv_stop.tv_usec-tv_start.tv_usec)/1000;
	elap_time_ms=(tv_stop.tv_sec-tv_prev.tv_sec)*1000+(tv_stop.tv_usec-tv_prev.tv_usec)/1000;
	cout << "done with planner " << time_ms << " elapsed " <<  elap_time_ms << endl;
	tv_prev = tv_stop;

	return traj;
}

/*
 static void GP_MAP_DATA_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
 //function to handle map parameter update messages
 GP_MAP_DATA_PTR gp_map_data_p;
 IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_map_data_p);
 printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);
	static int count=0;
	count++;
	printf("map count is %d\n", count);
 //function to print message to screen
 //IPC_printData(IPC_msgInstanceFormatter(msgRef), stdout, gp_map_data_p);

 //update size variables
 map_size_x = gp_map_data_p->map_size_x;
 map_size_y = gp_map_data_p->map_size_y;
 map_size_x = gp_map_data_p->map_size_x;
 map_size_y = gp_map_data_p->map_size_y;
 map_size_x = gp_map_data_p->map_size_x;
 map_size_y = gp_map_data_p->map_size_y;
 map_cell_size = gp_map_data_p->map_cell_size;
 map_cell_size = gp_map_data_p->map_cell_size;
 map_cell_size = gp_map_data_p->map_cell_size;

 //initialize astar vectors for later use
 Astarpoint_init(map_size_x, map_size_y);

 //allocates space for the maps
 map_alloc();

 //sets greedy threshold
 HIGH_IG_THRES = (int)(IG_RATIO*map_size_x*map_size_y*KNOWN);

 //frees memory used by the message
 IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) gp_map_data_p);
 IPC_freeByteArray(callData);
 }
 */

/*
 static void GP_ROBOT_PARAMETER_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
 // function handles robot parameter update messages
 GP_ROBOT_PARAMETER_PTR gp_robot_parameter_p;
 IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_robot_parameter_p);
 printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

 //stores new parameters
 MAX_VELOCITY = gp_robot_parameter_p->MAX_VELOCITY;
 MAX_TURN_RATE = gp_robot_parameter_p->MAX_TURN_RATE;
 sensor_radius = gp_robot_parameter_p->sensor_radius;
 sensor_height = gp_robot_parameter_p->sensor_height;

 // establish sensor endpoints
 int	sensor_int_radius = (int)(sensor_radius/map_cell_size);
 rasterCircle((int)(sensor_radius/map_cell_size));

 //determine start and stop vector numbers for each direction
 int delta_vec = NUMVECTORS*SENSORWIDTH/(2*M_PI); // 120 degrees worth of vectors
 int cardinal_vec = NUMVECTORS/8; // 45 degrees worth of vectors
 for(int i=0; i<8; i++) {
 FVR[i] = SVL[i] = ValidVec(cardinal_vec*i);
 FVL[i] = ValidVec(cardinal_vec*i+delta_vec);
 SVR[i] = ValidVec(cardinal_vec*i-delta_vec);

 cout << " vectors " << SVR[i] << " " << FVR[i] << " " << SVL[i] << " " << FVL[i] << endl;

 }

 //for nomove set the start and finish vectors to a full circle
 SVR[8] = SVL[8] = 0;
 FVR[8] = FVL[8] = NUMVECTORS-1;

 //determines outer bounding circle of robot for inflation purposes
 float max_dist=0;
 for (int i=0;i<gp_robot_parameter_p->I_DIMENSION; i++) {
 float dist = sqrt(pow(gp_robot_parameter_p->PerimeterArray[i*gp_robot_parameter_p->J_DIMENSION], 2)+ pow(gp_robot_parameter_p->PerimeterArray[i*gp_robot_parameter_p->J_DIMENSION+1], 2));
 printf(" data point %d is %f away\n", i, dist);
 if (dist > max_dist) {max_dist = dist;}
 }
 inflation_size = max_dist/map_cell_size;

 //function to print message to screen
 //IPC_printData(IPC_msgInstanceFormatter(msgRef), stdout, gp_robot_parameter_p);

 //free the memory used by the message
 IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) gp_robot_parameter_p);
 IPC_freeByteArray(callData);
 }
 */

/*
 static void GP_POSITION_UPDATE_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
 //function handles the position update messages
 GP_POSITION_UPDATE_PTR gp_position_update_p;
 IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_position_update_p);
 printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

 //updates the stored robot position as a float
 robot_xx=gp_position_update_p->x;
 robot_yy=gp_position_update_p->y;

 // .... and as an int in cells
 int temp_robot_x= (int)(robot_xx/map_cell_size);
 int temp_robot_y= (int)(robot_yy/map_cell_size);

 //updtes orientation
 theta = gp_position_update_p->theta;

 //function to print message data to screen
 IPC_printData(IPC_msgInstanceFormatter(msgRef), stdout, gp_position_update_p);

 //calls the global planner to get (and publish) a new plan
 if (OnMap(temp_robot_x, temp_robot_y) && ( temp_robot_x !=0) && (temp_robot_y !=0)) {
 robot_x = temp_robot_x;
 robot_y = temp_robot_y;
 global_planner(-1, -1, -1);
 }
 else { cout << " Invalid position received " << endl; }

 //frees memory used by message
 IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *)gp_position_update_p);
 IPC_freeByteArray(callData);
 }
 */

/*
 static void GP_GOAL_ASSIGN_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
 //function handles the position update messages
 GP_GOAL_ASSIGN_PTR gp_goal_assign_p;
 IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_goal_assign_p);
 printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

 //updates the stored robot position as a float
 robot_xx=gp_goal_assign_p->x;
 robot_yy=gp_goal_assign_p->y;

 // .... and as an int in cells
 robot_x= (int)(robot_xx/map_cell_size);
 robot_y= (int)(robot_yy/map_cell_size);

 //updates orientation
 theta = gp_goal_assign_p->theta;

 //function to print message data to screen
 IPC_printData(IPC_msgInstanceFormatter(msgRef), stdout, gp_goal_assign_p);

 //calls the global planner to get (and publish) a new plan
 global_planner(gp_goal_assign_p->goal_x, gp_goal_assign_p->goal_y,  gp_goal_assign_p->goal_theta );

 //frees memory used by message
 IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *)gp_goal_assign_p);
 IPC_freeByteArray(callData);
 }
 */

/*
 static void GP_FULL_UPDATE_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
 //function handles full map updates
 GP_FULL_UPDATE_PTR gp_full_update_p;
 IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_full_update_p);
 printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

 // function to print received message to screen
 //IPC_printData(IPC_msgInstanceFormatter(msgRef), stdout, gp_full_update_p);
 //update size variables
 map_size_x = gp_full_update_p->sent_cost_x;
 map_size_y = gp_full_update_p->sent_cost_y;
 map_size_x = gp_full_update_p->sent_cover_x;
 map_size_y = gp_full_update_p->sent_cover_y;
 map_size_x = gp_full_update_p->sent_elev_x;
 map_size_y = gp_full_update_p->sent_elev_y;
  global_x_offset = gp_full_update_p->UTM_x;
  global_y_offset = gp_full_update_p->UTM_y;
  printf("x_offset=%f, y_offset=%f\n",global_x_offset,global_y_offset);

 //allocate memory for the maps according to the size variables
 map_alloc();
 //initialize the astar vectors for later use
 Astarpoint_init(map_size_x, map_size_y);
 //sets greedy threshold
 HIGH_IG_THRES = (int)(IG_RATIO*map_size_x*map_size_y*KNOWN);

 // copy data to local map
 memcpy((void *)cover_map, (void *)gp_full_update_p->coverage_map, map_size_x*map_size_y*sizeof(unsigned char));
	memcpy((void *)real_cover_map, (void *)gp_full_update_p->coverage_map, map_size_x*map_size_y*sizeof(unsigned char));

 memcpy((void *)cost_map, (void *)gp_full_update_p->cost_map, map_size_x*map_size_y*sizeof(unsigned char));
 memcpy((void *)elev_map, (void *)gp_full_update_p->elev_map, map_size_x*map_size_y*sizeof(int16_t));

 //free memory used by message
 IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) gp_full_update_p);
 IPC_freeByteArray(callData);
 }
 */
/*
static void GP_MAGIC_MAP_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	//function handles full map updates
	GP_MAGIC_MAP_PTR msg_p;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&msg_p);

	delete [] cost_map;
	delete [] elev_map;
	delete [] real_cover_map;
map_cell_size = map_cell_size = map_cell_size = msg_p->resolution;
	convertMap(msg_p, true, msg_p->resolution, &cost_map, &elev_map, &real_cover_map, &map_size_x, &map_size_y);

	printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

	// function to print received message to screen
	//IPC_printData(IPC_msgInstanceFormatter(msgRef), stdout, gp_full_update_p);
	//update size variables

	map_size_x = map_size_x;
	map_size_y = map_size_y;
	map_size_x = map_size_x;
	map_size_y = map_size_y;
	global_x_offset = msg_p->UTM_x;
	global_y_offset = msg_p->UTM_y;
	printf("map size is %d x %d   ", map_size_x, map_size_y);
	printf("x_offset=%f, y_offset=%f\n",global_x_offset,global_y_offset);

	//for (int j=0; j<map_size_y; j++) {
		//for (int i=0; i<map_size_x; i++) {
			//if (cost_map[i+map_size_x*j] !=0) {	printf("i=%d j=%d cost val =%d ", i,j,(int)cost_map[i + map_size_x*j]);}
			//if (cover_map[i+map_size_x*j] !=0) {	printf("i=%d j=%d cover val =%d ", i,j,(int)cover_map[i + map_size_x*j]);}
			//if (elev_map[i+map_size_x*j] !=0) {	printf("i=%d j=%d elev val =%d \n", i,j,(int)elev_map[i + map_size_x*j]);}
		//}
		//printf("\n");
	//}

	//allocate memory for the maps according to the size variables
	//remove old storage
	delete [] inflated_cost_map;
	delete [] cost_map_pa;
	delete [] inf_cost_map_pa;
	delete [] robot_cover_map;
	delete [] cover_map;

	//allocate new storage
	robot_cover_map = new unsigned char[map_size_x*map_size_y*NUMROBOTS];
	inflated_cost_map = new unsigned char[map_size_x*map_size_y];
	cover_map = new unsigned char[map_size_x * map_size_y];	// non-const storage for each possible goal

	// set up pointer to array of pointers for [][] indexing of cost map
	cost_map_pa = new unsigned char*[map_size_y];
	inf_cost_map_pa = new unsigned char*[map_size_y];
	for (int j=0; j<map_size_y;j++) {
		cost_map_pa[j]=&cost_map[j*map_size_x];
		inf_cost_map_pa[j]=&inflated_cost_map[j*map_size_x];
	}

	//initialize the astar vectors for later use
	Astarpoint_init(map_size_x, map_size_y);
	//sets greedy threshold
	HIGH_IG_THRES = (int)(IG_RATIO*map_size_x*map_size_y*KNOWN);

	// copy data to local map
	//memcpy((void *)cover_map, (void *)gp_full_update_p->coverage_map, map_size_x*map_size_y*sizeof(unsigned char));
	//memcpy((void *)cover_map, (void *)real_cover_map, map_size_x*map_size_y*sizeof(unsigned char));
	for (int idx = 0; idx < NUMROBOTS; idx++) { 
		memcpy((void *)&robot_cover_map[idx*map_size_x*map_size_y], (void *)real_cover_map, map_size_x*map_size_y*sizeof(unsigned char));
	}
	//memcpy((void *)cost_map, (void *)gp_full_update_p->cost_map, map_size_x*map_size_y*sizeof(unsigned char));
	//memcpy((void *)elev_map, (void *)gp_full_update_p->elev_map, map_size_x*map_size_y*sizeof(int16_t));

	//free memory used by message
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) msg_p);
	IPC_freeByteArray(callData);
}

static void GP_ALL_POSE_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	//function handles the position update messages
	//static int count=0;
	//count++;
	//printf("pose count is now %d\n", count);
	GP_ALL_POSE_PTR gp_all_pose_p;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_all_pose_p);
	printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

	//updates the stored robot position as a float
	POSEX[0]=gp_all_pose_p->x1-global_x_offset;
	POSEY[0]=gp_all_pose_p->y1-global_y_offset;
	POSETHETA[0] = gp_all_pose_p->theta1;

	POSEX[1]=gp_all_pose_p->x2-global_x_offset;
	POSEY[1]=gp_all_pose_p->y2-global_y_offset;
	POSETHETA[1] = gp_all_pose_p->theta2;

	POSEX[2]=gp_all_pose_p->x3-global_x_offset;
	POSEY[2]=gp_all_pose_p->y3-global_y_offset;
	POSETHETA[2] = gp_all_pose_p->theta3;

cout << "pointer has " << gp_all_pose_p->x3 << "," << gp_all_pose_p->y3 << endl;

	//for (int idx=0; idx < NUMROBOTS; idx++) {
		//if (OnMap(POSEX[idx]/map_cell_size, POSEY[idx]/map_cell_size) ) {
			//ROBOTAVAIL[idx] = true;
		//}
		//else {
			//ROBOTAVAIL[idx] = false; 
//
		//}
		//printf("robot %d is avail = %d and at UTM = %3.1f, %3.1f  Cells = %d %d\n", idx, ROBOTAVAIL[idx], POSEX[idx], POSEY[idx], (int)(POSEX[idx]/map_cell_size), (int)(POSEY[idx]/map_cell_size));
	//}

				global_planner(-1, -1, -1);

printf("Waiting for next callback...\n");

	/*

	// .... and as an int in cells
	int temp_robot_x= (int)(robot_xx/map_cell_size);
	int temp_robot_y= (int)(robot_yy/map_cell_size);
	printf("wtf: %d %d\n", temp_robot_x, temp_robot_y);
	//updtes orientation
	theta = gp_position_update_p->theta;

	//function to print message data to screen
	IPC_printData(IPC_msgInstanceFormatter(msgRef), stdout, gp_position_update_p);

	//calls the global planner to get (and publish) a new plan
	if (OnMap(temp_robot_x, temp_robot_y) && ( temp_robot_x !=0) && (temp_robot_y !=0)) { 
	robot_x = temp_robot_x; 
	robot_y = temp_robot_y; 
	}
	else { cout << " Invalid position received " << endl; }
	*/
	//frees memory used by message
/*	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *)gp_all_pose_p);
	IPC_freeByteArray(callData);
}
*/
/*
 static void GP_SHORT_UPDATE_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
 // function handles short map updates
 GP_SHORT_UPDATE_PTR gp_short_update_p;
 IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_short_update_p);
 printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

 IPC_printData(IPC_msgInstanceFormatter(msgRef), stdout, gp_short_update_p);

 //variables for map coordinates
 int lly = gp_short_update_p->y_cost_start;
 int llx = gp_short_update_p->x_cost_start;
 int sizey = gp_short_update_p->sent_cost_y;
 int sizex = gp_short_update_p->sent_cost_x;

 //place data into the correct arrays
 for(int j = 0; j< sizey; j++){
 for (int i=0;i< sizex;i++) {
 if (OnMap(i+llx, j+lly)) {
 cover_map[(i+llx)+map_size_x*(j+lly)] = gp_short_update_p->coverage_map[i+sizex*j];
 cost_map[(i+llx)+map_size_x*(j+lly)] = gp_short_update_p->cost_map[i+sizex*j];
 elev_map[(i+llx)+map_size_x*(j+lly)] = gp_short_update_p->elev_map[i+sizex*j];
 }
 }
 }
 //free the message data
 IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) gp_short_update_p);
 IPC_freeByteArray(callData);
 }
 */

/*static void stdinHnd (int fd, void *clientData) {
 // function handles keyboard input for the purpose of writing to file or quitting
 char inputLine[81];
 fgets(inputLine, 80, stdin);
 switch (inputLine[0]) {
 case 'q': case 'Q':
 IPC_disconnect();
 exit(0);
 case 'f': case 'F':
 writefiles(cover_map, inflated_cost_map, elev_map, map_size_x, map_size_y);
 //writefileextra(dijkstra, map_size_x, map_size_y);
 //writefiletraj(best_score, traj);
 break;
 default:
 printf("stdinHnd [%s]: Received %s", (char *)clientData, inputLine);
 fflush(stdout);
 }
 printf("\n'f' to write to file\n'q' to quit\n");
 }
 */

/*

 int main (void) {
 //initialize variables and seed random number generator
 gp_traj.traj_array = new float[1];
 srand((int)(time(NULL)));

 //stuff to initialize system in the event no init message comes
 //initialize astar vectors for later use
 Astarpoint_init(map_size_x, map_size_y);
 //sets greedy threshold
 HIGH_IG_THRES = (int)(IG_RATIO*map_size_x*map_size_y*KNOWN);
 // establish sensor endpoints
 int	sensor_int_radius = (int)(sensor_radius/map_cell_size);
 rasterCircle((int)(sensor_radius/map_cell_size));

 //determine start and stop vector numbers for each direction
 int delta_vec = NUMVECTORS*SENSORWIDTH/(2*M_PI); // 120 degrees worth of vectors
 int cardinal_vec = NUMVECTORS/8; // 45 degrees worth of vectors
 for(int i=0; i<8; i++) {
 FVR[i] = SVL[i] = ValidVec(cardinal_vec*i);
 FVL[i] = ValidVec(cardinal_vec*i+delta_vec);
 SVR[i] = ValidVec(cardinal_vec*i-delta_vec);

 cout << " vectors " << SVR[i] << " " << FVR[i] << " " << SVL[i] << " " << FVL[i] << endl;

 }

 //for nomove set the start and finish vectors to a full circle
 SVR[8] = SVL[8] = 0;
 FVR[8] = FVL[8] = NUMVECTORS-1;

 // Connect to the central server
 printf("\nIPC_connect(%s)\n", MODULE_NAME);
 IPC_connect(MODULE_NAME);

 // Define the messages that this module publishes
 printf("\nIPC_defineMsg(%s, IPC_VARIABLE_LENGTH, %s)\n", GP_TRAJECTORY_MSG, GP_TRAJECTORY_FORM);
 IPC_defineMsg(GP_TRAJECTORY_MSG, IPC_VARIABLE_LENGTH, GP_TRAJECTORY_FORM);

 // Subscribe to the messages that this module listens to.
 printf("\nIPC_subscribe(%s, GP_MAP_DATA_Handler, %s)\n", GP_MAP_DATA_MSG, MODULE_NAME);
 IPC_subscribe(GP_MAP_DATA_MSG, GP_MAP_DATA_Handler, (void *)MODULE_NAME);
 IPC_setMsgQueueLength(GP_MAP_DATA_MSG, 1);

 printf("\nIPC_subscribe(%s, GP_ROBOT_PARAMETER_Handler, %s)\n", GP_ROBOT_PARAMETER_MSG, MODULE_NAME);
 IPC_subscribe(GP_ROBOT_PARAMETER_MSG, GP_ROBOT_PARAMETER_Handler, (void *)MODULE_NAME);
 IPC_setMsgQueueLength(GP_ROBOT_PARAMETER_MSG, 1);

 printf("\nIPC_subscribe(%s, GP_POSITION_UPDATE_Handler, %s)\n", GP_POSITION_UPDATE_MSG, MODULE_NAME);
 IPC_subscribe(GP_POSITION_UPDATE_MSG, GP_POSITION_UPDATE_Handler, (void *)MODULE_NAME);
 IPC_setMsgQueueLength(GP_POSITION_UPDATE_MSG, 1);

 printf("\nIPC_subscribe(%s, GP_GOAL_UPDATE_Handler, %s)\n", GP_GOAL_ASSIGN_MSG, MODULE_NAME);
 IPC_subscribe(GP_GOAL_ASSIGN_MSG, GP_GOAL_ASSIGN_Handler, (void *)MODULE_NAME);

 printf("\nIPC_subscribe(%s, GP_FULL_UPDATE_Handler, %s)\n", GP_FULL_UPDATE_MSG, MODULE_NAME);
 IPC_subscribe(GP_FULL_UPDATE_MSG, GP_FULL_UPDATE_Handler, (void *)MODULE_NAME);

 printf("\nIPC_subscribe(%s, GP_SHORT_UPDATE_Handler, %s)\n", GP_SHORT_UPDATE_MSG, MODULE_NAME);
 IPC_subscribe(GP_SHORT_UPDATE_MSG, GP_SHORT_UPDATE_Handler, (void *)MODULE_NAME);

 // Subscribe a handler for tty input. Typing "q" will quit the program.
 //	printf("\nIPC_subscribeFD(%d, stdinHnd, %s)\n", _fileno(stdin),MODULE_NAME);
 //IPC_subscribeFD(_fileno(stdin), stdinHnd, (void *)MODULE_NAME);
 printf("\nType 'q' to quit\n");

 IPC_setVerbosity(IPC_Print_Errors);

 IPC_dispatch();

 //wait for messages
 //while(true) {
 //IPC_listen(1000);
 //}

 //clean up on exit
 IPC_disconnect();
 return(0);
 }

 */

