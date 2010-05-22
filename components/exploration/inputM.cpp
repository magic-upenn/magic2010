#include <iostream>
#include <fstream>
#include <string>
#include "stdio.h"
#include "mex.h"
#include <stdint.h>
using namespace std;

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])  {
    
    int  mrows, ncols;
    unsigned char *cost_map, *cover_map;
    char *filename;
    int16_t *elev_map;
    ifstream fin;
    
    /*  check for proper number of arguments */
    if(nrhs!=1)
        mexErrMsgTxt("none expected");
    if(nlhs!=3)
        mexErrMsgTxt("score, cover, elev");
    
    /*  create a pointer to the input matrix path and get dimensions */
    filename = mxArrayToString(prhs[0]);
    fin.open(filename, ios_base::in | ios_base::binary)  ;
    fin.read( (char *) &mrows, 4);//sizeof(int));
    fin.read( (char *) &ncols, 4);//sizeof(int));
    mexPrintf("map - M: %i %i\n", mrows, ncols);
    while((mrows*ncols)>(5000*5000)) {
        // as long as dimensions are too big, keep trying to load
        
        mexPrintf("dim too large\n");
        fin.close();
        fin.open(filename, ios_base::in | ios_base::binary)  ;
        fin.read( (char *) &mrows, 4);//sizeof(int));
        fin.read( (char *) &ncols, 4);//sizeof(int));
        mexPrintf("map - M: %i %i\n", mrows, ncols);
    }

    
    
  
    const mwSize ndim=2, dim[2] = {mrows, ncols};//{1000,1000};//
    plhs[0] = mxCreateNumericArray(ndim, dim, mxUINT8_CLASS, mxREAL );
    cover_map =(unsigned char *) mxGetPr(plhs[0]);
    
    plhs[1] = mxCreateNumericArray(ndim, dim, mxUINT8_CLASS, mxREAL );
    cost_map =(unsigned char *) mxGetPr(plhs[1]);
    
    plhs[2] = mxCreateNumericArray(ndim, dim, mxINT16_CLASS, mxREAL );
    elev_map =(int16_t *) mxGetPr(plhs[2]);
    
    fin.read( (char *) cover_map, mrows*ncols*sizeof(char));
    fin.read( (char *) cost_map, mrows*ncols*sizeof(char));
    fin.read( (char *) elev_map, mrows*ncols*sizeof(int16_t));
    fin.close();
    mexPrintf("load done\n");
}