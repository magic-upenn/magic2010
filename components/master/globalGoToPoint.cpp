#define _USE_MATH_DEFINES
#include <vector>
#include <mex.h>
// #include <matrix.h>

using namespace std;

#include "../../common/dataTypes/MagicPlanDataTypes.h"
#include "../../ipc/ipc.h"
#include "../sbpl/src/sbpl/headers.h"


#define MODULE_NAME "GCS GoTo Point"


struct Traj_pt_s {
    int x; // position in cells
    int y;
    
    Traj_pt_s() {
        x = 0;
        y = 0;
    }
    
    Traj_pt_s(int a, int b) {
        x = a;
        y = b;
    }
};



void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])  {
    double *path;
    double *map_d, *pose, *target, *UTM, inflation_size, cell_size;
    int size_x, size_y;
    
    /*  check for proper number of arguments */
    if(nrhs!=6)
        mexErrMsgTxt("map, pose, target, UTM, inflation_size, cell_size expected");
    if(nlhs!=1)
        mexErrMsgTxt(" path array expected");
    
    /* create pointer for the matrix input M */
    map_d = (double *) mxGetPr(prhs[0]);
    size_x = mxGetM(prhs[0]);
    size_y =  mxGetN(prhs[0]);
    
    /*  create pointer and get the dimensions of the matrix input map */
    pose = (double *) mxGetPr(prhs[1]);
    
    // create pointer for region map
    target = (double *) mxGetPr(prhs[2]);
    
    // create pointer for region map
    UTM = (double *) mxGetPr(prhs[3]);
    
    // get map values
    inflation_size = (double) mxGetScalar(prhs[4]);
    cell_size = (double) mxGetScalar(prhs[5]);
    
    mexPrintf("pose is %.1f %.1f target is %.1f %.1f UTM is %.1f %.1f inflation size %.2f cell size %.2f\n", pose[0], pose[1], target[0], target[1], UTM[0], UTM[1], inflation_size, cell_size);
    
    // constants
    const unsigned char ABS_OBS = 255;
    const unsigned char OBS = 250;
    const unsigned char UNK = 125;
    const unsigned char FREE = 0;
    
    const double ABS_TH = 500;
    const double OBS_TH = 90;
    const double UNK_TH = -1;
    
    const double SOFT_PAD_DIST = 1.0;
    
    const int DIJKSTRA_LIMIT = 100000000;
    const double stepcost[3][3] = {{1.414213562, 1, 1.414213562}, {1, 0, 1}, {1.414213562, 1, 1.414213562}};
    
    // set up map sizes, initial pose and target locations
    int pose_x = (int)((pose[0] - UTM[0])/cell_size);
    int pose_y = (int)((pose[1] - UTM[1])/cell_size);
    
    int target_x = (int)((target[0] - UTM[0])/cell_size);
    int target_y = (int)((target[1] - UTM[1])/cell_size);
    
    int pad_dist = (int)(SOFT_PAD_DIST/cell_size);
    int buffer = (pad_dist - (int)inflation_size);
    
    unsigned char *map = new unsigned char[size_x*size_y];
    unsigned char *inf_map = new unsigned char[size_x*size_y];
    unsigned char* *map_pa = new unsigned char*[size_y];
    unsigned char* *inf_map_pa = new unsigned char*[size_y];
    
    float *obs_array = new float[size_x * size_y];
    float **obs_ptr_array = new float*[size_y];
    float *nonfree_array = new float[size_x * size_y];
    float **nonfree_ptr_array = new float*[size_y];
    
    int *dijkstra = new int[size_x*size_y];
    
    for (int j = 0; j < size_y; j++) {
        map_pa[j] = &map[j * size_x];
        inf_map_pa[j] = &inf_map[j * size_x];
        obs_ptr_array[j] = &obs_array[j * size_x];
        nonfree_ptr_array[j] = &nonfree_array[j * size_x];
    }
    
    for (int j = 0; j < size_y; j++) {
        for (int i = 0; i < size_x; i++) {
            if(map_d[i+size_x*j] >= ABS_TH) {
                map[i+size_x*j] = ABS_OBS;
            }
            if(map_d[i+size_x*j] >= OBS_TH)  {
                map[i+size_x*j] = OBS;
            }
            else if(map_d[i+size_x*j] >= UNK_TH)  {
                map[i+size_x*j] = UNK;
            }
            else {
                map[i+size_x*j] = FREE;
            }
        }
    }
    
    
    // ensure map boundaries are solid
    for (int i = 0; i < size_x; i++) {
        inf_map[i] = map[i] = ABS_OBS;
        inf_map[i + size_x * (size_y -1)] = map[i + size_x * (size_y -1)] = ABS_OBS;
    }
    
    for (int j = 0; j < size_y; j++) {
        inf_map[j * size_x] = map[j * size_x] = ABS_OBS;
        inf_map[(size_x - 1) + j * size_x] = map[(size_x - 1) + j * size_x] = ABS_OBS;
    }
    
    computeDistancestoNonfreeAreas(map_pa, size_y, size_x, OBS, obs_ptr_array, nonfree_ptr_array);
    
    //update inflated map based on robot size and make unknown areas obstacles w/o inflation
    for (int j = 0; j < size_y; j++) {
        for (int i = 0; i < size_x; i++) {
            if (obs_ptr_array[j][i] <= inflation_size) {
                inf_map[i + size_x * j] = OBS;
            }
            else {
                inf_map[i + size_x * j] = (unsigned char) max((double) (map[i + size_x * j]) , (double)((pad_dist - obs_ptr_array[j][i])*200/buffer));
            }
        }
    }
    
    SBPL2DGridSearch search(size_y, size_x, cell_size);
    search.setOPENdatastructure(SBPL_2DGRIDSEARCH_OPENTYPE_HEAP);
    
    // dijkstra map to get cost to target point
    search.search(inf_map_pa, ABS_OBS, pose_y, pose_x, target_y, target_x, SBPL_2DGRIDSEARCH_TERM_CONDITION_OPTPATHFOUND);
    
//     for (int i=0; i<size_x; i++) {
//         for (int j=0; j<size_y; j++) {
//             printf("%d ", (int)(search.getlowerboundoncostfromstart_inmm(j, i)) );
//         }
//         printf("\n");
//     }
    
    
    
    
    for (int j = 0; j < size_y; j++) {
        for (int i = 0; i < size_x; i++) {
            dijkstra[i + size_x * j] = (int) (search.getlowerboundoncostfromstart_inmm(j, i));
        }
    }
    
    // generate the path
    Traj_pt_s current;
    vector<Traj_pt_s> inv_traj;
    vector<Traj_pt_s> traj;
    
    int x_val, y_val, best_x_val, best_y_val;
    x_val = current.x = target_x;
    y_val = current.y = target_y;
    
    inv_traj.clear();
    inv_traj.push_back(current);
    int min_val;
    while ((x_val != pose_x) || (y_val != pose_y)) {
        min_val = DIJKSTRA_LIMIT ;
        for (int x = -1; x < 2; x++) {
            for (int y = -1; y < 2; y++) {
                if ((x+x_val < size_x) && (x+x_val > 0) && (y+y_val < size_y) && (y+y_val > 0))  {
                    int val = dijkstra[(x + x_val) + (size_x * (y+ y_val))];
                  //  printf("%d @ (%d, %d)", val, x+x_val, y+y_val);
                    if (val < min_val) {
                       // printf("*");
                        min_val = val;
                        best_y_val = y_val + y;
                        best_x_val = x_val + x;
                     //   temp_cost = (stepcost[x + 1][y + 1])*(double)(inf_map[best_x_val + size_x*best_y_val]+1);
                    } // if val
                  //  printf("\n");
                } // if onmap
            } // y
        } //x
        
        //cost += temp_cost;
        current.x = x_val = best_x_val;
        current.y = y_val = best_y_val;
        inv_traj.push_back(current);
    }
    
   // printf("done with inversion\n");
    // invert the trajectory to send back
    traj.clear();
    while (inv_traj.size() != 0) {
        current.x = inv_traj.back().x;
        current.y = inv_traj.back().y;
        traj.push_back(current);
        inv_traj.pop_back();
    }
    
    // handle return stuff
    int NUMPTS = traj.size();
 //   printf(" num points returned %d \n", NUMPTS);
    
    /*  set the output pointer to the output matrix */
    //int dims[2] = {NUMPTS, 1};
    plhs[0] = mxCreateDoubleMatrix(2, NUMPTS, mxREAL);
    path = (double *) mxGetPr(plhs[0]);
    
    for(int idx = 0; idx < NUMPTS; idx++) {
        path[idx*2] = traj[idx].x*cell_size + UTM[0];
        path[idx*2 +1]= traj[idx].y*cell_size + UTM[1];
    }
    
    delete [] map;
    delete [] inf_map;
    delete [] map_pa;
    delete [] inf_map_pa;
    
    delete [] obs_array;
    delete [] obs_ptr_array;
    delete [] nonfree_array;
    delete [] nonfree_ptr_array;
    
    delete [] dijkstra;
    
}
