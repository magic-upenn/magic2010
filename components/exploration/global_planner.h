#ifndef _GLOBAL_PLANNER_JMB
#define _GLOBAL_PLANNER_JMB

class GPLAN {
	friend class GP_threads;

	public:

//	bool gplan_init(GP_MAP_DATA * gp_map_data_p, GP_ROBOT_PARAMETER * gp_robot_parameter_p, GP_FULL_UPDATE * gp_full_update_p);
	bool gplan_init( GP_PLANNER_PARAMETER  * gp_planner_param_p); //, GP_ROBOT_PARAMETER * gp_robot_parameter_p);
	vector < vector<Traj_pt_s> > gplan_plan(GP_POSITION_UPDATE * gp_position_update_p, GP_FULL_UPDATE * gp_full_update_p);

	//constuctor
	GPLAN();

	//destructor
	~GPLAN();
	private:

	//map variables
	int map_sizex_m;
	int map_sizey_m;
	double map_cell_size;
	int map_size_x;
	int map_size_y;

	// multi-robot variables
	bool * ROBOTAVAIL;
	double * POSEX;
	double * POSEY;
	double * POSETHETA;
	int NUMROBOTS;
	int * robot_goals;

	//map variables
	unsigned char * cover_map;
	unsigned char * cost_map;
	int16_t * elev_map; 
	unsigned char * region_map;
	unsigned char * real_cover_map;
//	unsigned char * real_cost_map;

	unsigned char * inflated_cost_map;
	unsigned char ** cost_map_pa; // ptr to first element of each row
	unsigned char ** inf_cost_map_pa; //ptr to first element of each row for inflated map

	//posit variables
	double robot_xx, robot_yy; // float posit of robot
	int robot_x, robot_y; // x and y cell coordinates of robot
	double theta;

	//robot variables
	double sensor_radius; // distance sensors can see in m
	int16_t sensor_height; // sensor height in cm
	double SENSORWIDTH;  // sensor width in radians used to determine start and finish vectors for ray tracing
	double inflation_size;  //size in cells to inflate obstacles
	double SOFT_PAD_DIST; // size in meters for soft padding on obstacles

	//planner variables
	double GP_PLAN_TIME; // seconds to allow for planning
	double DIST_GAIN; // factor to switch between greedy and IG
//	double BASE_DIST_GAIN;
//	double DIST_GAIN_DELTA;
	bool WRITE_FILES; // flag to write files out
	bool DISPLAY_OUTPUT; // flag to display any output
	double THETA_BIAS; // 0 TO 1 Adds additional bias to rough direction to goal location
	double MIN_RANGE;
	double MAX_RANGE;
	double DIST_PENALTY;
	double REGION_PENALTY;

	// sensor variables
	int NUMVECTORS;
	vector<RAY_TEMPLATE_PT> rayendpts;
	int SVL[9], SVR[9], FVL[9], FVR[9];  // holds the start and finish vectors for the right and left 120 arcs

	// output and misc variables
	priority_queue<frontier_pts, vector<frontier_pts>, fp_compare> frontier;
	vector <vector<Traj_pt_s> > traj; // trajectory
	
	// functions
	void setPixel(int x, int y);
	void rasterCircle(int radius);
	int ValidVec(int vec);
	bool OnMap(int x, int y);
	double return_path(int x_target, int y_target, const int dijkstra[], vector<Traj_pt_s> & traj, int RID);
	bool map_alloc(void);
	void sample_point(int &x_target, int &y_target);
	void calc_all_IG(unsigned int IG_map[]);
	unsigned int get_IG(unsigned int IG_map[], int x, int y, int dim);
	void find_frontier(unsigned int IG_map[], int dijkstra[], int RID);
	void global_planner(double goal_x, double goal_y, double goal_theta);
	void cast_single_ray(int x0, int y0, int x1, int y1, int & score, unsigned char cover_map[], const int16_t elev[]) ;
	int cast_all_rays(int x0, int y0, unsigned char cover_map[], const int16_t elev_map[], int start_vec, int end_vec);
	void fix_cover(int robot_id);
	double bias(int RID, int x, int y);
	double IG_dist_ratio(int IG, double dist);
};

class GP_threads {
	public: 
		GP_threads() {}

		void start(int RID, int dijkstra[], int r_robot_x, int r_robot_y, GPLAN * gplanner) {
			m_thread = boost::thread(&GP_threads::SearchFxn, this, RID,  dijkstra,  r_robot_x,  r_robot_y, gplanner);
		}

		void join() {
			m_thread.join();
		}

		void SearchFxn(int RID, int dijkstra[], int r_robot_x, int r_robot_y, GPLAN * gplanner);

	private:
		boost::thread m_thread;
};



#endif
