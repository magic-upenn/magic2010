#define _USE_MATH_DEFINES
//generic includes
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <cstdio>
#include <vector>
#include <deque>
#include <cstring>
#include <time.h>
#include <queue>
#include <limits>
#include <fstream>
#include <string>
//#include "stdint.h"

using namespace std;
//local files
#include "map_globals.h"
#include "test_planner.h"
#include "filetransfer.h"
#include "generate_map.h"


//IPC related
#include "ipc.h"
#include "messages_IPC.h"

// name of this module for IPC
#define MODULE_NAME "Test Planner linux"


// allocate initial message structures
GP_ROBOT_PARAMETER robot;
GP_MAP_DATA map_data;
GP_POSITION_UPDATE posit;
GP_GOAL_ASSIGN goal_assign;
GP_FULL_UPDATE full;
GP_SHORT_UPDATE gp_short;
GP_TRAJECTORY traj;

//initial map dimensions
int mapm=1000, mapn=1000;


//int repetition;

// module written by Jonathan Michael Butzke 
//	 serves test stub simulating the remainder of the robot
//  input: reads map file from disk and keyboard entry
//  output: sends appropriate messages to global planner module
//
//  Current limitations: coverage, cost, and elevation maps are required to be the same size


static void GPTRAJHandler (MSG_INSTANCE msgRef, BYTE_ARRAY callData, void *clientData) {
	// handles incoming trajectory messages
	static int count=0; // used for automated testing to repeatedly send updates "count" times
	GP_TRAJECTORY_PTR GP_Traj_p; // pointer to trajectory message

	// get the data from IPC
	IPC_unmarshall(IPC_msgInstanceFormatter(msgRef), callData, (void **)&GP_Traj_p);
	printf("GPTRAJHandler: Receiving %s (size %lu) [%s] \n", IPC_msgInstanceName(msgRef),  sizeof(callData), (char *)clientData);

	// copy size information to local variable
	traj.num_traj_pts = GP_Traj_p->num_traj_pts;
	traj.traj_dim = GP_Traj_p->traj_dim;

	// remove old trajectory and replace it with new one
	delete [] traj.traj_array;
	traj.traj_array = new float[traj.num_traj_pts*traj.traj_dim];

	// copy elements into new trajectory
	printf("%d trajectory points with %d dimensions\n", traj.num_traj_pts, traj.traj_dim);
	for (int i =0; i< traj.num_traj_pts; i++) {
		for (int j=0; j< traj.traj_dim; j++) {
			traj.traj_array[i*traj.traj_dim+j] = GP_Traj_p->traj_array[i*traj.traj_dim+j];
		}
	}

	// free variable length elements and message body
	IPC_freeDataElements(IPC_msgInstanceFormatter(msgRef), (void *) GP_Traj_p);
	IPC_freeByteArray(callData);

	// send out an update message which will trigger trajectory message in response 
	if(count <0) {
		cout << " count is now : " << count << endl;

		//file name for reading
		char fn[] = "Map_out.txt";
		getfiles(&(full.coverage_map), &(full.cost_map), &(full.elev_map), fn, mapm, mapn);

		// set map size info
		map_data.cost_size_x = map_data.coverage_size_x = map_data.elev_size_x = full.sent_cost_x = full.sent_elev_x = full.sent_cover_x = mapm;
		map_data.cost_size_y = map_data.coverage_size_y = map_data.elev_size_y = full.sent_cost_y = full.sent_elev_y = full.sent_cover_y = mapn;

		//set time to current clock tick
		full.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);//time(NULL);

		//print to screen and publish message for full map update
		IPC_printData(IPC_msgFormatter (GP_FULL_UPDATE_MSG), stdout, &full);
		IPC_publishData(GP_FULL_UPDATE_MSG, &full);

		//set time to current clock tick
		posit.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);//time(NULL);

		//set position information
		posit.x = (float)(traj.traj_array[traj.num_traj_pts*traj.traj_dim-6]*map_data.cost_cell_size);
		posit.y = (float)(traj.traj_array[traj.num_traj_pts*traj.traj_dim-5]*map_data.cost_cell_size);

		// print info to scren then publish position update
		printf("%f %f \n", posit.x, posit.y);
		IPC_printData(IPC_msgFormatter (GP_POSITION_UPDATE_MSG), stdout, &posit);
		IPC_publishData(GP_POSITION_UPDATE_MSG, &posit);

		count++;
	}
	else {count =0;}
}

