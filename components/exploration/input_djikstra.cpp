#include <iostream>
#include <fstream>
#include <string>
#include "stdio.h"
#include "mex.h"
using namespace std;

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])  {
    
    int  mrows, ncols;
    int *djikstra;
    char *filename;
    ifstream fin;
    
    /*  check for proper number of arguments */
    if(nrhs!=1)
        mexErrMsgTxt("filename expected");
    if(nlhs!=1)
        mexErrMsgTxt("djikstra");
    
    filename = mxArrayToString(prhs[0]);
        
    fin.open(filename, ios_base::in | ios_base::binary)  ;
    fin.read( (char *) &mrows, 4);//sizeof(int));
    fin.read( (char *) &ncols, 4);//sizeof(int));
    
    mexPrintf("dji - M: %i %i\n", mrows, ncols);
      while((mrows*ncols)>(5000*5000)) {
        // as long as dimensions are too big, keep trying to load
        
        mexPrintf("dim too large\n");
        fin.close();
        fin.open(filename, ios_base::in | ios_base::binary)  ;
        fin.read( (char *) &mrows, 4);//sizeof(int));
        fin.read( (char *) &ncols, 4);//sizeof(int));
        mexPrintf("dji - M: %i %i\n", mrows, ncols);
    }
    
    
    
    const mwSize ndim=2, dim[2] = {mrows, ncols};//{1000,1000};//
    plhs[0] = mxCreateNumericArray(ndim, dim, mxINT32_CLASS, mxREAL );
    djikstra =(int *) mxGetPr(plhs[0]);
    
    fin.read( (char *) djikstra, mrows*ncols*sizeof(int));
    fin.close();
    mexPrintf("load done\n");
}