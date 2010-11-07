#include "common_headers.h"
#include "filetransfer.h"

using namespace std;

#define DEFAULTMAP 1

// Module written by Jonathan Michael Butzke
// Fxns are from the exploration planner class to support autonomous exploration of an area by a team of robots.  Functions include support
// for regions of interest, min and max prefered distances to nearest robot and configurable cost maps.  The robots seek to maximize a cost
// function including elements of information gain, distance, preferences, etc.
// University of Pennsylvania - See website for legal restrictions and copyright information concerning this or derivative works.
// (c) 2010 ALL RIGHTS RESERVED

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
    POSEX = new int[NUMROBOTS];
    POSEY = new int[NUMROBOTS];
    POSETHETA = new double[NUMROBOTS];
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
    inflated_cost_map = new unsigned char[DEFAULTMAP];
    cost_map_pa = new unsigned char*[DEFAULTMAP]; // ptr to first element of each row
    inf_cost_map_pa = new unsigned char*[DEFAULTMAP]; //ptr to first element of each row for inflated map
    bias_table = new double[DEFAULTMAP];


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
    FRONTIER_HEAP_SIZE = 100;

    // zone setup
    //BN = new uint16_t[16];
    //for(int i = 0; i<16; i++) { BN[i] = (unsigned int16_t)(1 << (15-i)); }
    //GENERIC_REGION_MASK = 63;

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
    //delete [] BN;
    delete [] bias_table;
}

inline void GPLAN::timer_fxn(const char txt[]) {
    // fxn outputs standardized timing notices with the text string
    gettimeofday(&tv_stop, NULL);
    time_ms=(tv_stop.tv_sec-tv_start.tv_sec)*1000+(tv_stop.tv_usec-tv_start.tv_usec)/1000;
    elap_time_ms=(tv_stop.tv_sec-tv_prev.tv_sec)*1000+(tv_stop.tv_usec-tv_prev.tv_usec)/1000;
    printf("\t\t\t\t\t %5.0f : %.0f - %s\n", time_ms, elap_time_ms, txt);
    tv_prev = tv_stop;   
}

void GPLAN::setPixel(const int x, const int y) {
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
            rayendpts.insert(rayendpts.begin(), RAY_TEMPLATE_PT(x, y, tempangle));
        } else if (rayendpts[locptr - 1].angle != tempangle) {
            if (locptr == rayendpts.size()) {
                rayendpts.push_back(RAY_TEMPLATE_PT(x, y, tempangle));
            } else {
                rayendpts.insert(rayendpts.begin() + locptr, RAY_TEMPLATE_PT(x, y, tempangle));
            }
        }
    }
}