bool OnMap(int x, int y) {
	//function to verify coordinates are within map size
	if ((x<map_data.cost_size_x) && (x>=0) && (y<map_data.cost_size_x) && (y >=0)) {return true; }
	else { return false;}
}

void send_part_update(void) {

	char fn[] = "Map_out.txt";

	//variables to hold lower left and upper right map corners (smallest x, smallest y) - (largest x, largest y)
	int llx, lly, urx=-1, ury=-1;

	//allocate temp space to hold maps from disk
	unsigned char * cv_map = new unsigned char[1], *cs_map = new unsigned char[1];
	int16_t * el_map = new int16_t[1];

	getfiles(&cv_map, &(cs_map), &(el_map), fn, mapm, mapn);

	map_data.cost_size_x = map_data.coverage_size_x = map_data.elev_size_x = full.sent_cost_x = full.sent_elev_x = full.sent_cover_x = mapm;
	map_data.cost_size_y = map_data.coverage_size_y = map_data.elev_size_y = full.sent_cost_y = full.sent_elev_y = full.sent_cover_y = mapn;

	// set the map +/- 8 m from current location  -   rudimentary check on bounds
	llx = (posit.x -18)/map_data.cost_cell_size;
	if (llx < 0) llx = 0;
	lly = (posit.y -18)/map_data.cost_cell_size;
	if (lly  < 0) lly =0;
	urx = (posit.x +18)/map_data.cost_cell_size;
	if (urx >= map_data.cost_size_x) urx = map_data.cost_size_x;
	ury = (posit.y +18)/map_data.cost_cell_size;
	if (ury >= map_data.cost_size_y) ury = map_data.cost_size_y;


	int sizex = urx - llx;
	int sizey = ury - lly;

	// delete old maps
	delete [] gp_short.coverage_map;
	delete [] gp_short.cost_map;
	delete [] gp_short.elev_map;

	// set variables
	gp_short.sent_cover_x=gp_short.sent_cost_x=gp_short.sent_elev_x = sizex;
	gp_short.sent_cover_y=gp_short.sent_cost_y=gp_short.sent_elev_y = sizey;

	gp_short.x_cover_start = gp_short.x_cost_start = gp_short.x_elev_start = llx;
	gp_short.y_cover_start = gp_short.y_cost_start = gp_short.y_elev_start = lly;

	// allocate new maps
	gp_short.coverage_map = new unsigned char[sizex*sizey];
	gp_short.cost_map = new unsigned char[sizex*sizey];
	gp_short.elev_map = new int16_t[sizex*sizey];

	// copy elements from full map into short (multiple memcpy getting the whole row at once would be quicker)
	for (int j = lly; j < ury; j++) {
		for (int i = llx; i < urx; i++) {
			if (OnMap(i,j)) {
				gp_short.coverage_map[(i-llx)+sizex*(j-lly)] = KNOWN - cs_map[i+map_data.coverage_size_x*j];
				gp_short.cost_map[(i-llx)+sizex*(j-lly)] = cs_map[i+map_data.cost_size_x*j];
				gp_short.elev_map[(i-llx)+sizex*(j-lly)] = el_map[i+map_data.elev_size_x*j];
			}
		}
	}

	// set timestamp				
	gp_short.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);

	//print and publish message
	IPC_printData(IPC_msgFormatter (GP_SHORT_UPDATE_MSG), stdout, &gp_short);
	IPC_publishData(GP_SHORT_UPDATE_MSG, &gp_short);

	// delete temporary maps
	delete [] cv_map;
	delete [] cs_map;
	delete [] el_map;
}


