#include <iostream>
#include <fstream>
#include <string>
#include "stdio.h"
#include "mex.h"
using namespace std;

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])  {
    unsigned char *cost_map, *cover_map;
    double *x, *y;
    float xx, yy;
    int mm, nn;
    int16_t *elev_map;
    
    ofstream fout;
    
  /*  check for proper number of arguments */
    if(nrhs!=3)
        mexErrMsgTxt("unsigned char cover_map, unsigned char cost_map, int16t elev_map expected");
    if(nlhs!=0)
        mexErrMsgTxt("none expected");
    
//    x = mxGetPr(prhs[0]);
//    y = mxGetPr(prhs[1]);
//    
//    xx = (float) *x;
//    yy = (float) *y;
    
    /*  create a pointer to the input matrix path and get dimensions */
    cover_map = (unsigned char*) mxGetPr(prhs[0]);
    double mrows = mxGetM(prhs[0]);
    double ncols = mxGetN(prhs[0]);
    
    mm = (int) mrows;
    nn = (int) ncols;
    
    cost_map = (unsigned char*) mxGetPr(prhs[1]);
    elev_map = (int16_t*) mxGetPr(prhs[2]);
    
    fout.open("Map.txt", ios_base::out | ios_base::binary | ios_base::trunc )  ;

    mexPrintf("%f %f\n", xx, yy);
    
//    fout.write( (char *) &xx, 4);// sizeof(xx));
//    fout.write( (char *) &yy, 4);//sizeof(yy));
    
    mexPrintf("%i %i\n", mm, nn);
    
    fout.write( (char *) &mm, 4);//sizeof(mm));
    fout.write( (char *) &nn, 4);//sizeof(nn));
    
    fout.write( (char *) cover_map, (mrows*ncols*sizeof(char)));
    fout.write( (char *) cost_map, (mrows*ncols*sizeof(char)) );
    fout.write( (char *) elev_map, (mrows*ncols*sizeof(int16_t)) );
        
    fout.clear();
    fout.close();
}