/*
  [o, op1] = scan_icp(p1, p2, o, rmatch);

  Returns transformation parameters to match points p1 to p2 using ICP.

  mex -O scan_icp.cpp
*/

#include <math.h>
#include <vector>
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const int na = 100; // Size of correlation array side
  const int maxIter = 10; // Max number of iterations for ICP

  std::vector< std::vector<int> > a(na*na); // Correlation array

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

  double rmatch = 1.0; // Default match cell length
  if (nrhs >= 4) {
    rmatch = mxGetScalar(prhs[3]);
  }

  double o[3]; // Transformation parameters
  if (nrhs >= 3) {
    if (mxGetNumberOfElements(prhs[2]) != 3) {
      mexErrMsgTxt("Initial transformation not in correct format");
    }
    for (int i = 0; i < 3; i++) {
      o[i] = mxGetPr(prhs[2])[i];
    }
  }

  // Clear array
  for (int k = 0; k < na*na; k++) {
    a[k].clear();
  }

  // Compute mean of p2 points:
  double mx2 = 0;
  double my2 = 0;
  for (int k = 0; k < n2; k++) {
    double x2 = p2[m2*k];
    double y2 = p2[m2*k+1];
      
    mx2 += x2;
    my2 += y2;
  }
  if (n2 > 0) {
    mx2 /= n2;
    my2 /= n2;
  }

  // Accumulate p2 points in array
  for (int k = 0; k < n2; k++) {
    double x2 = p2[m2*k];
    double y2 = p2[m2*k+1];

    int i2 = round((x2-mx2)/rmatch + na/2);
    if ((i2 < 0) || (i2 >= na)) continue;
    int j2 = round((y2-my2)/rmatch + na/2);
    if ((j2 < 0) || (j2 >= na)) continue;

    int k2 = na*i2+j2;
    a[k2].push_back(k);
  }

  // Fit statistics
  int nf0 = 3; // Minimum number of points to fit
  int nf;
  double s1[2], s2[2], s21[2][2];

  // Loop to iterate fits
  for (int ifit = 0; ifit < maxIter; ifit++) {
    
    // Clear fit statistics
    nf = 0;
    for (int is = 0; is < 2; is++) {
      s1[is] = 0;
      s2[is] = 0;
      for (int js = 0; js < 2; js++)
	s21[is][js] = 0;
    }

    // Correlate p1 points in array
    double ca = cos(o[2]);
    double sa = sin(o[2]);
    // Iterate over all p1 points
    for (int k = 0; k < n1; k++) {
      double x1 = p1[m1*k];
      double y1 = p1[m1*k+1];

      // Transformed coordinates of p1
      double ox1 = o[0] + ca*x1 - sa*y1;
      double oy1 = o[1] + sa*x1 + ca*y1;
      int i1 = round((ox1 - mx2)/rmatch + na/2);
      if ((i1 < 0) || (i1 >= na)) continue;
      int j1 = round((oy1 - my2)/rmatch + na/2);
      if ((j1 < 0) || (j1 >= na)) continue;

      // Index into correlation array
      int k1 = na*i1+j1;

      // Find closest p2 point in array cell
      double dicp = INFINITY;
      int k2icp = -1;
      for (int ma = 0; ma < a[k1].size(); ma++) {
	int kk = a[k1][ma];
	double dm = (ox1-p2[m2*kk])*(ox1-p2[m2*kk])+
	  (oy1-p2[m2*kk+1])*(oy1-p2[m2*kk+1]);
	if (dm < dicp) {
	  dicp = dm;
	  k2icp = kk;
	}
      }

      // If there is a nearest point
      if (k2icp >= 0) {
	// Add to fit statistics
	double x2 = p2[m2*k2icp];
	double y2 = p2[m2*k2icp+1];

	nf++;
	s1[0] += x1;
	s1[1] += y1;
	s2[0] += x2;
	s2[1] += y2;
	s21[0][0] += x2*x1;
	s21[0][1] += x2*y1;
	s21[1][0] += y2*x1;
	s21[1][1] += y2*y1;

	//printf("%d->%d: (%.2f,%.2f)->(%.2f,%.2f)\n",k,k2icp,x1,y1,x2,y2);
      }
    }
  
    if (nf < nf0)
      // Not enough statistics to fit
      break;
    else
      nf0 = nf;

    // Compute transformation parameters
    s21[0][0] -= s2[0]*s1[0]/nf;
    s21[0][1] -= s2[0]*s1[1]/nf;
    s21[1][0] -= s2[1]*s1[0]/nf;
    s21[1][1] -= s2[1]*s1[1]/nf;

    // Fit rotation angle
    double ay = s21[0][1] - s21[1][0];
    double ax = s21[0][0] + s21[1][1];
    double afit = -atan2(ay,ax);
    
    // Fit translation
    double cafit = cos(afit);
    double safit = sin(afit);
    double oxfit = (s2[0]-(cafit*s1[0] - safit*s1[1]))/nf;
    double oyfit = (s2[1]-(safit*s1[0] + cafit*s1[1]))/nf;

    double dx = oxfit - o[0];
    double dy = oyfit - o[1];
    double da = afit - o[2];

    o[0] = oxfit;
    o[1] = oyfit;
    o[2] = afit;

    printf("Fit: %d pts, %.2f(%.2f) %.2f(%.2f) %.2f(%.2f)\n",
	   nf, o[0],dx,o[1],dy,o[2],da);

    // Fit is consistent
    if ((fabs(dx) < 0.01) && (fabs(dy) < 0.01) && (fabs(da) < 0.01))
      break;
  }

  // Return transformation parameters
  plhs[0] = mxCreateDoubleMatrix(3,1,mxREAL);
  double *oarray = mxGetPr(plhs[0]);
  for (int i = 0; i < 3; i++) {
    oarray[i] = o[i];
  }
}
