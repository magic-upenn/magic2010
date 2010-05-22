#include "common_headers.h"
#include <fstream>
#include <string>
#include "generate_map.h"
#include "astarpoint.h"

using namespace std;

const int16_t OBST16 = 30000; // minimum value of OBSTACLES on 

class MFCell {
	public:
		int x;
		int y;
	
		friend bool operator< (const MFCell & cell1, const MFCell & cell2);
		friend bool operator> (const MFCell & cell1, const MFCell & cell2);

		MFCell() { x=0; y=0; }

		MFCell(int a, int b) { x=a; y=b; }

};

bool operator< (const MFCell & cell1, const MFCell & cell2)
{ return cell1.x <= cell2.x; }

bool operator> (const MFCell & cell1, const MFCell & cell2)
{ return cell1.x > cell2.x; }

void mapfill(unsigned char cost_map[], int size_x, int size_y, int startx, int starty) {
	// fills all unaccessable areas as obstacles; used during map generation
	
double INFd = numeric_limits<double>::infinity();
vector<vector<bool> > MFClosed;
vector<vector<double> > MFG;

	// find an open start point
	MFClosed.resize(size_x);
	MFG.resize(size_x);
	for (int i = 0; i < size_x; ++i) {
		MFClosed[i].resize(size_y);
		MFG[i].resize(size_y);
	}


	for (int i = 0;i < size_x; i++) {
		for(int j = 0; j < size_y; j++) {
			MFClosed[i][j] = false;
			MFG[i][j] = INFd;
		}
	}


	// initialize cost per step
	//  3 2 1
	//  4   0
	//  5 6 7

	const int dX[8] = {1, 1, 0, -1, -1, -1,  0,  1};
	const int dY[8] = {0, 1, 1,  1,  0, -1, -1, -1};

	// setup open cell queue
	priority_queue<MFCell, deque<MFCell>,greater<MFCell> > OpenCells;

	MFCell current;

	MFG[startx][starty] = 0;

	// init current cell to start
	current.x = startx;
	current.y = starty;

	OpenCells.push(current);

	while (!OpenCells.empty()) { // while not empty 
		current = OpenCells.top(); // read top value
		OpenCells.pop(); // remove from queue
		MFClosed[current.x][current.y] = true; // add to closed
		//cost_map[current.x*size_y + current.y] = 70;
		for (int k = 0;k<8;k++) { // check neighbors
			int evalx = current.x + dX[k];
			int evaly = current.y + dY[k];
			if ((evalx >= 0) && (evalx < size_x)) {  // within x bounds
				if ((evaly >= 0) && (evaly < size_y)) { // within y bounds
					if (cost_map[evalx*size_y + evaly] != OBSTACLE) { // not an obstacle
						if (!MFClosed[evalx][evaly]) { // not already evaluated
							if (MFG[evalx][evaly] > MFG[current.x][current.y]) {  // if smaller g value
								MFG[evalx][evaly] = MFG[current.x][current.y]; // update g
								MFCell temp(evalx, evaly); // setup cell
								OpenCells.push(temp); // add to open list
//cout << " closed " << evalx << "," << evaly << endl;
							} // end smaller g
						} // end closed
					} // end obstacle
				} // end cost_size_y
			} // end x dim
		} // end check neighbors
	} // end while

	for (int j=0; j< size_y; j++) {
		for (int i=0;i< size_x; i++) {
			if (MFG[i][j] == INFd) { cost_map[i+size_x*j] = OBSTACLE; }
		}
	}
	return;
}


