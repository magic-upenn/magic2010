/*
  im_accum(im, x_im, y_im, vp);

  MEX file to compute accumulate points(vp(1,:),vp(2,:),vp(3,:))
  in array im with limits x_im, y_im.

  Note: This routine accumulates repeated indices and changes
  the matrix x directly in memory.

  Daniel D. Lee, 11/2010
  <ddlee@seas.upenn.edu>
*/

#include "mex.h"
#include <math.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Check arguments */
  if (nrhs < 4)
    mexErrMsgTxt("Need four input arguments.");

  if (!mxIsDouble(prhs[0])) {
    mexErrMsgTxt("Image needs to be double array");
  }
  double *im = mxGetPr(prhs[0]);
  int nx = mxGetM(prhs[0]);
  int ny = mxGetN(prhs[0]);

  double *x_im = mxGetPr(prhs[1]);
  double xmin = x_im[0];
  double xmax = x_im[mxGetNumberOfElements(prhs[1])-1];
  double xresolution = (xmax-xmin)/(nx-1);
  //printf("x: %.3f %.3f %.3f\n", xmin, xmax, xresolution);

  double *y_im = mxGetPr(prhs[2]);
  double ymin = y_im[0];
  double ymax = y_im[mxGetNumberOfElements(prhs[2])-1];
  double yresolution = (ymax-ymin)/(ny-1);
  //printf("y: %.3f %.3f %.3f\n", ymin, ymax, yresolution);

  double *vp = mxGetPr(prhs[3]);
  if (mxGetM(prhs[3]) != 3) {
    mexErrMsgTxt("Point array needs to contain 3 rows");
  }
  int np = mxGetN(prhs[3]);

  for (int k = 0; k < np; k++) {
    int ix = (int) round((vp[3*k]-xmin)/xresolution);
    int iy = (int) round((vp[3*k+1]-ymin)/yresolution);
    //    printf("ix,iy = %d,%d\n",ix,iy);

    if ((ix >= 0) && (ix < nx) && (iy >= 0) && (iy < ny)) {
      int index = ix + nx*iy;
      im[index] += vp[3*k+2];
    }
  }
  
  plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
}
