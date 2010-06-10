using namespace std;
#include <cstdlib>
#include <vector>
#include "ipc.h"
#include "MagicPlanDataTypes.h"
//#include "headers.h"
#include "../sbpl/src/sbpl/headers.h"
#include "envMagic.h"
#include "mapConverter.h"
#include "MagicTraj.hh"
#include "MagicPose.hh"
#include "unistd.h"
#include <string>

//GET RID OF THESE (temporary for Jon's matlab visualization)
//#include "map_globals.h"
//#include <iostream>
//#include <fstream>

// name of this module for IPC
#define MODULE_NAME "Lattice Planner"

#define min(a,b) (a<b?a:b)
#define max(a,b) (a>b?a:b)

#define PLANNING_TIME 0.75

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
float padding = 0.8;
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
float* traj_path = NULL;

bool reset_traj_map = false;

//initialization flags
int shouldRun = 0;
char initialized = 0;
#define INIT_RES    1<<0
#define INIT_PARAMS 1<<1
#define INIT_MAP    1<<2
#define INIT_POSE   1<<3
#define INIT_TRAJ   1<<4
#define UPDATED_MAP 1<<5
#define UPDATED_POS 1<<6
#define INIT_DONE (INIT_MAP | INIT_POSE | INIT_TRAJ | UPDATED_MAP | UPDATED_POS)
#define NEED_UPDATE (INIT_MAP | INIT_POSE | INIT_TRAJ)



bool OnMap(int x, int y) {
  // function to determine if a point is on the map
  return ((x<size_x) && (x>=0) && (y<size_y) && (y >=0));
}

static void GP_FULL_UPDATE_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	//function handles full map updates
	GP_MAGIC_MAP_PTR gp_full_update_p;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_full_update_p);
	printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

  unsigned char* temp_map = NULL;
  int new_size_x;
  int new_size_y;
  convertMap(gp_full_update_p, false, gp_full_update_p->resolution, 
             &temp_map, NULL, NULL,
             &new_size_x, &new_size_y);

  if(true || size_x != new_size_x || size_y != new_size_y || env == NULL){
    //update size variables
    int old_size_x = size_x;
    size_x = new_size_x;
    size_y = new_size_y;
    global_x_offset = gp_full_update_p->UTM_x;
    global_y_offset = gp_full_update_p->UTM_y;
    
    if(env != NULL){
      /*
      count++;
      //delete planner;
      if(count>8){
        exit(0);
      }
      */
      delete env;
    }

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
        costmap[x][y] = max((cell_padding-costmap[x][y])*200/(cell_padding-outer_radius), rawcostmap[x][y]);
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

	//free memory used by message
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) gp_full_update_p);
	IPC_freeByteArray(callData);
}

static void GP_POSITION_UPDATE_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	//function handles the position update messages
  Magic::Pose* gp_position_update_p;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_position_update_p);
	printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

  //set start
  global_start_x = gp_position_update_p->x;
  global_start_y = gp_position_update_p->y;
  global_start_theta = gp_position_update_p->yaw;

  initialized |= INIT_POSE;
  initialized |= UPDATED_POS;

	//frees memory used by message
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *)gp_position_update_p);
	IPC_freeByteArray(callData);
}

static void GP_STATE_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	//function handles the position update messages
  GP_SET_STATE_PTR state_msg;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&state_msg);
	printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

  shouldRun = state_msg->shouldRun;

	//frees memory used by message
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *)state_msg);
	IPC_freeByteArray(callData);
}

static void GPTRAJHandler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	// handles incoming trajectory messages
	GP_TRAJECTORY_PTR GP_Traj_p; // pointer to trajectory message

	// get the data from IPC
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&GP_Traj_p);
	printf("GPTRAJHandler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

  if(GP_Traj_p->num_traj_pts > 0 && 
      ((GP_Traj_p->id == 0 &&  shouldRun==1) || (GP_Traj_p->id>0 && shouldRun==2))){
    reset_traj_map = true;

    //set goal
    global_goal_x = GP_Traj_p->traj_array[(GP_Traj_p->num_traj_pts-1)*GP_Traj_p->traj_dim];
    global_goal_y = GP_Traj_p->traj_array[(GP_Traj_p->num_traj_pts-1)*GP_Traj_p->traj_dim+1];
    global_goal_theta = GP_Traj_p->traj_array[(GP_Traj_p->num_traj_pts-1)*GP_Traj_p->traj_dim+2];

    //store trajectory
    traj_length = GP_Traj_p->num_traj_pts;
    traj_dim = GP_Traj_p->traj_dim;
    if(traj_path != NULL)
      delete [] traj_path;
    traj_path = new float[traj_length*traj_dim];
    memcpy(traj_path, GP_Traj_p->traj_array, sizeof(float)*traj_length*traj_dim);

    initialized |= INIT_TRAJ;
  }
  
	// free variable length elements and message body
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) GP_Traj_p);
	IPC_freeByteArray(callData);
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



