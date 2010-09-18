using namespace std;
#include "mex.h"
#include <cstdlib>
#include <vector>
#include "../sbpl/src/sbpl/headers.h"
#include "envMagic.h"
#include "unistd.h"
#include <string>

#define min(a,b) (a<b?a:b)
#define max(a,b) (a>b?a:b)

#define PLANNING_TIME 2.0
#define OBS_THRESH 90

float resolution=0.1;
float max_velocity=1.0; //meters per sec
float max_turn_rate=3.14; //radians per sec
float outer_radius = sqrt(2*0.25*0.25)/resolution;

int count=0;

int size_x=0;
int size_y=0;
unsigned char** rawcostmap = NULL;
unsigned char** rawtrajmap = NULL;
float** costmap = NULL;
float** trajmap = NULL;
float** dummymap = NULL;
EnvironmentMAGICLAT* env = NULL;
ARAPlanner* planner = NULL;
vector<sbpl_2Dpt_t> perimeterptsV;
float inner_radius = 0;
float padding = 1.0;
float padding_cost = 2;
int exploration_obst_thresh = 250;
int obst_thresh = 254;
int inner_obst_thresh = obst_thresh-1;
float close_to_path = 6;

double global_x_offset = 0;
double global_y_offset = 0;
double global_start_x;
double global_start_y;
double global_start_theta;
double global_goal_x;
double global_goal_y;
double global_goal_theta;
int traj_length;
int traj_dim;
double* traj_path = NULL;

bool reset_traj_map = false;

//initialization flags
int shouldRun = 0;
char initialized = 0;
#define INIT_RES    (1<<0)
#define INIT_PARAMS (1<<1)
#define INIT_MAP    (1<<2)
#define INIT_POSE   (1<<3)
#define INIT_TRAJ   (1<<4)
#define UPDATED_MAP (1<<5)
#define UPDATED_POS (1<<6)
#define INIT_DONE (INIT_MAP | INIT_POSE | INIT_TRAJ | UPDATED_MAP | UPDATED_POS)
#define NEED_UPDATE (INIT_MAP | INIT_POSE | INIT_TRAJ)



bool OnMap(int x, int y) {
  // function to determine if a point is on the map
  return ((x<size_x) && (x>=0) && (y<size_y) && (y >=0));
}


void makeTrajMap(){
  //clear old trajectory
  for(int x=0; x<size_x; x++)
    for(int y=0; y<size_y; y++)
      rawtrajmap[x][y] = 0;

  // copy path into new trajectory map
  for(int i=0; i<traj_length; i++){
    int x = (int)(CONTXY2DISC(traj_path[i*traj_dim]-global_x_offset,resolution));
    int y = (int)(CONTXY2DISC(traj_path[i*traj_dim+1]-global_y_offset,resolution));
    rawtrajmap[x][y] = 1;
  }

  computeDistancestoNonfreeAreas(rawtrajmap, size_x, size_y, 1, trajmap, dummymap);

  for(int x=0; x<size_x; x++){
    for(int y=0; y<size_y; y++){
      if(trajmap[x][y] <= close_to_path)
        trajmap[x][y] = 0;
      else
        trajmap[x][y] -= close_to_path;
    }
  }
  reset_traj_map = false;
}


