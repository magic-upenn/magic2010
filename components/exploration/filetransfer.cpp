#include "common_headers.h"
#include "filetransfer.h"

using namespace std;

void getfiles(unsigned char **cover_map, unsigned char **cost_map, int16_t **elev_map, const char * filename, int &mapm, int &mapn) {
	// gets the dimensions, map from disk 
	ifstream fin;
	fin.open(filename, ios_base::in | ios_base::binary);

	if (fin.is_open()) {
		fin.read( (char *) &mapm, sizeof(int));
		fin.read( (char *) &mapn, sizeof(int));
		cout << "m: " << mapm  << "  n: " << mapn << endl;

		// free up old space
		delete [] *cover_map;
		delete [] *cost_map;
		delete [] *elev_map;

		*cover_map = new unsigned char[mapn*mapm];
		*cost_map = new unsigned char[mapn*mapm];
		*elev_map = new int16_t[mapn*mapm];

		fin.read( (char *) *cover_map, (mapm*mapn)*sizeof(char));
		fin.read( (char *) *cost_map, (mapm*mapn)*sizeof(char));
		fin.read( (char *) *elev_map, (mapm*mapn)*sizeof(int16_t));

		fin.close();
	}
	else 
	{ cerr << " unable to read input file"; }
}

void writefiles(const unsigned char cover_map[], const unsigned char cost_map[], const int16_t elev_map[], const char * filename, const int mapx, const int mapy) {
	// writes the main map variables to disk

	ofstream fout;

	fout.open(filename, ios_base::out | ios_base::binary | ios_base::trunc);
	if (fout.is_open()) {

		fout.write( (char *) &mapx, sizeof(int));
		fout.write( (char *) &mapy, sizeof(int));

		fout.write( (char *) cover_map, mapx*mapy*sizeof(char));
		fout.write( (char *) cost_map, mapx*mapy*sizeof(char));
		fout.write( (char *) elev_map, mapx*mapy*sizeof(int16_t));


		fout.close();
	}
	else 
	{ cerr << " unable to write output file"; }
}

void writefileextra(const int map[], const char * filename, int x, int y) {
	// writes the cost to accessable points map to disk
	ofstream fout;
	
	fout.open(filename, ios_base::out | ios_base::binary | ios_base::trunc);

	if (fout.is_open()) {

		fout.write( (char *) &x, sizeof(int));
		fout.write( (char *) &y, sizeof(int));

		fout.write( (char *) map, x*y*sizeof(int));

		fout.close();
	}
	else 
	{ cerr << " unable to write output file"; }
}


void writefiletraj( const double score, const std::vector<Traj_pt_s> & traj,  const char * filename) {
	// writes the trajectory to disk
	ofstream fout;
	
	int t_leng = traj.size();

	fout.open(filename, ios_base::out | ios_base::binary | ios_base::trunc);

	if (fout.is_open()) {

		fout.write( (char *) &score, sizeof(double));
		fout.write( (char *) &t_leng, sizeof(int));
		fout.write( (char *) &traj[0], t_leng*sizeof(Traj_pt_s));
		fout.close();
	}
	else 
	{ cerr << " unable to write output file"; }
}
