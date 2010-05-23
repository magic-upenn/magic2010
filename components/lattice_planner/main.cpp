using namespace std;
#include <cstdlib>
#include <vector>
#include "ipc.h"
#include "MagicPlanDataTypes.h"
#include "headers.h"
#include "envMagic.h"
#include "MagicTraj.hh"

//GET RID OF THESE (temporary for Jon's matlab visualization)
//#include "map_globals.h"
//#include <iostream>
//#include <fstream>

// name of this module for IPC
#define MODULE_NAME "Lattice Planner"

#define min(a,b) (a<b?a:b)
#define max(a,b) (a>b?a:b)

int size_x=0;
int size_y=0;
float resolution=0;
unsigned char** rawcostmap = NULL;
unsigned char** rawtrajmap = NULL;
float** costmap = NULL;
float** trajmap = NULL;
float** dummymap = NULL;
EnvironmentMAGICLAT* env = NULL;
ARAPlanner* planner = NULL;
float max_velocity=0; //meters per sec
float max_turn_rate=0; //radians per sec
vector<sbpl_2Dpt_t> perimeterptsV;
float inner_radius = 0;
float outer_radius = 0;
float padding = 3;
int exploration_obst_thresh = 250;
int obst_thresh = 255;
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
char initialized = 0;
#define INIT_RES    1<<0
#define INIT_PARAMS 1<<1
#define INIT_MAP    1<<2
#define INIT_POSE   1<<3
#define INIT_TRAJ   1<<4
#define UPDATED_MAP 1<<5
#define UPDATED_POS 1<<6
#define INIT_DONE (INIT_RES | INIT_PARAMS | INIT_MAP | INIT_POSE | INIT_TRAJ | UPDATED_MAP | UPDATED_POS)
#define NEED_UPDATE (INIT_RES | INIT_PARAMS | INIT_MAP | INIT_POSE | INIT_TRAJ)



bool OnMap(int x, int y) {
  // function to determine if a point is on the map
  return ((x<size_x) && (x>=0) && (y<size_y) && (y >=0));
}

static void GP_MAP_DATA_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	//function to handle map parameter update messages
	GP_MAP_DATA_PTR gp_map_data_p;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_map_data_p);
	printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

	//update size variables
	resolution = gp_map_data_p->cost_cell_size;
  initialized |= INIT_RES;

	//frees memory used by the message
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) gp_map_data_p);
	IPC_freeByteArray(callData);
}

static void GP_ROBOT_PARAMETER_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	// function handles robot parameter update messages
	GP_ROBOT_PARAMETER_PTR gp_robot_parameter_p;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_robot_parameter_p);
	printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

	//stores new parameters
	max_velocity = gp_robot_parameter_p->MAX_VELOCITY;
	max_turn_rate = gp_robot_parameter_p->MAX_TURN_RATE;

	//get the robot perimeter
  outer_radius = sqrt(pow(gp_robot_parameter_p->PerimeterArray[0],2) + pow(gp_robot_parameter_p->PerimeterArray[1],2));
  inner_radius = min(fabs(gp_robot_parameter_p->PerimeterArray[0]),fabs(gp_robot_parameter_p->PerimeterArray[1]));
  perimeterptsV.reserve(gp_robot_parameter_p->I_DIMENSION);
  for (int i=0; i < gp_robot_parameter_p->I_DIMENSION; i++) {
    sbpl_2Dpt_t pt;
    pt.x = gp_robot_parameter_p->PerimeterArray[i*gp_robot_parameter_p->J_DIMENSION];
    pt.y = gp_robot_parameter_p->PerimeterArray[i*gp_robot_parameter_p->J_DIMENSION+1];
    perimeterptsV.push_back(pt);
    float r = sqrt(pt.x*pt.x+pt.y*pt.y);
    if(r>outer_radius)
      outer_radius = r;
    inner_radius = min(inner_radius,min(fabs(pt.x),fabs(pt.y)));
  }
  printf("outer_radius=%f inner_radius=%f\n",outer_radius,inner_radius);
  inner_radius /= resolution;
  outer_radius /= resolution;
  initialized |= INIT_PARAMS;

	//free the memory used by the message
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) gp_robot_parameter_p);
	IPC_freeByteArray(callData);
}

static void GP_FULL_UPDATE_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	//function handles full map updates
	GP_FULL_UPDATE_PTR gp_full_update_p;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_full_update_p);
	printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

  if(size_x != gp_full_update_p->sent_cost_x || size_y != gp_full_update_p->sent_cost_y || env == NULL){
    //update size variables
    int old_size_x = size_x;
    size_x = gp_full_update_p->sent_cost_x;
    size_y = gp_full_update_p->sent_cost_y;
    global_x_offset = gp_full_update_p->UTM_x;
    global_y_offset = gp_full_update_p->UTM_y;
    
    if(env != NULL)
      delete env;

    env = new EnvironmentMAGICLAT();
    env->SetEnvParameter("cost_obsthresh",254);
    env->SetEnvParameter("cost_inscribed_thresh",253);
    env->SetEnvParameter("cost_possibly_circumscribed_thresh",252);

    const char* primitive_filename = "magic.mprim";
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

  for(int y=0; y<size_y; y++)
    for(int x=0; x<size_x; x++)
      rawcostmap[x][y] = gp_full_update_p->cost_map[x+size_x*y];

  computeDistancestoNonfreeAreas(rawcostmap, size_x, size_y, exploration_obst_thresh, costmap, dummymap);

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

	//free memory used by message
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) gp_full_update_p);
	IPC_freeByteArray(callData);
}