void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[] ){
  const int BUFLEN = 256;
  char command[BUFLEN];	

  if (mxGetString(prhs[0], command, BUFLEN) != 0)
    mexErrMsgTxt("lattice_planner: Could not read string. (1st argument)");

  if (strcasecmp(command, "map") == 0){
    //size_x size_y resolution utm_x utm_y map_data
    if(mxGetNumberOfElements(prhs[1]) != 5){
      mexErrMsgTxt("the map parameters (2nd argument) should have 5 values (size_x,size_y,resolution,origin_global_x,origin_global_y)");
      return;
    }
    double* map_params = mxGetPr(prhs[1]);
    int new_size_x = map_params[0];
    int new_size_y = map_params[1];
    if(mxGetNumberOfElements(prhs[2]) != new_size_x*new_size_y){
      mexErrMsgTxt("the map (3rd argument) should have size_x*size_y elements");
      return;
    }
    double* map_data = mxGetPr(prhs[2]);
    double new_resolution = map_params[2];
    global_x_offset = map_params[3];
    global_y_offset = map_params[4];

    unsigned char* temp_map = new unsigned char[new_size_x*new_size_y];
    for(int y=0; y<new_size_y; y++){
      for(int x=0; x<new_size_x; x++){
        bool isObstacle = map_data[x+new_size_x*y] > OBS_THRESH;
        bool isExplored = map_data[x+new_size_x*y] != 0;
        temp_map[x+new_size_x*y] = (isObstacle ? 250 : (isExplored ? 0 : 125));
      }
    }

    if(size_x != new_size_x || size_y != new_size_y || resolution != new_resolution || env == NULL){
      //update size variables
      int old_size_x = size_x;
      size_x = new_size_x;
      size_y = new_size_y;
      resolution = new_resolution;
      
      if(env != NULL)
        delete env;

      env = new EnvironmentMAGICLAT();
      env->SetEnvParameter("cost_obsthresh",obst_thresh);
      env->SetEnvParameter("cost_inscribed_thresh",inner_obst_thresh);
      env->SetEnvParameter("cost_possibly_circumscribed_thresh",252);

      const char* primitive_filename = "magic.mprim";
      //THIS IS A POINT ROBOT!!!!!! 
      perimeterptsV.clear();
      env->InitializeEnv(size_x, // width
                         size_y, // height
                         0, // mapdata
                         0, 0, 0, // start (x, y, theta)
                         0, 0, 0, // goal (x, y, theta)
                         0, 0, 0, //goal tolerance
                         perimeterptsV, resolution, max_velocity,
                         M_PI/4*max_turn_rate, obst_thresh, 
                         primitive_filename);

      if(planner != NULL)
        delete planner;

      planner = new ARAPlanner(env, false);
      planner->set_initialsolution_eps(3.0);
      planner->set_search_mode(false);
      
      if(costmap != NULL){
        for(int i=0; i<old_size_x; i++){
          delete [] rawcostmap[i];
          delete [] costmap[i];
          delete [] rawtrajmap[i];
          delete [] trajmap[i];
          delete [] dummymap[i];
        }
        delete [] rawcostmap;
        delete [] costmap;
        delete [] rawtrajmap;
        delete [] trajmap;
        delete [] dummymap;
      }

      costmap = new float* [size_x];
      trajmap = new float* [size_x];
      rawcostmap = new unsigned char* [size_x];
      rawtrajmap = new unsigned char* [size_x];
      dummymap = new float* [size_x];
      for(int i=0; i<size_x; i++){
        costmap[i] = new float [size_y];
        trajmap[i] = new float [size_y];
        rawcostmap[i] = new unsigned char [size_y];
        rawtrajmap[i] = new unsigned char [size_y];
        dummymap[i] = new float [size_y];
      }
      initialized |= INIT_MAP;
      reset_traj_map = true;
    }
    initialized |= UPDATED_MAP;

    for(int y=0; y<size_y; y++){
      for(int x=0; x<size_x; x++){
        rawcostmap[x][y] = temp_map[x+size_x*y];
      }
    }
    delete [] temp_map;

    computeDistancestoNonfreeAreas(rawcostmap, size_x, size_y, exploration_obst_thresh, costmap, dummymap);

    double cell_padding = padding/resolution;

    for(int x=0; x<size_x; x++){
      for(int y=0; y<size_y; y++){
        if(costmap[x][y] <= outer_radius)
          costmap[x][y] = 254;
        else if(costmap[x][y] <= cell_padding)
          costmap[x][y] = max((cell_padding-costmap[x][y])*padding_cost/(cell_padding-outer_radius), rawcostmap[x][y]);
        else
          costmap[x][y] = rawcostmap[x][y];
      }
    }
    /*
    for(int x=0; x<size_x; x++){
      for(int y=0; y<size_y; y++){
        if(costmap[x][y] == 0)
          costmap[x][y] = 254;
        else if(costmap[x][y] <= inner_radius)
          costmap[x][y] = 253;
        else if(costmap[x][y] <= outer_radius)
          costmap[x][y] = 150;
        else if(costmap[x][y] <= padding)
          costmap[x][y] = max((padding-costmap[x][y])*150/(padding-outer_radius), rawcostmap[x][y]);
        else
          costmap[x][y] = rawcostmap[x][y];
      }
    }
    */

  }
  else if (strcasecmp(command, "pose") == 0){
    if(mxGetNumberOfElements(prhs[1]) != 3){
      mexErrMsgTxt("the pose (2nd argument) should have 3 values (x,y,yaw)");
      return;
    }
    double* start_pose = mxGetPr(prhs[1]);
    //set start
    global_start_x = start_pose[0];
    global_start_y = start_pose[1];
    global_start_theta = start_pose[2];

    initialized |= INIT_POSE;
    initialized |= UPDATED_POS;
  }
  else if (strcasecmp(command, "goal") == 0){
    if(mxGetNumberOfElements(prhs[1]) != 3){
      mexErrMsgTxt("the goal (2nd argument) should have 3 values (x,y,yaw)");
      return;
    }
    double* goal_pose = mxGetPr(prhs[1]);
    //set goal
    global_goal_x = goal_pose[0];
    global_goal_y = goal_pose[1];
    global_goal_theta = goal_pose[2];
    reset_traj_map = false;

    initialized |= INIT_TRAJ;
  }
  
  else if (strcasecmp(command, "explore_path") == 0){
    if((mxGetNumberOfElements(prhs[1]) % 3) != 0 || mxGetNumberOfElements(prhs[1]) == 0){
      mexErrMsgTxt("the exploration path (2nd argument) should be divisible by 3 (x,y,yaw)");
      return;
    }
    double* explore_path = mxGetPr(prhs[1]);
    int num_pts = mxGetNumberOfElements(prhs[1])/3;

    reset_traj_map = true;

    if(env){
      int i;
      for(i=1; i<num_pts; i++){

        //let it slide if the point in within our footprint
        float dx = explore_path[i] - global_start_x;
        float dy = explore_path[i + num_pts] - global_start_y;
        float dist = sqrt(dx*dx+dy*dy)/resolution;
        if(dist <= outer_radius)
          continue;

        int cell_x = (explore_path[i]-global_x_offset)/resolution;
        int cell_y = (explore_path[i + num_pts]-global_y_offset)/resolution;
        if(!OnMap(cell_x, cell_y) || costmap[cell_x][cell_y] >= obst_thresh)
          break;
      }
      //if(i==GP_Traj_p->num_traj_pts)
        i--;

      printf("\npruned %d points out of %d points\n\n",num_pts-(i+1),num_pts);
      global_goal_x = explore_path[i];
      global_goal_y = explore_path[i + num_pts];
      global_goal_theta = explore_path[i + 2*num_pts];
      //printf("exploration goal (%f, %f, %f)\n",global_goal_x,global_goal_y,global_goal_theta);
    }
    else{
      global_goal_x = explore_path[(num_pts-1)];
      global_goal_y = explore_path[(num_pts-1) + num_pts];
      global_goal_theta = explore_path[(num_pts-1) + 2*num_pts];
    }

    //store trajectory
    traj_length = num_pts;
    if(traj_path != NULL)
      delete [] traj_path;
    traj_path = new double[3*traj_length];
    memcpy(traj_path, explore_path, sizeof(double)*traj_length*3);

    initialized |= INIT_TRAJ;
  }
  

  else if (strcasecmp(command, "plan") == 0){
    vector<int> solution_stateIDs;
    vector<EnvMAGICLAT3Dpt_t> sbpl_path;
    if(initialized == INIT_DONE){
      //if(reset_traj_map)
        //makeTrajMap();

      //copy data to map
      double temp_rad_sqr = (outer_radius+1)*(outer_radius+1);
      double start_cell_x = (global_start_x-global_x_offset)/resolution;
      double start_cell_y = (global_start_y-global_y_offset)/resolution;
      printf("start clear (%f %f) ", start_cell_x, start_cell_y);
      int count2 = 0;
      for(int x=0; x < size_x; x++){
        for(int y=0; y < size_y; y++){
          unsigned char c;
          double dist = (start_cell_x-x)*(start_cell_x-x) + (start_cell_y-y)*(start_cell_y-y);
          if(dist < temp_rad_sqr){
            c = min(costmap[x][y], inner_obst_thresh-1);
            env->UpdateCost(x,y,c);
            count2++;
          }
          else{
            /*
            if(shouldRun==2)
              c = (unsigned char)min(max(costmap[x][y], trajmap[x][y]),251);
            else
            */
            c = (unsigned char)min(costmap[x][y],251);
            env->UpdateCost(x, y, c);
          }
        }
      }
      printf("footprint count = %d\n",count2);
      planner->costs_changed();
      //planner->force_planning_from_scratch();
      planner->set_start(env->SetStart(global_start_x-global_x_offset, 
                                       global_start_y-global_y_offset, 
                                       global_start_theta));

      planner->set_goal(env->SetGoal(global_goal_x-global_x_offset,
                                     global_goal_y-global_y_offset,
                                     global_goal_theta));
      /*
      int goal_cell_x = (global_goal_x-global_x_offset)/resolution;
      int goal_cell_y = (global_goal_y-global_y_offset)/resolution;
      printf("goal UTM(%f %f) cell(%d %d)\n",global_goal_x,global_goal_y,goal_cell_x,goal_cell_y);
      for(int py=goal_cell_y-2; py<=goal_cell_y+2; py++){
        for(int px=goal_cell_x-2; px<=goal_cell_x+2; px++){
          if(OnMap(px,py))
            printf("%d ",env->GetMapCost(px,py));
          else
            printf("? ");
        }
        printf("\n");
      }
      */
      if(planner->replan(PLANNING_TIME, &solution_stateIDs))
          mexPrintf("Solution is found\n");
      else{
          mexPrintf("Solution does not exist\n");
      }
      env->ConvertStateIDPathintoXYThetaPath(&solution_stateIDs, &sbpl_path);
      printf("size of solution = %d\n", (int)sbpl_path.size());

      plhs[0] = mxCreateDoubleMatrix(sbpl_path.size(),1,mxREAL);
      plhs[1] = mxCreateDoubleMatrix(sbpl_path.size(),1,mxREAL);
      plhs[2] = mxCreateDoubleMatrix(sbpl_path.size(),1,mxREAL);
      double* return_x = mxGetPr(plhs[0]);
      double* return_y = mxGetPr(plhs[1]);
      double* return_yaw = mxGetPr(plhs[2]);
      for(unsigned int i=0; i<sbpl_path.size(); i++){
        return_x[i] = sbpl_path[i].x+global_x_offset;
        return_y[i] = sbpl_path[i].y+global_y_offset;
        return_yaw[i] = sbpl_path[i].theta;
      }

      initialized = NEED_UPDATE;
      initialized &= ~INIT_TRAJ;
    }
  }
  else
    mexErrMsgTxt("lattice_planner: command not recognized");
}

