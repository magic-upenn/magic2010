#ifndef _GLOBAL_PLANNER_JMB
#define _GLOBAL_PLANNER_JMB

class GPLAN {
	friend class GP_threads;

	public:

//	bool gplan_init(GP_MAP_DATA * gp_map_data_p, GP_ROBOT_PARAMETER * gp_robot_parameter_p, GP_FULL_UPDATE * gp_full_update_p);
	bool gplan_init( GP_PLANNER_PARAMETER  * gp_planner_param_p); //, GP_ROBOT_PARAMETER * gp_robot_parameter_p);
    std::vector < std::vector<Traj_pt_s> > gplan_plan(GP_POSITION_UPDATE * gp_position_update_p, GP_FULL_UPDATE * gp_full_update_p);

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
    int * POSEX;
    int *POSEY;
	double * POSETHETA;
	int NUMROBOTS;
	int * robot_goals;

	//map variables
	unsigned char * cover_map;
	unsigned char * cost_map;
	int16_t * elev_map; 
	uint16_t * region_map;
	unsigned char * real_cover_map;


	unsigned char * inflated_cost_map;
	unsigned char ** cost_map_pa; // ptr to first element of each row
	unsigned char ** inf_cost_map_pa; //ptr to first element of each row for inflated map

	//robot variables
	double sensor_radius; // distance sensors can see in m
	int16_t sensor_height; // sensor height in cm
	double SENSORWIDTH;  // sensor width in radians used to determine start and finish vectors for ray tracing
	double inflation_size;  //size in cells to inflate obstacles
	double SOFT_PAD_DIST; // size in meters for soft padding on obstacles

	//planner variables
	double GP_PLAN_TIME; // seconds to allow for planning
	double DIST_GAIN; // factor to switch between greedy and IG
	bool WRITE_FILES; // flag to write files out
	bool DISPLAY_OUTPUT; // flag to display any output
	double THETA_BIAS; // 0 TO 1 Adds additional bias to rough direction to goal location
	double MIN_RANGE;
	double MAX_RANGE;
	double DIST_PENALTY;
	double REGION_PENALTY;
    uint16_t * BN;
    uint16_t GENERIC_REGION_MASK;

    // sensor variables
	int NUMVECTORS;
	std::vector<RAY_TEMPLATE_PT> rayendpts;
	int SVL[9], SVR[9], FVL[9], FVR[9];  // holds the start and finish vectors for the right and left 120 arcs

	// output and misc variables
	std::priority_queue<frontier_pts, std::vector<frontier_pts>, fp_compare_max> frontier;
    int FRONTIER_HEAP_SIZE;
	std::vector <std::vector<Traj_pt_s> > traj; // trajectory
	
	// functions
	void setPixel(const int x, const int y);
	void rasterCircle(const int radius);
	int ValidVec(int vec);
	bool OnMap(const int x, const int y);
	double return_path(int x_target, int y_target, const int dijkstra[], std::vector<Traj_pt_s> & traj, const int RID);
	bool map_alloc(void);
	void sample_point(int &x_target, int &y_target, int &robot_id);
	void calc_all_IG(unsigned int IG_map[]);
	unsigned int get_IG(const unsigned int IG_map[], const int x, const int y, const int dim);
	void find_frontier(const unsigned int IG_map[], const int dijkstra[], const int RID,  std::priority_queue<frontier_pts, std::vector<frontier_pts>, fp_compare_min>* temp_frontier);
	void global_planner(double goal_x, double goal_y, double goal_theta);
	void cast_single_ray(int x0, int y0, int x1, int y1, int & score, unsigned char cover_map[], const int16_t elev[]) ;
	int cast_all_rays(int x0, int y0, unsigned char cover_map[], const int16_t elev_map[], int start_vec, int end_vec);
//	void fix_cover(int robot_id);
	double bias(const int RID, const int x, const int y);
	double IG_dist_ratio(const int IG, const double dist);
    double trace_path(const int x_target, const int y_target, std::vector<Traj_pt_s> & traversal_traj, const int robot_id, const int dijkstra[], unsigned char trav_cover_map[]);
    void timer_fxn(const char txt[]);

};

class GP_threads {
	public: 
		GP_threads() {}

		void start_dijkstra(int RID, int dijkstra[], int r_robot_x, int r_robot_y, GPLAN * gplanner) {
			m_thread = boost::thread(&GP_threads::SearchFxn, this, RID, dijkstra, r_robot_x, r_robot_y, gplanner);
		}

		void start_frontier(const int RID, const int dijkstra[], const unsigned int IG_map[], std::priority_queue<frontier_pts, std::vector<frontier_pts>, fp_compare_min>* temp_frontier, GPLAN * gplanner) {
			m_thread = boost::thread(&GP_threads::FrontierFxn, this, RID, dijkstra, IG_map, temp_frontier, gplanner);
		}


		void join() {
			m_thread.join();
		}

		void SearchFxn(int RID, int dijkstra[], int r_robot_x, int r_robot_y, GPLAN * gplanner);

   		void FrontierFxn(const int RID, const int dijkstra[], const unsigned int IG_map[], std::priority_queue<frontier_pts, std::vector<frontier_pts>, fp_compare_min>* temp_frontier, GPLAN * gplanner);

	private:
		boost::thread m_thread;
};



#endif