static void GP_SHORT_UPDATE_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	// function handles short map updates
	GP_SHORT_UPDATE_PTR gp_short_update_p;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_short_update_p);
	printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

	//variables for map coordinates
	int lly = gp_short_update_p->y_cost_start; 
	int llx = gp_short_update_p->x_cost_start; 
	int sizey = gp_short_update_p->sent_cost_y; 
	int sizex = gp_short_update_p->sent_cost_x; 

	//place data into the correct arrays
	for(int j = 0; j< sizey; j++){
		for (int i=0;i< sizex;i++){
			if (OnMap(i+llx, j+lly)) 
        rawcostmap[i+llx][j+lly] = gp_short_update_p->cost_map[i+sizex*j];
		}
	}

  initialized |= UPDATED_MAP;

  computeDistancestoNonfreeAreas(rawcostmap, size_x, size_y, exploration_obst_thresh, costmap, dummymap);

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

	//free the message data
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) gp_short_update_p);
	IPC_freeByteArray(callData);
}

static void GP_POSITION_UPDATE_Handler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	//function handles the position update messages
	GP_POSITION_UPDATE_PTR gp_position_update_p;
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&gp_position_update_p);
	printf("Handler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

  //set start
  global_start_x = gp_position_update_p->x;
  global_start_y = gp_position_update_p->y;
  global_start_theta = gp_position_update_p->theta;

  initialized |= INIT_POSE;
  initialized |= UPDATED_POS;

	//frees memory used by message
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *)gp_position_update_p);
	IPC_freeByteArray(callData);
}

static void GPTRAJHandler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	// handles incoming trajectory messages
	GP_TRAJECTORY_PTR GP_Traj_p; // pointer to trajectory message

	// get the data from IPC
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&GP_Traj_p);
	printf("GPTRAJHandler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

  if(GP_Traj_p->num_traj_pts > 0){
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
  printf("\nIPC_connect(%s)\n", MODULE_NAME);
  IPC_connect(MODULE_NAME);

  //Subscribe to the messages that this module listens to.
	printf("\nIPC_subscribe(%s, GP_MAP_DATA_Handler, %s)\n", GP_MAP_DATA_MSG, MODULE_NAME);
	IPC_subscribe(GP_MAP_DATA_MSG, GP_MAP_DATA_Handler, (void *)MODULE_NAME);

	printf("\nIPC_subscribe(%s, GP_ROBOT_PARAMETER_Handler, %s)\n", GP_ROBOT_PARAMETER_MSG, MODULE_NAME);
	IPC_subscribe(GP_ROBOT_PARAMETER_MSG, GP_ROBOT_PARAMETER_Handler, (void *)MODULE_NAME);

	printf("\nIPC_subscribe(%s, GP_FULL_UPDATE_Handler, %s)\n", GP_FULL_UPDATE_MSG, MODULE_NAME);
	IPC_subscribe(GP_FULL_UPDATE_MSG, GP_FULL_UPDATE_Handler, (void *)MODULE_NAME);

	printf("\nIPC_subscribe(%s, GP_SHORT_UPDATE_Handler, %s)\n", GP_SHORT_UPDATE_MSG, MODULE_NAME);
	IPC_subscribe(GP_SHORT_UPDATE_MSG, GP_SHORT_UPDATE_Handler, (void *)MODULE_NAME);

	printf("\nIPC_subscribe(%s, GP_POSITION_UPDATE_Handler, %s)\n", GP_POSITION_UPDATE_MSG, MODULE_NAME);
	IPC_subscribe(GP_POSITION_UPDATE_MSG, GP_POSITION_UPDATE_Handler, (void *)MODULE_NAME);

  printf("\nIPC_subscribe(%s, msg2Handler, %s)\n", GP_TRAJECTORY_MSG, MODULE_NAME);
  IPC_subscribe(GP_TRAJECTORY_MSG, GPTRAJHandler, (void *)MODULE_NAME);

  Magic::MotionTraj path_msg;
  IPC_defineMsg("Trajectory", IPC_VARIABLE_LENGTH, path_msg.getIPCFormat());

  // call IPC and wait for messages
  vector<int> solution_stateIDs;
  vector<EnvMAGICLAT3Dpt_t> sbpl_path;
  
  path_msg.waypoints = NULL;
  
  while(1){
    IPC_listenWait(100);
    if(initialized == INIT_DONE){

      if(reset_traj_map)
        makeTrajMap();

      //copy data to map
      for(int x=0; x < size_x; x++){
        for(int y=0; y < size_y; y++){
          unsigned char c;
          if(costmap[x][y] < 252)
            c = (unsigned char)min(max(costmap[x][y], trajmap[x][y]),251);
            //c = (unsigned char)min(costmap[x][y] + trajmap[x][y], 251);
          else
            c= (unsigned char)costmap[x][y];
          env->UpdateCost(x, y, c);
        }
      }
      planner->costs_changed();
      planner->set_start(env->SetStart(global_start_x-global_x_offset, 
                                       global_start_y-global_y_offset, 
                                       global_start_theta));

      planner->set_goal(env->SetGoal(global_goal_x-global_x_offset,
                                     global_goal_y-global_y_offset,
                                     global_goal_theta));
      if(planner->replan(1.0, &solution_stateIDs))
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
      for(int i=0; i<sbpl_path.size(); i++){
        path_msg.waypoints[i].x = sbpl_path[i].x+global_x_offset;
        path_msg.waypoints[i].y = sbpl_path[i].y+global_y_offset;
        path_msg.waypoints[i].yaw = sbpl_path[i].theta;
        path_msg.waypoints[i].v = 0.5;
      }
      IPC_publishData("Trajectory", &path_msg);
      
      initialized = NEED_UPDATE;
    }
  }

  IPC_disconnect();
  return 0;
}