static void stdinHnd (int fd, void *clientData) {
	// handle input from keyboard
	char inputLine[81];
	fgets(inputLine, 80, stdin);

	switch (inputLine[0]) {
		case 'q': case 'Q':
			IPC_disconnect();
			exit(0);
		case '1':
			{ // initialize map 
				//initialize values to -1
				map_data.cost_size_x = 10;
				map_data.cost_size_y = 10;
				map_data.cost_cell_size = 0.1;

				//set time to current clock tick
				map_data.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);//time(NULL);

				//get map parameters
				cout << endl << "map size x in cells?" << endl;
				while (map_data.cost_size_x <=0) { cin >> map_data.cost_size_x; mapn = map_data.elev_size_x = map_data.coverage_size_x = map_data.cost_size_x; }

				cout << endl << "map size y in cells?" << endl;
				while (map_data.cost_size_y <=0) { cin >> map_data.cost_size_y; mapm = map_data.elev_size_y = map_data.coverage_size_y = map_data.cost_size_y; }

				cout << endl << "cell size in meters?" << endl;
				while (map_data.cost_cell_size <=0) { cin >> map_data.cost_cell_size; map_data.elev_cell_size = map_data.coverage_cell_size = map_data.cost_cell_size; }

				// print and publish data
				IPC_printData(IPC_msgFormatter (GP_MAP_DATA_MSG), stdout, &map_data);
				IPC_publishData(GP_MAP_DATA_MSG, &map_data);

				// remove old maps
				delete [] full.coverage_map;
				delete [] full.cost_map;
				delete [] full.elev_map;

				// set sizes
				full.sent_cost_x = full.sent_elev_x = full.sent_cover_x = mapm;
				full.sent_cost_y = full.sent_elev_y = full.sent_cover_y = mapn;

				//allocate new storage
				full.coverage_map = new unsigned char[mapn*mapm];
				full.cost_map = new unsigned char[mapn*mapm];
				full.elev_map = new int16_t[mapn*mapm];

				break;
			}
		case '2':
			{ // send robot parameters 
				robot.MAX_VELOCITY = 1;
				robot.MAX_TURN_RATE = 1;
				robot.I_DIMENSION = 4;
				robot.J_DIMENSION = 2;
				robot.sensor_height = 120;
				robot.sensor_radius = 30;

				cout << endl << "max velocity (m/s)?" << endl;
				while (robot.MAX_VELOCITY <=0) { cin >> robot.MAX_VELOCITY;}

				cout << endl << "max turn rate (rad/s)?" << endl;
				while (robot.MAX_TURN_RATE <=0) { cin >> robot.MAX_TURN_RATE;}

				cout << endl << "sensor radius (m)?" << endl;
				while (robot.sensor_radius <=0) { cin >> robot.sensor_radius;}

				cout << endl << "sensor_height (cm)?" << endl;
				while (robot.sensor_height <=0) { cin >> robot.sensor_height;}

				cout << endl << "Number of robot perimeter points?" << endl;
				while (robot.I_DIMENSION <=0) { cin >> robot.I_DIMENSION;}

				// allocate storage
				robot.PerimeterArray = new double[robot.I_DIMENSION*robot.J_DIMENSION];

				// input points
				for(int q = 0; q < robot.I_DIMENSION; q++) {
					for (int r=0; r< robot.J_DIMENSION; r++) {
						printf("\n coordinate (%d, %d):", q, r);
						//cin >> robot.PerimeterArray[q*robot.J_DIMENSION+r];
						robot.PerimeterArray[q*robot.J_DIMENSION+r] = 0.05;
					}
				}

				//print and send data
				IPC_printData(IPC_msgFormatter (GP_ROBOT_PARAMETER_MSG), stdout, &robot);
				IPC_publishData(GP_ROBOT_PARAMETER_MSG, &robot);

				// delete storage
				delete [] robot.PerimeterArray;
				break;
			}
		case '3':
			{ // position update
				// use midpoint of returned trajectory (used for automated testing comment out and uncomment following block for manual entry
				if (traj.num_traj_pts>3) {
					int idx = traj.num_traj_pts-1;
				posit.x = (double)traj.traj_array[idx*6]*map_data.cost_cell_size;
				posit.y = (double)traj.traj_array[idx*6+1]*map_data.cost_cell_size;
				} 

				//posit.x = -1;
				//posit.y = -1;
				
				posit.theta = 0;

				printf("starting point is %4.0f, %4.0f\n", posit.x, posit.y);
				cout << endl << "X position in meters?" << endl;
				while ((posit.x<0)||(posit.x>=(map_data.cost_size_x*map_data.cost_cell_size))) { cin >> posit.x;}

				cout << endl << "Y position in meters?" << endl;
				while ((posit.y<0)||(posit.y>=(map_data.cost_size_y*map_data.cost_cell_size))) { cin >> posit.y;}

				cout << endl << "theta (0-2*PI)?" << endl;
				while ((posit.theta<0)||(posit.theta>2*M_PI)) { cin >> posit.theta;}

				// used for sending a preliminary full update with each position update.  not needed
				//tempx = posit.x/map_data.cost_cell_size;
				//tempy = posit.y/map_data.cost_cell_size;
				//IPC_publishData(GP_FULL_UPDATE_MSG, &full);

				//set time to current clock tick
				posit.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);//time(NULL);

				//print and publish message
				IPC_printData(IPC_msgFormatter (GP_POSITION_UPDATE_MSG), stdout, &posit);
				IPC_publishData(GP_POSITION_UPDATE_MSG, &posit);

				break;
			}
		case '4':
			{ // full map update
				//cout << endl << "map file to load?" << endl;
				//char fn[50];
				//cin >> fn;

				char fn[] = "Map.txt";

				getfiles(&(full.coverage_map), &(full.cost_map), &(full.elev_map), fn, mapm, mapn);

				// set map parameters
				map_data.cost_size_x = map_data.coverage_size_x = map_data.elev_size_x = full.sent_cost_x = full.sent_elev_x = full.sent_cover_x = mapm;
				map_data.cost_size_y = map_data.coverage_size_y = map_data.elev_size_y = full.sent_cost_y = full.sent_elev_y = full.sent_cover_y = mapn;

				// temp variables for automated testing clears initial area around robot start point out (makes 1m square area known)
				// only requirement is that the initial start cell is not unknown 
				int tempx = 600;//posit.x/map_data.cost_cell_size;
				int tempy = 600;//posit.y/map_data.cost_cell_size;

					for (int j = tempy-10; j < tempy+10; j++) {
					for (int i = tempx-10; i < tempx+10; i++) {
						if (OnMap(i, j) && full.cost_map[i+map_data.cost_size_x*j]!=OBSTACLE) {full.coverage_map[i+map_data.cost_size_x*j] = KNOWN;}
					}
				}

				//set time to current clock tick
				full.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);

				//print and publish data
				IPC_printData(IPC_msgFormatter (GP_FULL_UPDATE_MSG), stdout, &full);
				IPC_publishData(GP_FULL_UPDATE_MSG, &full);
				break;
			}
		case '5':
			{ // partial map update
				char fn[] = "Map_out.txt";

				//variables to hold lower left and upper right map corners (smallest x, smallest y) - (largest x, largest y)
				int llx, lly, urx=-1, ury=-1;

				//allocate temp space to hold maps from disk
				unsigned char * cv_map = new unsigned char[1], *cs_map = new unsigned char[1];
				int16_t * el_map = new int16_t[1];

				getfiles(&cv_map, &(cs_map), &(el_map), fn, mapm, mapn);

				map_data.cost_size_x = map_data.coverage_size_x = map_data.elev_size_x = full.sent_cost_x = full.sent_elev_x = full.sent_cover_x = mapm;
				map_data.cost_size_y = map_data.coverage_size_y = map_data.elev_size_y = full.sent_cost_y = full.sent_elev_y = full.sent_cover_y = mapn;

				// set the map +/- 8 m from current location  -   rudimentary check on bounds
				llx = (posit.x -30)/map_data.cost_cell_size;
				if (llx < 0) llx = 0;
				lly = (posit.y -30)/map_data.cost_cell_size;
				if (lly  < 0) lly =0;
				urx = (posit.x +30)/map_data.cost_cell_size;
				if (urx >= map_data.cost_size_x) urx = map_data.cost_size_x;
				ury = (posit.y +30)/map_data.cost_cell_size;
				if (ury >= map_data.cost_size_y) ury = map_data.cost_size_y;


				//// section to use for manual entry
				//cout << "select lower left corner x: ";
				//cin >> llx;
				//cout << " y: ";
				//cin >> lly;
				//cout << endl << "select upper right corner x: ";
				//while (urx < llx) {cin >> urx; }
				//cout << " y: ";
				//while (ury < lly) {cin >> ury; }
				//cout << endl;

				int sizex = urx - llx;
				int sizey = ury - lly;

				// delete old maps
				delete [] gp_short.coverage_map;
				delete [] gp_short.cost_map;
				delete [] gp_short.elev_map;

				// set variables
				gp_short.sent_cover_x=gp_short.sent_cost_x=gp_short.sent_elev_x = sizex;
				gp_short.sent_cover_y=gp_short.sent_cost_y=gp_short.sent_elev_y = sizey;

				gp_short.x_cover_start = gp_short.x_cost_start = gp_short.x_elev_start = llx;
				gp_short.y_cover_start = gp_short.y_cost_start = gp_short.y_elev_start = lly;

				// allocate new maps
				gp_short.coverage_map = new unsigned char[sizex*sizey];
				gp_short.cost_map = new unsigned char[sizex*sizey];
				gp_short.elev_map = new int16_t[sizex*sizey];

				// copy elements from full map into short (multiple memcpy getting the whole row at once would be quicker)
				for (int j = lly; j < ury; j++) {
					for (int i = llx; i < urx; i++) {
						if (OnMap(i,j)) {
							gp_short.coverage_map[(i-llx)+sizex*(j-lly)] = cv_map[i+map_data.coverage_size_x*j];
							gp_short.cost_map[(i-llx)+sizex*(j-lly)] = full.cost_map[i+map_data.cost_size_x*j];
							gp_short.elev_map[(i-llx)+sizex*(j-lly)] = full.elev_map[i+map_data.elev_size_x*j];
						}
					}
				}

				// set timestamp				
				gp_short.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);

				//print and publish message
				IPC_printData(IPC_msgFormatter (GP_SHORT_UPDATE_MSG), stdout, &gp_short);
				IPC_publishData(GP_SHORT_UPDATE_MSG, &gp_short);

				// delete temporary maps
				delete [] cv_map;
				delete [] cs_map;
				delete [] el_map;
				
				break;
			}
		case '6':
			{ // generate new map 
				int sizex, sizey, obs_num, obs_size, point_num;
				cout << endl << "x dimension in cells?" << endl;
				cin >> sizex;
				cout << endl << "y dimension in cells?" << endl;
				cin >> sizey;
				cout << endl << "number of obstacles?" << endl;
				cin >> obs_num;
				cout << endl << "obstacle size in cells?" << endl;
				cin >> obs_size;
				cout << endl << "number of point obstacles?" << endl;
				cin >> point_num;

				//generates the three maps with random elevations and obstacles as specified
				generate_map(sizex, sizey, obs_num, obs_size, point_num); 

				break;
			}
		case '7':
			{
				// this block is used for automated testing... and changes frequently
				char fn[] = "Map_out.txt";

				for (int count =0; count <150; count++) {
					cout << " starting loop # " << count << endl;
					char fn[] = "Map_out.txt";

					//variables to hold lower left and upper right map corners (smallest x, smallest y) - (largest x, largest y)
					int llx, lly, urx=-1, ury=-1;

					//allocate temp space to hold maps from disk
					unsigned char * cv_map = new unsigned char[1], *cs_map = new unsigned char[1];
					int16_t * el_map = new int16_t[1];

					getfiles(&cv_map, &(cs_map), &(el_map), fn, mapm, mapn);

					map_data.cost_size_x = map_data.coverage_size_x = map_data.elev_size_x = full.sent_cost_x = full.sent_elev_x = full.sent_cover_x = mapm;
					map_data.cost_size_y = map_data.coverage_size_y = map_data.elev_size_y = full.sent_cost_y = full.sent_elev_y = full.sent_cover_y = mapn;

					// set the map +/- 8 m from current location  -   rudimentary check on bounds
					llx = (posit.x -30)/map_data.cost_cell_size;
					if (llx < 0) llx = 0;
					lly = (posit.y -30)/map_data.cost_cell_size;
					if (lly  < 0) lly =0;
					urx = (posit.x +30)/map_data.cost_cell_size;
					if (urx >= map_data.cost_size_x) urx = map_data.cost_size_x;
					ury = (posit.y +30)/map_data.cost_cell_size;
					if (ury >= map_data.cost_size_y) ury = map_data.cost_size_y;


					//// section to use for manual entry
					//cout << "select lower left corner x: ";
					//cin >> llx;
					//cout << " y: ";
					//cin >> lly;
					//cout << endl << "select upper right corner x: ";
					//while (urx < llx) {cin >> urx; }
					//cout << " y: ";
					//while (ury < lly) {cin >> ury; }
					//cout << endl;

					int sizex = urx - llx;
					int sizey = ury - lly;

					// delete old maps
					delete [] gp_short.coverage_map;
					delete [] gp_short.cost_map;
					delete [] gp_short.elev_map;

					// set variables
					gp_short.sent_cover_x=gp_short.sent_cost_x=gp_short.sent_elev_x = sizex;
					gp_short.sent_cover_y=gp_short.sent_cost_y=gp_short.sent_elev_y = sizey;

					gp_short.x_cover_start = gp_short.x_cost_start = gp_short.x_elev_start = llx;
					gp_short.y_cover_start = gp_short.y_cost_start = gp_short.y_elev_start = lly;

					// allocate new maps
					gp_short.coverage_map = new unsigned char[sizex*sizey];
					gp_short.cost_map = new unsigned char[sizex*sizey];
					gp_short.elev_map = new int16_t[sizex*sizey];

					// copy elements from full map into short (multiple memcpy getting the whole row at once would be quicker)
					for (int j = lly; j < ury; j++) {
						for (int i = llx; i < urx; i++) {
							if (OnMap(i,j)) {
								gp_short.coverage_map[(i-llx)+sizex*(j-lly)] = cv_map[i+map_data.coverage_size_x*j];
								gp_short.cost_map[(i-llx)+sizex*(j-lly)] = full.cost_map[i+map_data.cost_size_x*j];
								gp_short.elev_map[(i-llx)+sizex*(j-lly)] = full.elev_map[i+map_data.elev_size_x*j];
							}
						}
					}

					// set timestamp				
					gp_short.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);

					//print and publish message
					IPC_printData(IPC_msgFormatter (GP_SHORT_UPDATE_MSG), stdout, &gp_short);
					IPC_publishData(GP_SHORT_UPDATE_MSG, &gp_short);

					// delete temporary maps
					delete [] cv_map;
					delete [] cs_map;
					delete [] el_map;
					/*
					   getfiles(&(full.coverage_map), &(full.cost_map), &(full.elev_map), fn, mapm, mapn);

					   map_data.cost_size_x = map_data.coverage_size_x = map_data.elev_size_x = full.sent_cost_x = full.sent_elev_x = full.sent_cover_x = mapm;
					   map_data.cost_size_y = map_data.coverage_size_y = map_data.elev_size_y = full.sent_cost_y = full.sent_elev_y = full.sent_cover_y = mapn;

					//set time to current clock tick
					full.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);//time(NULL);
					IPC_printData(IPC_msgFormatter (GP_FULL_UPDATE_MSG), stdout, &full);

					IPC_publishData(GP_FULL_UPDATE_MSG, &full);
					*/

					//set time to current clock tick
					posit.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);//time(NULL);

					float temp_posit_x = (float)(traj.traj_array[traj.num_traj_pts*traj.traj_dim-6]*map_data.cost_cell_size);
					float temp_posit_y = (float)(traj.traj_array[traj.num_traj_pts*traj.traj_dim-5]*map_data.cost_cell_size);

					if ((temp_posit_x!=0) && (temp_posit_y!=0)) {
						posit.x = temp_posit_x;
						posit.y = temp_posit_y;
						cout << "valid posit sent" << endl;
					}
					printf("posit %f %f \n", posit.x, posit.y);


					IPC_printData(IPC_msgFormatter (GP_POSITION_UPDATE_MSG), stdout, &posit);


					IPC_publishData(GP_POSITION_UPDATE_MSG, &posit);
					cout << "pause for 5 "; fflush(stdout);
					sleep(5);
					cout << "and listen for 5 " << endl;fflush(stdout);
					IPC_listen(20000);
					cout << "and repeat" << endl;fflush(stdout);

				}

				break;
			}

		case '8': {
					  // send a goal assignment
				if (traj.num_traj_pts>2) {
					int idx = traj.num_traj_pts-1;
				goal_assign.x = (double)traj.traj_array[idx*6]*map_data.cost_cell_size;
				goal_assign.y = (double)traj.traj_array[idx*6+1]*map_data.cost_cell_size;
				} 

				//posit.x = -1;
				//posit.y = -1;
				
				goal_assign.theta = 0;

				printf("starting point is %4.0f, %4.0f\n", goal_assign.x, goal_assign.y);
				cout << endl << "X position in meters?" << endl;
				while ((goal_assign.x<0)||(goal_assign.x>=(map_data.cost_size_x*map_data.cost_cell_size))) { cin >> goal_assign.x;}

				cout << endl << "Y position in meters?" << endl;
				while ((goal_assign.y<0)||(goal_assign.y>=(map_data.cost_size_y*map_data.cost_cell_size))) { cin >> goal_assign.y;}

				cout << endl << "theta (0-2*PI)?" << endl;
				while ((goal_assign.theta<0)||(goal_assign.theta>2*M_PI)) { cin >> goal_assign.theta;}

				goal_assign.goal_x = goal_assign.goal_y = goal_assign.goal_theta = -1;
				
				cout << endl << "New goal X position in meters?" << endl;
				while ((goal_assign.goal_x<0)||(goal_assign.goal_x>=(map_data.cost_size_x*map_data.cost_cell_size))) { cin >> goal_assign.goal_x;}

				cout << endl << "New goal Y position in meters?" << endl;
				while ((goal_assign.goal_y<0)||(goal_assign.goal_y>=(map_data.cost_size_y*map_data.cost_cell_size))) { cin >> goal_assign.goal_y;}

	cout << endl << "theta (0-2*PI)?" << endl;
				while ((goal_assign.goal_theta<0)||(goal_assign.goal_theta>2*M_PI)) { cin >> goal_assign.goal_theta;}

				// used for sending a preliminary full update with each position update.  not needed
				//tempx = posit.x/map_data.cost_cell_size;
				//tempy = posit.y/map_data.cost_cell_size;
				//IPC_publishData(GP_FULL_UPDATE_MSG, &full);

				//set time to current clock tick
				goal_assign.timestamp = (double)(clock())/double(CLOCKS_PER_SEC);//time(NULL);

				//print and publish message
				IPC_printData(IPC_msgFormatter (GP_GOAL_ASSIGN_MSG), stdout, &goal_assign);
				IPC_publishData(GP_GOAL_ASSIGN_MSG, &goal_assign);

				break;
			}
		case 'f': case 'F':
			{
				//writes data to file
				vector<Traj_pt_s> traj;
				writefiles(full.coverage_map, full.cost_map, full.elev_map, full.sent_cost_x, full.sent_cost_y);
				break;
			}


		case 'm': case 'M':
			{ 
				//display all of the current messages
				IPC_printData(IPC_msgFormatter (GP_MAP_DATA_MSG), stdout, &map_data);
				IPC_printData(IPC_msgFormatter (GP_ROBOT_PARAMETER_MSG), stdout, &robot);
				IPC_printData(IPC_msgFormatter (GP_POSITION_UPDATE_MSG), stdout, &posit);
				IPC_printData(IPC_msgFormatter (GP_FULL_UPDATE_MSG), stdout, &full);

				break;
			}

		default: {
					 printf("stdinHnd [%s]: Received %s", (char *)clientData, inputLine);
					 fflush(stdout);
				 }
	}
	printf("\n'1' to initialize the maps \n'2' to specify robot parameters\n");
	printf("'3' to update position only\n'4' to send full map update\n'5' to send partial map update\n");
	printf("'6' to generate random map\n'7' to send return last cover map\n'8' to send goal assignment\n'q' to quit\n");
}