int main(int argc, char** argv){
  char* id = getenv("ROBOT_ID");
  string robotName = string("Robot") + id;

  string mapName = robotName + "/Cost_Map_Full"; 
  string poseName = robotName + "/Pose"; 
  string waypointsName = robotName + "/Waypoints"; 
  string trajName = robotName + "/Planner_Path"; 
  string stateName = robotName + "/Planner_State"; 

  printf("\nIPC_connect(%s)\n", MODULE_NAME);
  IPC_connect(MODULE_NAME);

  //Subscribe to the messages that this module listens to.
	IPC_subscribe(mapName.c_str(), GP_FULL_UPDATE_Handler, (void *)MODULE_NAME);
  IPC_setMsgQueueLength((char*)mapName.c_str(), 1);

	IPC_subscribe(poseName.c_str(), GP_POSITION_UPDATE_Handler, (void *)MODULE_NAME);
  IPC_setMsgQueueLength((char*)poseName.c_str(), 1);

  IPC_subscribe(waypointsName.c_str(), GPTRAJHandler, (void *)MODULE_NAME);
  IPC_setMsgQueueLength((char*)waypointsName.c_str(), 1);

  IPC_subscribe(stateName.c_str(), GP_STATE_Handler, (void *)MODULE_NAME);
  IPC_setMsgQueueLength((char*)stateName.c_str(), 1);


  Magic::MotionTraj path_msg;
  IPC_defineMsg(trajName.c_str(), IPC_VARIABLE_LENGTH, path_msg.getIPCFormat());


  printf("IPC init done!\n");


  // call IPC and wait for messages
  vector<int> solution_stateIDs;
  vector<EnvMAGICLAT3Dpt_t> sbpl_path;
  
  path_msg.waypoints = NULL;

  while(1){
    IPC_listenWait(100);
    if(initialized == INIT_DONE && shouldRun){

      if(reset_traj_map)
        makeTrajMap();

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
            if(costmap[x][y] < 252)
              if(shouldRun==2)
                c = (unsigned char)min(max(costmap[x][y], trajmap[x][y]),251);
              else
                c = (unsigned char)min(costmap[x][y],251);
              //c = (unsigned char)min(costmap[x][y] + trajmap[x][y], 251);
            else
              c= (unsigned char)costmap[x][y];
            env->UpdateCost(x, y, c);
          }
        }
      }
      printf("footprint count = %d\n",count2);
      planner->costs_changed();
      planner->set_start(env->SetStart(global_start_x-global_x_offset, 
                                       global_start_y-global_y_offset, 
                                       global_start_theta));

      planner->set_goal(env->SetGoal(global_goal_x-global_x_offset,
                                     global_goal_y-global_y_offset,
                                     global_goal_theta));

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

      if(planner->replan(PLANNING_TIME, &solution_stateIDs))
          printf("Solution is found\n");
      else{
          printf("Solution does not exist\n");
      }
      env->ConvertStateIDPathintoXYThetaPath(&solution_stateIDs, &sbpl_path);
      printf("size of solution = %d\n", (int)sbpl_path.size());
      
      if(path_msg.waypoints)
        delete [] path_msg.waypoints;
      path_msg.size = sbpl_path.size();
      path_msg.t = time(NULL);
      path_msg.waypoints = new Magic::MotionTrajWaypoint[sbpl_path.size()];
      for(unsigned int i=0; i<sbpl_path.size(); i++){
        path_msg.waypoints[i].x = sbpl_path[i].x+global_x_offset;
        path_msg.waypoints[i].y = sbpl_path[i].y+global_y_offset;
        path_msg.waypoints[i].yaw = sbpl_path[i].theta;
        path_msg.waypoints[i].v = 0.5;
      }
      IPC_publishData(trajName.c_str(), &path_msg);
      
      initialized = NEED_UPDATE;
    }
  }

  IPC_disconnect();
  return 0;
}
