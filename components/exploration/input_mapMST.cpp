#include <iostream>
#include <fstream>
#include <string>
#include "stdio.h"
#include "mex.h"
using namespace std;

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])  {
    
    int  mrows, ncols;
    float  *traj ;
    int  traj_leng;
    double *score;
    char *filename;
    ifstream fin;
    
    const int trajdim = 8;
    /*  check for proper number of arguments */
    if(nrhs!=1)
        mexErrMsgTxt("filename expected");
    if(nlhs!=2)
        mexErrMsgTxt("score, traj expected");
   
    const mwSize ndim=2, dim[2] = {1, 1};
    
    plhs[0] = mxCreateNumericArray(ndim, dim, mxDOUBLE_CLASS,  mxREAL );
    score = (double *) mxGetPr(plhs[0]);
    
    
    filename = mxArrayToString(prhs[0]);
    fin.open(filename, ios_base::in | ios_base::binary)  ;
    fin.read( (char *) score, sizeof(double));
    fin.read( (char *) &traj_leng, sizeof(int));
    
     traj_leng *= trajdim;
    mwSize dimtraj[2] = {1, traj_leng};
    
    plhs[1] = mxCreateNumericArray(ndim, dimtraj, mxSINGLE_CLASS,  mxREAL );
    traj = (float *) mxGetPr(plhs[1]);
    
   
    
    for (int q=0; q<traj_leng/trajdim;q++) {
        int intptr;
        fin.read( (char *) &intptr, sizeof(int));
     //   cout << intptr << endl;
        traj[q*trajdim] = (float) intptr;
        fin.read( (char *) &intptr, sizeof(int));
       // cout << intptr << endl;
        traj[q*trajdim+1] = (float)intptr;
        fin.read( (char *) &traj[q*trajdim+2], sizeof(float));
        fin.read( (char *) &traj[q*trajdim+3], sizeof(float));
        fin.read( (char *) &traj[q*trajdim+4], sizeof(float));
        fin.read( (char *) &traj[q*trajdim+5], sizeof(float));
        fin.read( (char *) &traj[q*trajdim+6], sizeof(float));
        fin.read( (char *) &traj[q*trajdim+7], sizeof(float));
    }
    
    mexPrintf("ST:  %f  %i\n",  score, traj_leng);
    
    fin.close();
    mexPrintf("load done\n");
}