int main() {
	//initialize the map variables
	full.sent_cost_x = full.sent_elev_x = full.sent_cover_x = mapm;
	full.sent_cost_y = full.sent_elev_y = full.sent_cover_y = mapn;

	// ...and allocate space for the maps themselves
	full.coverage_map = new unsigned char[mapn*mapm];
	full.cost_map = new unsigned char[mapn*mapm];
	full.elev_map = new int16_t[mapn*mapm];
	gp_short.coverage_map = new unsigned char[1];
	gp_short.cost_map = new unsigned char[1];
	gp_short.elev_map = new int16_t[1];

	// ...and the trajectory
	traj.traj_array = new float[31];
	traj.num_traj_pts = 6;
	traj.traj_array[30] = 600;
	traj.traj_array[31] = 600;

	// set an inital position 
	// MIGHT CONFLICT WITH SETTING ON LINE 270/271
	posit.x = 600;
	posit.y = 600;

	// init random seed
	srand((int)(time(NULL)));

	/* Connect to the central server */
	printf("\nIPC_connect(%s)\n", MODULE_NAME);
	IPC_connect(MODULE_NAME);

	/* Define the messages that this module publishes */
	//msg for robot parameters
	printf("\nIPC_defineMsg(%s, IPC_VARIABLE_LENGTH, %s)\n", GP_ROBOT_PARAMETER_MSG, GP_ROBOT_PARAMETER_FORM);
	IPC_defineMsg(GP_ROBOT_PARAMETER_MSG, IPC_VARIABLE_LENGTH, GP_ROBOT_PARAMETER_FORM);

	//msg for map initialization
	printf("\nIPC_defineMsg(%s, IPC_VARIABLE_LENGTH, %s)\n", GP_MAP_DATA_MSG, GP_MAP_DATA_FORM);
	IPC_defineMsg(GP_MAP_DATA_MSG, IPC_VARIABLE_LENGTH, GP_MAP_DATA_FORM);

	//msg for position update
	printf("\nIPC_defineMsg(%s, IPC_VARIABLE_LENGTH, %s)\n", GP_POSITION_UPDATE_MSG, GP_POSITION_UPDATE_FORM);
	IPC_defineMsg(GP_POSITION_UPDATE_MSG, IPC_VARIABLE_LENGTH, GP_POSITION_UPDATE_FORM);

	//msg for goal assignment
	printf("\nIPC_defineMsg(%s, IPC_VARIABLE_LENGTH, %s)\n", GP_GOAL_ASSIGN_MSG, GP_GOAL_ASSIGN_FORM);
	IPC_defineMsg(GP_GOAL_ASSIGN_MSG, IPC_VARIABLE_LENGTH, GP_GOAL_ASSIGN_FORM);

	//msg for full update
	printf("\nIPC_defineMsg(%s, IPC_VARIABLE_LENGTH, %s)\n", GP_FULL_UPDATE_MSG, GP_FULL_UPDATE_FORM);
	IPC_defineMsg(GP_FULL_UPDATE_MSG, IPC_VARIABLE_LENGTH, GP_FULL_UPDATE_FORM);

	// msg for partial update
	printf("\nIPC_defineMsg(%s, IPC_VARIABLE_LENGTH, %s)\n", GP_SHORT_UPDATE_MSG, GP_SHORT_UPDATE_FORM);
	IPC_defineMsg(GP_SHORT_UPDATE_MSG, IPC_VARIABLE_LENGTH, GP_SHORT_UPDATE_FORM);


	//Subscribe to the messages that this module listens to.
	printf("\nIPC_subscribe(%s, msg2Handler, %s)\n", GP_TRAJECTORY_MSG, MODULE_NAME);
	IPC_subscribe(GP_TRAJECTORY_MSG, GPTRAJHandler, (void *)MODULE_NAME);

	// Subscribe a handler for tty input.
	printf("\nIPC_subscribeFD(%d, stdinHnd, %s)\n", fileno(stdin), MODULE_NAME);
	IPC_subscribeFD(fileno(stdin), stdinHnd, (void *)MODULE_NAME);

	//parse format strings
	IPC_parseFormat(GP_MAP_DATA_FORM);
	IPC_parseFormat(GP_ROBOT_PARAMETER_FORM);
	IPC_parseFormat(GP_POSITION_UPDATE_FORM);
IPC_parseFormat(GP_GOAL_ASSIGN_FORM);
IPC_parseFormat(GP_FULL_UPDATE_FORM);
	IPC_parseFormat(GP_SHORT_UPDATE_FORM);

	printf("\n'1' to initialize the maps \n'2' to specify robot parameters\n");
	printf("'3' to update position only\n'4' to send full map update\n'5' to send partial map update\n");
	printf("'6' to generate new map\n'q' to quit\n");

	// call IPC and wait for messages
	IPC_dispatch();

	// clean up when done DOES NOT FREE ARRAYS IN USE
	IPC_disconnect();
	return 0;
}

