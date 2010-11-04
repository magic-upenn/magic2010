/*
  stats = scan_correlation(p1, p2);
  
  Returns scan correlation statistics of points p1 with p2.

  mex -O scan_correlation.cpp
*/

#include <math.h>
#include <float.h>
#include <string.h>
#include "mex.h"

const double resolution = 0.05;
const int na = 1500;

unsigned char a[na][na];

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs < 2) {
    mexErrMsgTxt("Need two input arguments");
  }

  int m1 = mxGetM(prhs[0]);
  int n1 = mxGetN(prhs[0]);
  double *p1 = mxGetPr(prhs[0]);
  if (m1 < 2) {
    mexErrMsgTxt("p1 not in 2D point format");
  }


  int m2 = mxGetM(prhs[1]);
  int n2 = mxGetN(prhs[1]);
  double *p2 = mxGetPr(prhs[1]);
  if (m2 < 2) {
    mexErrMsgTxt("p2 not in 2D point format");
  }

  // Clear array
  memset(a, 0, na*na);

  // Compute mean of p1 points:
  double mx1 = 0;
  double my1 = 0;
  for (int k = 0; k < n1; k++) {
    double x1 = p1[m1*k];
    double y1 = p1[m1*k+1];
      
    mx1 += x1;
    my1 += y1;
  }
  if (n1 > 0) {
    mx1 /= n1;
    my1 /= n1;
  }

  // Accumulate p1 points in array
  int c1 = 0;
  for (int k = 0; k < n1; k++) {
    double x1 = p1[m1*k] - mx1;
    double y1 = p1[m1*k+1] - my1;

    int i1 = round(x1/resolution + na/2);
    if ((i1 < 0) || (i1 >= na)) continue;
    int j1 = round(y1/resolution + na/2);
    if ((j1 < 0) || (j1 >= na)) continue;
    
    if (!(a[i1][j1] & 0x01)) {
      c1++;
      a[i1][j1] |= 0x01;
    }
  }

  // Correlate p2 points in array
  int c2 = 0;
  int c3 = 0;
  for (int k = 0; k < n2; k++) {
    double x2 = p2[m2*k] - mx1;
    double y2 = p2[m2*k+1] - my1;

    int i2 = round(x2/resolution + na/2);
    if ((i2 < 0) || (i2 >= na)) continue;
    int j2 = round(y2/resolution + na/2);
    if ((j2 < 0) || (j2 >= na)) continue;
    
    if (!(a[i2][j2] & 0x02)) {
      c2++;
      a[i2][j2] |= 0x02;
      if (a[i2][j2] & 0x01) {
	c3++;
      }
    }
  }

  // Return counts
  plhs[0] = mxCreateDoubleMatrix(1,3,mxREAL);
  double *c = mxGetPr(plhs[0]);
  c[0] = c1;
  c[1] = c2;
  c[2] = c3;

}
