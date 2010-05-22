#ifndef _FILETRANSFER_JMB
#define _FILETRANSFER_JMB
void getfiles(unsigned char **cover_map, unsigned char **cost_map, int16_t **elev_map, const char * filename, int &mapm, int &mapn);
void writefiles(const unsigned char cover_map[], const unsigned char cost_map[], const int16_t elev_map[], const int mapx, const int mapy);
void writefileextra(const int map[], int x, int y);
void writefiletraj( const double score, const std::vector<Traj_pt_s> & traj);
#endif