void generate_map(int sizex, int sizey, int obs_num, int obs_size, int point_num) {
	// written by Jonathan Michael Butzke 20 Jun 2009
	// this function takes the parameters for a map and generates a cost and
	// coverage map from that data
	cout << sizex << " " << sizey << " " << obs_num << " " << obs_size << " "  << endl;
	unsigned char * new_cover_map = new unsigned char[sizex*sizey];
	unsigned char * new_cost_map = new unsigned char[sizex*sizey];
	int16_t * new_elev_map = new int16_t[sizex*sizey];

	//initialize
	for(int n = 0; n < sizey; n++) {
		for(int m = 0; m < sizex; m++) {
			new_cost_map[m+sizex*n] =rand()%200;
			new_cover_map[m+sizex*n] = 0;
			new_elev_map[m+sizex*n] =  ((rand()%1000)/1000.0)*((rand()%1000)/1000.0)*((rand()%1000)/1000.0)*20.0;
			//if ((m<200) && (n< 300))  { new_cover_map[m*sizey+n] = 0; }
			//else { new_cover_map[m*sizey+n] = 240; }
		}
	}

	cout << "big obstacles ";cout.flush();
	for(int i = 0; i< obs_num; i++) {
		int x0 = (rand() % (sizex-obs_size-1));
		int y0 = (rand() % (sizey-obs_size-1));
		int x1 = (rand() % obs_size) + x0;
		int y1 = (rand() % obs_size) + y0;

		for (int n=y0; n < y1; n++ ) {
			for (int m=x0; m< x1; m++) {
				new_cost_map[m+sizex*n] = OBSTACLE;
				new_elev_map[m+sizex*n] =  ((rand()%1000)/1000.0)*((rand()%1000)/1000.0)*((rand()%1000)/1000.0)*2000.0;
				//				new_cover_map[m*sizey+n] = OBSTACLE;
			}
		} 
	}
	//
	//cout << "clear big hole ";cout.flush();
	//        for(int m = xx-(obs_size/4); m < xx + (obs_size/4); m++) {
	//                for(int n = yy-(obs_size/4); n < yy + (obs_size/4); n++) {
	//                        new_cost_map[m*sizey+n] = 0;
	////			new_cover_map[m*sizey+n] = UNKNOWN;
	//                }
	//        }

	cout << "points ";cout.flush();
	for(int i = 0; i < point_num; i++) {
		int x =  (rand()%(sizex-2))+1;
		int y = (rand()%(sizey-2))+1;
		new_cost_map[x+sizex*y] = OBSTACLE;
		new_elev_map[x+sizex*y] = ((rand()%1000)/1000.0)*((rand()%1000)/1000.0)*((rand()%1000)/1000.0)*2000.0;
		//		new_cover_map[x*sizey+y] = OBSTACLE;
		//for(int q =-1; q< 2; q++) {
		//        for(int w=-1;w<2;w++) {
		//                new_cost_map[(x+q)*sizey+y+w] = UNKNOWN;
		//                new_cover_map[(x+q)*sizey+y+w] = UNKNOWN;
		//        }
		//}
		//	new_cost_map[x*sizey+y] = OBSTACLE;
		//	new_cover_map[x*sizey+y] = OBSTACLE;
	}
	//        cout << "clear small hole ";cout.flush();
	//
	//        for(int m=-25; m < 26; m++) {
	//                for(int n=-25; n< 26; n++) {
	//                        new_cost_map[(m+xx)*sizey+n+yy] = 0;
	////			new_cover_map[(m+xx)*sizey+n+yy] = UNKNOWN;
	//                }
	//        }

	//puts solid edges on the maps
	cout << " V edges "; 
	for(int j=0; j< sizey; j++) {
		//		new_cover_map[i*sizey +0] = OBSTACLE;
		//		new_cover_map[i*sizey+sizey-1] = OBSTACLE;
		new_cost_map[j*sizex +0] = OBSTACLE;
		new_cost_map[j*sizex + sizex-1] = OBSTACLE;
		new_elev_map[j*sizex +0] = OBST16;
		new_elev_map[j*sizex + sizex-1] = OBST16;
	}

	cout << " H edges "; cout.flush();
	for(int i=0; i<sizex; i++) {
		//		new_cover_map[i] = OBSTACLE;
		//		new_cover_map[(sizex-1)*sizex+i] = OBSTACLE;
		new_cost_map[i] = OBSTACLE;
		new_cost_map[(sizey-1)*sizex+i] = OBSTACLE;
		new_elev_map[i] = OBST16;
		new_elev_map[(sizey-1)*sizex+i] = OBST16;
	}

	//for (int i=0; i< 5; i++) {
	//new_cost_map[i*sizey+4] = OBSTACLE;
	//new_cost_map[4*sizey+i] = OBSTACLE;
	//}
	//
	//start info not used
	int startx, starty;
	do {
		startx = rand() % sizex;
		starty = rand() % sizey;
	} while (new_cost_map[starty*sizex + startx] == OBSTACLE); // find point that is not an obstacle
	//startx = 401; starty = 1220;

	//mapfill(new_cost_map, sizex, sizey, startx, starty);
	ofstream fout;

	fout.open("Map.txt", ios_base::out | ios_base::binary | ios_base::trunc);
	cout << "put to file" << endl;cout.flush();
	if (fout.is_open()) {
		fout.write( (char *) &sizex, sizeof(int));
		fout.write( (char *) &sizey, sizeof(int));

		fout.write( (char *) new_cover_map, sizex*sizey*sizeof(char));
		fout.write( (char *) new_cost_map, sizex*sizey*sizeof(char));
		fout.write( (char *) new_elev_map, sizex*sizey*sizeof(int16_t));

		fout.close();
	}
	else 
	{ cerr << " unable to write initial map output file\n"; }

	//for(int q=0; q<sizey;q++) {
	//    for(int w=0;w<sizex;w++) {
	//        printf("%3u ",(unsigned int)new_cost_map[q*sizex+w]);
	//    }
	//    printf("\n");
	//}

	delete [] new_cover_map;
	delete [] new_cost_map;
	delete [] new_elev_map;
}

