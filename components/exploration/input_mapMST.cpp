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
    mexPrintf("ST:  %f  %i\n",  score, traj_leng);
    while(abs(traj_leng)>10000) {
        // as long as dimensions are too big, keep trying to load
        mexPrintf("traj too large\n");
        fin.close();
        fin.open(filename, ios_base::in | ios_base::binary)  ;
        fin.read( (char *) score, sizeof(double));
        fin.read( (char *) &traj_leng, sizeof(int));
        mexPrintf("ST:  %f  %i\n",  score, traj_leng);
    }
    

     traj_leng *= 6;
    mwSize dimtraj[2] = {1, traj_leng};
    
    plhs[1] = mxCreateNumericArray(ndim, dimtraj, mxSINGLE_CLASS,  mxREAL );
    traj = (float *) mxGetPr(plhs[1]);
    
   
    
    for (int q=0; q<traj_leng/6;q++) {
        int intptr;
        fin.read( (char *) &intptr, sizeof(int));
        cout << intptr << " ";
        traj[q*6] = (float) intptr;
        fin.read( (char *) &intptr, sizeof(int));
        cout << intptr << endl;
        traj[q*6+1] = (float)intptr;
        fin.read( (char *) &traj[q*6+2], sizeof(float));
        fin.read( (char *) &traj[q*6+3], sizeof(float));
        fin.read( (char *) &traj[q*6+4], sizeof(float));
        fin.read( (char *) &traj[q*6+5], sizeof(float));
    }
    

    
    fin.close();
    mexPrintf("load done\n");
}