void GPLAN::rasterCircle(const int radius) {
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

inline int GPLAN::ValidVec(int vec) {
    // verifies that the vector is within limits
    if (vec < 0) {
        vec = NUMVECTORS + vec;
    } else if (vec >= NUMVECTORS) {
        vec = vec - NUMVECTORS;
    }
    return vec;
}

inline bool GPLAN::OnMap(const int x, const int y) {
    // function to determine if a point is on the map
    if ((x < map_size_x) && (x >= 0) && (y < map_size_y) && (y >= 0)) {
        return true;
    } else {
        return false;
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
 
    //allocate new storage
    cost_map = new unsigned char[map_size_x * map_size_y];
    elev_map = new int16_t[map_size_x * map_size_y];
    cover_map = new unsigned char[map_size_x * map_size_y];
    region_map = new unsigned char[map_size_x*map_size_y];
    real_cover_map = new unsigned char[map_size_x*map_size_y];
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

unsigned int GPLAN::get_IG(const unsigned int IG_map[],const  int x, const int y, const int dim) {
    // function returns the IG in a box +/- dim from point (x,y)

    int t, r, l, b; // top right left and bottom dimensions
    t = min((map_size_y - 1), y + dim);
    b = max(0, y - dim);
    l = max(0, x - dim);
    r = min((map_size_x - 1), x + dim);

    return (IG_map[r + map_size_x * t] - IG_map[r + map_size_x * b]
            + IG_map[l + map_size_x * b] - IG_map[l + map_size_x * t]);
}

double GPLAN::IG_dist_ratio(const int IG, const double dist) {
    // fxn to calc  weighted distance to IG ratio
    return ((IG*DIST_GAIN) / (dist*(1.0-DIST_GAIN)));
}

double GPLAN::bias(const int RID, const int x, const int y) {
    // fxn takes robot number and potential endpoint and returns a double bias amount 
    // based on distance outside range in cells * DIST_PENALTY
    // no penalty applies if the points are in different regions
    // fxn to calc a heading bias to prefer points closer to "straight ahead"

      double theta_pt = atan2((double)(y-POSEY[RID]), (double)(x-POSEX[RID]));
      double theta_diff = theta_pt - POSETHETA[RID];

    //normalize between -pi and pi
      if (theta_diff > M_PI) { theta_diff -= 2*M_PI;}
      if (theta_diff < -M_PI) { theta_diff += 2*M_PI;}

      double heading_bias =  ((1.0+cos(THETA_BIAS*theta_diff))/2.0);

    int min_dist2 = (map_size_x+map_size_y) * (map_size_x+map_size_y) ;
    double dist_bias = 1;
    bool robot_in_region = false;
    bool region_zero = true;
    double region_bias = 1.0;
    double delta = 0;
    double same_bonus = 1.0;

    // benefit for going to the same point
    if ((x == robot_goals[RID*2]) && (y == robot_goals[RID*2+1])) { same_bonus = 2; }

    //// if in my own or someone elses region apply value
    //if (region_map[x+map_size_x*y] & BN[RID]) { region_bias = 1000; }
    //else if (region_map[x+map_size_x*y] & ~(BN[RID]|GENERIC_REGION_MASK)) { region_bias = .0001; }
    //// if in a generic region see if I am alone then apply appropriate value
    //else  {
    //region_bias = 100;

    // check the other robots to see if any in same region
    for (int ridx = 0; ridx < NUMROBOTS; ridx++) {
        int xx = robot_goals[ridx*2];
        int yy = robot_goals[ridx*2+1];
        if (ridx != RID) {
            if (region_map[xx + map_size_x*yy] == region_map[x + map_size_x*y]) { 
                robot_in_region = true;
                int dist2 = ((x-xx)*(x-xx) + (y-yy)*(y-yy));
                if (dist2 < min_dist2) { min_dist2 = dist2; }
            }
        }
    }


    // if robot is in same region calc bias
    if (robot_in_region) {
        double dist;

        //// determine if in region zero and if not (since we are in this block) apply the penalty for sharing regions
        //if ((region_map[x + map_size_x*y] & GENERIC_REGION_MASK) == 0) {region_bias = 1;} else { region_bias = .01;}

        // determine distance and delta from desired range
        dist = sqrt((double)(min_dist2)) * map_cell_size;
        if (dist < MIN_RANGE) { delta = dist/MIN_RANGE; }
        else if (dist > MAX_RANGE) {delta = MAX_RANGE/dist; }

        // calculate bias
        dist_bias = (delta) * DIST_PENALTY;
    }

    // pick region type (generic or defined)
    if (bias_table[NUMROBOTS + 1 + (NUMROBOTS+2)*region_map[x + map_size_x*y] ] != 0) {
        region_bias = bias_table[NUMROBOTS + robot_in_region + (NUMROBOTS+2)*region_map[x + map_size_x*y] ];
                }
    else { region_bias = bias_table[RID  + (NUMROBOTS+2)*region_map[x + map_size_x*y] ]; }

    double bias = dist_bias * region_bias * same_bonus *  heading_bias ;
    //  cout << " penalties for " << x << "," << y << " d: " << delta << " "<<  dist_bias << " r0: " << region_bias << " h: " << heading_bias << " t: " << bias << endl;
    return bias;
}

inline void GPLAN::sample_point(int &x_target, int &y_target, int &RID) {
    // fxn to pick possible target points
    x_target = -1;
    y_target = -1;
    RID = -1;

    if(!frontier.empty()) { 
        x_target = frontier.top().x;
        y_target = frontier.top().y;
        RID = frontier.top().RID;
        frontier.pop();
    }
}

double GPLAN::return_path(int x_target, int y_target, const int dijkstra[],
        vector<Traj_pt_s> & trajectory, const int RID) {
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
        while ((x_val != POSEX[RID]) || (y_val != POSEY[RID])) {
            min_val = DIJKSTRA_LIMIT ;
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
        while ((inv_traj.size() != 0) && (inflated_cost_map[inv_traj.back().x + map_size_x*inv_traj.back().y] < OBSTACLE)) {
            current.x = inv_traj.back().x;
            current.y = inv_traj.back().y;
            trajectory.push_back(current);
            inv_traj.pop_back();
        }
        return (cost * map_cell_size);
    } else {
        printf("WARNING: Invalid goal location (its on an obstacle) - %d,%d", x_target, y_target);
        return (-1);
    }
}

double GPLAN::trace_path(const int x_target, const int y_target, vector<Traj_pt_s> & traversal_traj, const int robot_id, const int dijkstra[], unsigned char trav_cover_map[]) {
    // determine path to each goal point
    double dist = return_path(x_target, y_target, dijkstra, traversal_traj, robot_id);

 //   if (DISPLAY_OUTPUT) {printf(" and the distance is %f ", dist);}

    double temp_score = 0;
    for (int current_loc = 1; current_loc < traversal_traj.size(); current_loc++) {
        // determine the direction of travel in each axis
        int x_dir = traversal_traj[current_loc].x - traversal_traj[current_loc - 1].x + 1;
        int y_dir = traversal_traj[current_loc].y - traversal_traj[current_loc - 1].y + 1;
        int direction = dir[x_dir][y_dir];
        if (direction != NOMOVE) {
            // pass current location and inflated map to raycaster returns score
            temp_score += cast_all_rays(traversal_traj[current_loc].x, traversal_traj[current_loc].y, trav_cover_map, elev_map, SVR[direction], FVL[direction]);
        } // if !NOMOVE
    } //for current_loc
    if (DISPLAY_OUTPUT) {
        printf("robot %d ->(%d, %d) score: %.0f dist: %.1f bias: %.5f IG/Dist ratio: %.0f region: %d total: %.0f\n", robot_id, x_target, y_target, temp_score, dist, bias(robot_id, x_target, y_target), IG_dist_ratio((int)temp_score, dist), (int)region_map[x_target + map_size_x*y_target], bias(robot_id, x_target,y_target)*IG_dist_ratio((int)temp_score, dist)); }

    return (bias(robot_id, x_target, y_target) *IG_dist_ratio((int)temp_score, dist));
}

void GPLAN::find_frontier(const unsigned int IG_map[], const int dijkstra[], const int RID, std::priority_queue<frontier_pts, std::vector<frontier_pts>, fp_compare_min>* temp_frontier ) {
    // function scans coverage map and populates the frontier queue with frontier points

    int dim = (int)(sqrt((sensor_radius* SENSORWIDTH)/(2*M_PI*map_cell_size)));

    // if (DISPLAY_OUTPUT) {printf("start %d FF\n", RID);}
    while (!temp_frontier->empty()) {
        temp_frontier->pop();
    }
    //  if (DISPLAY_OUTPUT) {printf("before %d loop\n", RID);}
    for (int j = 1; j < map_size_y - 1; j++) {
        for (int i = 1; i < map_size_x - 1; i++) {
            if (dijkstra[i + map_size_x * j+ map_size_x*map_size_y*RID] < DIJKSTRA_LIMIT) {
                if ((real_cover_map[i + map_size_x * j] == KNOWN)
                        && ((real_cover_map[(i + 1) + map_size_x * (j)] != KNOWN) 
                            || (real_cover_map[(i - 1) + map_size_x * (j)] != KNOWN)
                            || (real_cover_map[(i) + map_size_x * (j + 1)] != KNOWN) 
                            || (real_cover_map[(i) + map_size_x * (j - 1)] != KNOWN))) {
                    frontier_pts temp(i,j,RID, bias(RID,i,j)*IG_dist_ratio(get_IG(IG_map, i, j, dim), dijkstra[i + map_size_x * j + map_size_x*map_size_y*RID]));
                    if (temp_frontier->size() < FRONTIER_HEAP_SIZE) {
                        temp_frontier->push(temp);

                    }
                    else {
                        if (temp_frontier->top().total < temp.total) {
                            temp_frontier->pop();
                            temp_frontier->push(temp);
                        }
                    }
                }
            }
        }
    }
    //  if (DISPLAY_OUTPUT) {printf("size for %d is %d\n", RID, (int)temp_frontier->size() );}
}
//
//void denoise(unsigned char src[], int strel, int mapm, int mapn) {
//  // performs morphological open
//  int xx = strel / 2;
//  int yy = strel / 2;
//
//  unsigned char *temp = new unsigned char[mapm * mapn];
//  unsigned char *dest = new unsigned char[mapm * mapn];
//
//  for (int j = 0; j < mapn; j++) {
//      for (int i = 0; i < mapm; i++) {
//          temp[i + j * mapm] = UNKNOWN;
//          dest[i + j * mapm] = KNOWN;
//      }
//  }
//
//  //perform dilation of known areas
//  for (int j = 0; j < mapn; j++) {
//      for (int i = 0; i < mapm; i++) {
//          if (src[i + mapm * j] != UNKNOWN) {
//              for (int x = 0; x < strel; x++) {
//                  for (int y = 0; y < strel; y++) {
//                      if (OnMap(x + i - xx, y + j - yy)) {
//                          temp[x + i - xx + (y + j - yy) * mapm] = KNOWN;
//                      }
//                  }
//              }
//          }
//      }
//  }
//
//  // perform erosion on temp map to return known areas to size
//  for (int j = 0; j < mapn; j++) {
//      for (int i = 0; i < mapm; i++) {
//          if (temp[i + mapm * j] == UNKNOWN) {
//              for (int x = 0; x <= strel; x++) {
//                  for (int y = 0; y <= strel; y++) {
//                      if (OnMap(x + i - xx, y + j - yy)) {
//                          dest[x + i - xx + (y + j - yy) * mapm] = UNKNOWN;
//                      }
//                  }
//              }
//          }
//      }
//  }
//
//  // copy the dest array back onto the original src array
//  memcpy((void *)src,(void *) dest, sizeof(unsigned char)*mapm*mapn);
//  delete[] dest;
//  delete[] temp;
//
//}

//void GPLAN::fix_cover(int robot_id) {
// function to make checked coverage map include the other robots estimated maps
//    if (DISPLAY_OUTPUT) {printf(" fix cover for %d\n", robot_id);}
//delete [] cover_map;
//cover_map = new unsigned char[map_size_x * map_size_y];   // non-const storage for each possible goal
//memcpy((void *)cover_map, (void *)real_cover_map, map_size_x*map_size_y * (sizeof(unsigned char)));

//   robot_xx = POSEXX[robot_id];
//    robot_x = (int)(robot_xx/map_cell_size);
//    robot_yy = POSEYY[robot_id];
//    robot_y = (int)(robot_yy/map_cell_size);
//    theta = POSETHETA[robot_id];

//  DIST_GAIN = BASE_DIST_GAIN + robot_id*DIST_GAIN_DELTA;

//   if (DISPLAY_OUTPUT) {cout << "robot " << robot_id << " is at UTM " << robot_xx << "," << robot_yy << " cell " << robot_x << "," << robot_y << endl;}

//  for (int id=0; id < NUMROBOTS; id++) {
//  cout << "looking at map " << id << endl;
/*  if (robot_id>0) {
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
//  }
//   if (DISPLAY_OUTPUT) {cout << "done with fix cover" << endl;}
//}

void GP_threads::SearchFxn(const int RID, int dijkstra[], const int r_robot_x, const int r_robot_y, GPLAN * gplanner) {
   printf("SFs%d\n", RID);
    int sx = gplanner->map_size_x;
    int sy = gplanner->map_size_y;
    // ensure that the robot cell is not an obstacle and clear a little box if there is
    int rad = (int)ceil(gplanner->inflation_size + gplanner->SOFT_PAD_DIST*gplanner->map_cell_size + 2);
    float rad_2 = pow(rad, 2);
    gplanner->cover_map[r_robot_x + sx * r_robot_y] = KNOWN;
    //cost_map[robot_x + map_size_x * robot_y] = 0;
    /*  if (cost_map[robot_x + map_size_x * robot_y] >= OBSTACLE) {
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
    //	if (gplanner->inflated_cost_map[r_robot_x + sx * r_robot_y] == OBSTACLE) {
    for (int xxx = -rad; xxx < rad; xxx++) {
        for (int yyy = -rad; yyy < rad; yyy++) {
            if (gplanner->OnMap(r_robot_x + xxx, r_robot_y + yyy) && ((xxx*xxx + yyy*yyy) <= rad_2)) {
                if (gplanner->cost_map[r_robot_x + xxx + (sx * (r_robot_y+yyy))] !=OBSTACLE) {
                    gplanner->inflated_cost_map[r_robot_x + xxx + (sx * (r_robot_y + yyy))] 
                        = min((int) gplanner->inflated_cost_map[r_robot_x + xxx+ (sx * (r_robot_y + yyy))], START_FOOTPRINT_INF_CLEAR);
                    //OBSTACLE - ((3	* rad * rad) / (1 + xxx * xxx + yyy * yyy)));
                }
            }
        }
    }
    //	}

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
    //cout << "d" << RID << endl;
    printf("SFd%d\n", RID);
}

void GP_threads::FrontierFxn(const int RID, const int dijkstra[], const unsigned int IG_map[], std::priority_queue<frontier_pts, std::vector<frontier_pts>, fp_compare_min>* temp_frontier, GPLAN * gplanner) {
    // fxn to create frontier lists for each robot in a separate thread
    printf("FFs%d\n", RID); 
    gplanner->find_frontier(IG_map, dijkstra, RID, temp_frontier);
    printf("FFd%d\n", RID); 
}

void GPLAN::global_planner(double goal_x, double goal_y, double goal_theta) {
    // function provides a traj to best found goal point to (nearest or most valuable)
    printf("Started exploration planner\n");

    float *obs_array = new float[map_size_x * map_size_y];
    float **obs_ptr_array = new float*[map_size_y];
    float *nonfree_array = new float[map_size_x * map_size_y];
    float **nonfree_ptr_array = new float*[map_size_y];

    if (DISPLAY_OUTPUT) {timer_fxn("Time @ start");}

    // set up array of pointers
    for (int j = 0; j < map_size_y; j++) {
        obs_ptr_array[j] = &obs_array[j * map_size_x];
        nonfree_ptr_array[j] = &nonfree_array[j * map_size_x];
    }

    // remove obstacles from unknown areas
    //for (int j = 0; j < map_size_y; j++) {
    //for (int i = 0; i < map_size_x; i++) {
    //if (cover_map[i + map_size_x * j] == UNKNOWN) {
    //elev_map[i + map_size_x * j] = -OBS16;
    //cost_map[i + map_size_x * j] = 0;
    //}
    //}
    //}

    // inflate map
    computeDistancestoNonfreeAreas(cost_map_pa, map_size_y, map_size_x, OBSTACLE, obs_ptr_array, nonfree_ptr_array);
    int dim = (int)(sensor_radius / (2.0 * map_cell_size));

    //update inflated map based on robot size and make unknown areas obstacles w/o inflation
    for (int j = 0; j < map_size_y; j++) {
        for (int i = 0; i < map_size_x; i++) {
            if (((!UNKNOWN_ARE_PASSABLE) && (cover_map[i + map_size_x * j]  == UNKNOWN)) || (obs_ptr_array[j][i] <= inflation_size)) {
                if ((!UNKNOWN_ARE_PASSABLE) && (cover_map[i + map_size_x * j]   == UNKNOWN)) {
                    inflated_cost_map[i + map_size_x * j] = UNKOBSTACLE;
                }
                if (obs_ptr_array[j][i] <= inflation_size) {
                    inflated_cost_map[i + map_size_x * j] = OBSTACLE;
                }
            }
            else {
                int pad_dist = (int)(SOFT_PAD_DIST/map_cell_size); 
                int buffer = (pad_dist - (int)inflation_size);

                inflated_cost_map[i + map_size_x * j] = (unsigned char) max((double) (cost_map[i + map_size_x * j]) , (double)((pad_dist - obs_ptr_array[j][i])*200/buffer));

                //          inflated_cost_map[i + map_size_x * j] = (unsigned char) max( 0.0, 
                //                  (double) (cost_map[i + map_size_x * j]) 
                //                  - (double)(get_IG(IG_map, i, j, dim)) / (4.0 * dim * dim)
                //                  );

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

    memcpy((void *)real_cover_map, (void *)cover_map, map_size_x*map_size_y * (sizeof(unsigned char)));

    if (DISPLAY_OUTPUT) {timer_fxn("Time before Dijkstra");}

    int * dijkstra = new int[map_size_x * map_size_y * NUMROBOTS];

    GP_threads GP_threadlist[NUMROBOTS];
    list<int> remaining_robots;

    // storage for frontier points
    vector < priority_queue<frontier_pts, vector<frontier_pts>, fp_compare_min>* >  temp_frontier;
    temp_frontier.resize(NUMROBOTS);
    for (int ridx=0; ridx < NUMROBOTS; ridx++) {
        temp_frontier[ridx] = new priority_queue<frontier_pts, vector<frontier_pts>, fp_compare_min>;
    }

    if (DISPLAY_OUTPUT) {printf("start Dijkstra thread for each robot\n");}
    for (int ridx=0; ridx < NUMROBOTS; ridx++) {
        if(ROBOTAVAIL[ridx]) { 
            GP_threadlist[ridx].start_dijkstra(ridx,  dijkstra,  POSEX[ridx],  POSEY[ridx], this);
            remaining_robots.push_back(ridx);
        }
    }

    if (DISPLAY_OUTPUT) {timer_fxn("Time after Dijkstra");}

    while(!remaining_robots.empty()) {
        printf("A");
        if (DISPLAY_OUTPUT) {printf("\nStart planning with %d robots in list\n", (int)remaining_robots.size());}

        if (DISPLAY_OUTPUT) {timer_fxn("Time at beginning of each loop");}

        // update position and adjust cover map if desired
        //    fix_cover(RID);

        unsigned int * IG_map = new unsigned int[map_size_x * map_size_y];

        //calculate the IG at each point based on current coverage map
        calc_all_IG(IG_map);

        for(list<int>::const_iterator pos = remaining_robots.begin(); pos != remaining_robots.end(); pos++) {
            // spawn thread to get the frontier points for each remaining robot and put into temp_frontier
            GP_threadlist[*pos].join();
            GP_threadlist[*pos].start_frontier((int)(*pos), dijkstra, IG_map, temp_frontier[*pos], this);

            //clear old traj of remaining robots
            traj[*pos].clear();
        }

        // wait for all threads to finish
        for(list<int>::const_iterator pos = remaining_robots.begin(); pos != remaining_robots.end(); pos++) {
            GP_threadlist[*pos].join();
            //if (DISPLAY_OUTPUT) {printf("frontier list for robot %d has %d elements and the min is %f\n", (int) *pos, (int) temp_frontier[*pos]->size(), temp_frontier[*pos]->top().total);}
        }

        // merge lists as long as they are all done into frontier
        priority_queue<frontier_pts, vector<frontier_pts>, fp_compare_min> temp_combine_frontier;
        for (list<int>::iterator pos = remaining_robots.begin(); pos != remaining_robots.end(); pos++) {
            while (!temp_frontier[*pos]->empty()) {
                if (temp_combine_frontier.size() < FRONTIER_HEAP_SIZE) {
                    temp_combine_frontier.push(temp_frontier[*pos]->top());
                    temp_frontier[*pos]->pop();
                }
                else {
                    if (temp_frontier[*pos]->top().total > temp_combine_frontier.top().total) {
                        temp_combine_frontier.pop();
                        temp_combine_frontier.push(temp_frontier[*pos]->top());
                    }
                    temp_frontier[*pos]->pop();
                }
            }
        }
        while(!frontier.empty()) { frontier.pop(); }
        while(!temp_combine_frontier.empty()) {
            frontier.push(temp_combine_frontier.top());
            temp_combine_frontier.pop();
        }
        
        double best_score = 0, temp_score = 0; // tracks best score this run
        int best_RID = -1;  //tracks best robot number
        int x_target, y_target;//, best_x, best_y;
        vector<Traj_pt_s> test_traj; // temp trajectory
        unsigned char * temp_cover_map = new unsigned char[map_size_x * map_size_y]; // non-const storage for each possible goal

        clock_t start, finish;
        start = finish = clock();

        if (DISPLAY_OUTPUT) {timer_fxn("Time after frontier before timed loop");}

        // run each robot to last goal and compare as best
        for(list<int>::const_iterator pos = remaining_robots.begin(); pos != remaining_robots.end(); pos++) {
            memcpy((void *) temp_cover_map, (void *) cover_map, map_size_x  * map_size_y * (sizeof(unsigned char)));
            int RID = *pos;
            int rx = robot_goals[RID*2];
            int ry = robot_goals[RID*2+1];

            if (DISPLAY_OUTPUT) {printf("checking last run for %d -> (%d,%d)\n", RID,rx, ry);}
            if ((dijkstra[rx + map_size_x * ry + map_size_x*map_size_y*RID] < DIJKSTRA_LIMIT) 
                    && (real_cover_map[rx + map_size_x * ry] == KNOWN)
                    && ((real_cover_map[(rx + 1) + map_size_x * (ry)] != KNOWN) 
                        || (real_cover_map[(rx - 1) + map_size_x * (ry)] != KNOWN)
                        || (real_cover_map[(rx) + map_size_x * (ry + 1)] != KNOWN) 
                        || (real_cover_map[(rx) + map_size_x * (ry - 1)] != KNOWN)) ) {
                x_target = rx;
                y_target = ry;
                if (DISPLAY_OUTPUT) {printf("going for previous\n");}

                temp_score = trace_path(x_target, y_target, test_traj, RID, dijkstra, temp_cover_map);

                if (temp_score > best_score) {
                    printf("*");
                    best_score = temp_score;
                    best_RID = RID;
                    traj[RID].swap(test_traj);
                }
            }
        }// check of previous goals

        if (DISPLAY_OUTPUT) {timer_fxn("Time after previous goal checks");}

        while (finish-start < GP_PLAN_TIME*CLOCKS_PER_SEC) { // while less than plan time  
            printf(".");    
            int RID = -1;
            // temp map for tracking changes during runs
            memcpy((void *) temp_cover_map, (void *) cover_map, map_size_x  * map_size_y * (sizeof(unsigned char)));

            sample_point(x_target, y_target, RID); 
     //       if (DISPLAY_OUTPUT) {printf("robot %d believes (%d,%d) to be a potential goal\n", RID, x_target, y_target);}

            // if return is -1, -1 then no more points found 
            if ((x_target == -1) && (y_target == -1)) {
                printf("Sample point has exhausted the frontier heap.  Break from timed while loop\n");
                break;
            }

            temp_score = trace_path(x_target, y_target, test_traj, RID, dijkstra, temp_cover_map);

            if (temp_score > best_score) {
                printf("*");
                best_score = temp_score;
                best_RID = RID;
                traj[RID].swap(test_traj);
            }

            //finish time
            finish = clock();
        } // while time remaining

        if (DISPLAY_OUTPUT) {printf("GP done looking at points\n");}

        // select highest scoring trajectory after XX seconds
        if (best_RID == -1) {
            printf("Trajectory is empty after timed loop - no valid trajectory found, deleting arrays and returning\n");
            // wait for all threads to finish
            // for (int ridx=0; ridx < NUMROBOTS; ridx++) {
            //     calc_dijkstra[ridx].join();
            // }
            delete [] temp_cover_map;
            delete [] IG_map;
            delete [] dijkstra;
            delete [] obs_array;
            delete [] nonfree_array;
            delete [] obs_ptr_array;
            delete [] nonfree_ptr_array;

            for (int ridx=0; ridx < NUMROBOTS; ridx++) {
                delete temp_frontier[ridx];
            }
           // delete [] temp_frontier;
           // delete [] GP_Threadlist;
           // delete [] remaining_robots;

            return;
        } else {
            //	cout << "final best goal " << traj[RID].back().x << "," << traj[RID].back().y
            //		<< " size " << traj[RID].size() << endl;
            printf( "final best goal (%d, %d) for robot %d score %f\n",traj[best_RID].back().x, traj[best_RID].back().y, best_RID, best_score );
        }

        // save goal locations 
        x_target = robot_goals[best_RID*2] = traj[best_RID].back().x;
        y_target = robot_goals[best_RID*2+1] = traj[best_RID].back().y;
printf("B");
        // update cover map
        trace_path(x_target, y_target, traj[best_RID], best_RID, dijkstra, cover_map);
printf("C");
        for (int current_loc = 0; current_loc < traj[best_RID].size(); current_loc++) {
            traj[best_RID][current_loc].xx = traj[best_RID][current_loc].x * map_cell_size;
            traj[best_RID][current_loc].yy = traj[best_RID][current_loc].y * map_cell_size;
        } //for current_loc

        // remove best_RID from list
        remaining_robots.remove(best_RID);
printf("D");
        // frees recalculated arrays
        delete [] temp_cover_map;
        delete [] IG_map;
    } // while remaining_robots !empty

    // write results to disk - cover map shows what was presumed to have been seen during traversal
    if (WRITE_FILES) {
        if (DISPLAY_OUTPUT) { printf(" writing map files to disk\n"); }
        //  writefiles(cover_map, inflated_cost_map, elev_map, "Map_out.txt", map_size_x, map_size_y);
        writefileextra(dijkstra, "Map_extra.txt", map_size_x, map_size_y);
        //  writefiletraj(best_score, traj[RID], "Map_traj.txt");
        char str[50];
        for (int ridx = 0; ridx < NUMROBOTS; ridx++) {
            sprintf(str, "Map%d.bmp", ridx);
            writeBMP(cover_map, inflated_cost_map, &dijkstra[map_size_x*map_size_y*ridx], map_size_x, map_size_y , traj[ridx], str) ;
        }
    }
printf("E");
    // frees un-needed arrays
    delete [] dijkstra;
    delete [] obs_array;
    delete [] nonfree_array;
    delete [] obs_ptr_array;
    delete [] nonfree_ptr_array;
    printf("F");
    for (int ridx=0; ridx < NUMROBOTS; ridx++) {
        delete  temp_frontier[ridx];
    }
    printf("G");
//    delete [] temp_frontier;
//    delete [] GP_Threadlist;
//    delete [] remaining_robots;

    if (DISPLAY_OUTPUT) {
        timer_fxn("Time after main planner\n");
    }
}

bool GPLAN::gplan_init(GP_PLANNER_PARAMETER * gp_planner_param_p) {
    //      GP_ROBOT_PARAMETER * gp_robot_parameter_p) {
    //      GP_FULL_UPDATE * gp_full_update_p) {
    // function to initialize map and robot data, read in initial full map, and set highlevel planning parameters
    //function to handle map and robot parameters and loads full map

    //update planner variables
    GP_PLAN_TIME = gp_planner_param_p->GP_PLAN_TIME; // seconds to allow for planning
    cout << " GP_PLAN_TIME = " << GP_PLAN_TIME << endl;
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
    POSEX = new int[NUMROBOTS];
    POSEY = new int[NUMROBOTS];
    POSETHETA = new double[NUMROBOTS];

    traj.resize(NUMROBOTS);

    //update size variables
    map_cell_size = gp_planner_param_p->map_cell_size;
    cout << " Cells are " << map_cell_size <<  "m square" << endl;

    //update size variables
    map_size_x = gp_planner_param_p->map_size_x;
    map_size_y = gp_planner_param_p->map_size_y;
    cout << "The maps are " << map_size_x << " x " << map_size_y << endl;

    // zeros out region bias table
    num_regions = 0;

    //stores new robot parameters
    sensor_radius = gp_planner_param_p->sensor_radius;
    sensor_height = gp_planner_param_p->sensor_height;
    //  cout << " The robot can go " << MAX_VELOCITY << " m/s and turn at " << MAX_TURN_RATE << " rad/sec.  The sensor is " << sensor_height << " cm high and can see " << sensor_radius << " m" << endl;

    // establish sensor endpoints
    //  int sensor_int_radius = (int) (sensor_radius / map_cell_size);
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
    inflation_size =  gp_planner_param_p->perimeter_radius / map_cell_size;

    //allocate memory for the maps according to the size variables
    bool val = map_alloc();
    if (val) {cout << "done alloc "; }
    else { printf("Map Allocation failed!!\n"); }

}

vector < vector<Traj_pt_s> > GPLAN::gplan_plan(GP_POSITION_UPDATE * gp_position_update_p,
        GP_FULL_UPDATE * gp_full_update_p) {
    //	cout << "starting library planning cycle" << endl;
    //function replans based on updated short map and position update
    gettimeofday(&tv_start, NULL);
    tv_prev = tv_start;
    //	cout << "copying data into static storage" << endl;
    //place data into the correct arrays
    memcpy((void *) cover_map, (void *) gp_full_update_p->coverage_map, map_size_x * map_size_y * sizeof(unsigned char));
    memcpy((void *) cost_map, (void *) gp_full_update_p->cost_map, map_size_x * map_size_y * sizeof(unsigned char));
    memcpy((void *) elev_map, (void *) gp_full_update_p->elev_map, map_size_x * map_size_y * sizeof(int16_t));
    memcpy((void *) region_map, (void *) gp_full_update_p->region_map, map_size_x * map_size_y * sizeof(unsigned char));

    if (num_regions != gp_full_update_p->num_regions) {
        num_regions = gp_full_update_p->num_regions;
        delete [] bias_table;
        bias_table = new double[num_regions*(NUMROBOTS+2)];
    }

    num_regions = gp_full_update_p->num_regions;
    memcpy((void *) bias_table, (void *) gp_full_update_p->bias_table, num_regions * (NUMROBOTS+2) * sizeof(double));

	if (DISPLAY_OUTPUT) {
		printf("printing bias table %d %d\n", num_regions, gp_full_update_p->num_states);
		for (int j = 0; j < num_regions; j++) {
			for (int i =0; i < (NUMROBOTS+2); i++) {
				printf(" %f ", bias_table[i+j*(NUMROBOTS+2)]);
			}
			printf("\n");
		}
	}
	//	cout << "prepping other variables" << endl;

	//map variables
	for (int idx=0; idx < NUMROBOTS; idx++) { ROBOTAVAIL[idx]= (bool)gp_position_update_p->avail[idx];}

    //updates the stored robot position
    for (int idx = 0; idx < NUMROBOTS; idx++) {
		POSEX[idx] = (int)(gp_position_update_p->x[idx] / map_cell_size);
		POSEY[idx] = (int)(gp_position_update_p->y[idx] / map_cell_size);
		POSETHETA[idx] = gp_position_update_p->theta[idx];
		printf("incoming robot %i pose is (%i, %i) facing %f\n", idx, POSEX[idx], POSEY[idx], POSETHETA[idx]);
		if (!OnMap(POSEX[idx], POSEY[idx])) { POSEX[idx] = 0; POSEY[idx]=0; }
		// free 9 cells in vicinity of robot start position
		for(int i=-4; i<=4; i++) {
			for(int j=-4; j<=4; j++) {
				if (OnMap(POSEX[idx]+i, POSEY[idx]+j)) {
					cover_map[POSEX[idx]+i+(POSEY[idx]+j)*map_size_x] = KNOWN;
				}
			}
		}
		traj[idx].reserve(300); 
		printf("robot %d is at (%.0f,%.0f)\n", idx, POSEX[idx]*map_cell_size, POSEY[idx]*map_cell_size);
	}

//	cout << "starting actual planner" << endl;
global_planner(-1, -1, -1);
for (int idx = 0; idx < NUMROBOTS; idx++) {
        cout << " " << idx << "-" << traj[idx].size();
    }
    cout << endl;  

    if (DISPLAY_OUTPUT) {timer_fxn("Done with planner");};

    return traj;
}

