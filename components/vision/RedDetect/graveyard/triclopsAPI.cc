/*
   status = triclopsAPI(args);

   Matlab R14 Linux MEX file
   to interface to Triclops SDK API.

   Compile with:
   mex triclopsAPI.cc -I/usr/local/include -ltriclops -lpnmutils

   Daniel D. Lee, 1/07
   <ddlee@seas.upenn.edu>
*/

#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <math.h>

#include "mex.h"

#include "triclops.h"

typedef unsigned char uint8;
typedef unsigned short uint16;

static int inputRows = 384;
static int inputCols = 512;
static int outputRows = 240;
static int outputCols = 320;

static TriclopsContext context = NULL;
static TriclopsInput inputData, leftData, rightData;
static TriclopsColorImage colorImage;

int imageParameters(mxArray *plhs[])
{
  mxArray *fieldArray, *fieldArray2;
  double *x, *y;
  const char *fields[] = {
    "resolution", "baseLine", "focalLength", "center", "transform",
    "rectifyLeftX", "rectifyLeftY", "rectifyRightX", "rectifyRightY"
  };
  const int nfields = sizeof(fields)/sizeof(*fields);

  plhs[0] = mxCreateStructMatrix(1, 1, nfields, fields);

  int nrows, ncols;
  TriclopsError tErr = triclopsGetResolution(context, &nrows, &ncols);
  if (tErr == TriclopsErrorOk) {
    fieldArray = mxCreateDoubleMatrix(1, 2, mxREAL);
    y = mxGetPr(fieldArray);
    y[0] = nrows;
    y[1] = ncols;
    mxSetField(plhs[0], 0, "resolution", fieldArray);
  }

  float base;
  tErr = triclopsGetBaseline(context, &base);
  if (tErr == TriclopsErrorOk) {
    mxSetField(plhs[0], 0, "baseLine", mxCreateDoubleScalar(base));
  }

  float focalLength;
  tErr = triclopsGetFocalLength(context, &focalLength);
  if (tErr == TriclopsErrorOk) {
    mxSetField(plhs[0], 0, "focalLength", mxCreateDoubleScalar(focalLength));
  }

  float centerRow, centerCol;
  tErr = triclopsGetImageCenter(context, &centerRow, &centerCol);
  if (tErr == TriclopsErrorOk) {
    fieldArray = mxCreateDoubleMatrix(1, 2, mxREAL);
    y = mxGetPr(fieldArray);
    y[0] = centerRow;
    y[1] = centerCol;
    mxSetField(plhs[0], 0, "center", fieldArray);
  }

  TriclopsTransform transform;
  tErr = triclopsGetTriclopsToWorldTransform(context, &transform);
  if (tErr == TriclopsErrorOk) {
    fieldArray = mxCreateDoubleMatrix(4, 4, mxREAL);
    y = mxGetPr(fieldArray);
    for (int i=0; i<4; i++) {
      for (int j=0; j<4; j++) {
	*y++ = transform.matrix[j][i];
      }
    }
    mxSetField(plhs[0], 0, "transform", fieldArray);
  }

  fieldArray = mxCreateDoubleMatrix(ncols, nrows, mxREAL);
  x = mxGetPr(fieldArray);
  fieldArray2 = mxCreateDoubleMatrix(ncols, nrows, mxREAL);
  y = mxGetPr(fieldArray2);
  for (int i = 0; i < nrows; i++) {
    for (int j = 0; j < ncols; j++) {
      float row, col;
      tErr = triclopsUnrectifyPixel(context, TriCam_LEFT,
				    (float) i, (float) j,
				    &row, &col);
      x[ncols*i + j] = col;
      y[ncols*i + j] = row;
    }
  }
  mxSetField(plhs[0], 0, "rectifyLeftX", fieldArray);
  mxSetField(plhs[0], 0, "rectifyLeftY", fieldArray2);

  fieldArray = mxCreateDoubleMatrix(ncols, nrows, mxREAL);
  x = mxGetPr(fieldArray);
  fieldArray2 = mxCreateDoubleMatrix(ncols, nrows, mxREAL);
  y = mxGetPr(fieldArray2);
  for (int i = 0; i < nrows; i++) {
    for (int j = 0; j < ncols; j++) {
      float row, col;
      tErr = triclopsUnrectifyPixel(context, TriCam_RIGHT,
				    (float) i, (float) j,
				    &row, &col);
      x[ncols*i + j] = col;
      y[ncols*i + j] = row;
    }
  }
  mxSetField(plhs[0], 0, "rectifyRightX", fieldArray);
  mxSetField(plhs[0], 0, "rectifyRightY", fieldArray2);

  return 1;
}

int imageDisparity(mxArray *plhs[])
{
  // Put image rows into Matlab matrix columns
  int dims[2];
  dims[0] = outputCols;
  dims[1] = outputRows;

  TriclopsBool subpixelOn;
  TriclopsError tErr = triclopsGetSubpixelInterpolation(context, &subpixelOn);
  if (tErr != TriclopsErrorOk) mexErrMsgTxt(triclopsErrorToString(tErr));

  if (subpixelOn) {
    plhs[0] = mxCreateNumericArray(2, dims, mxUINT16_CLASS, mxREAL);
    // By setting image buffer, triclops writes disparity directly to array
    tErr = triclopsSetImage16Buffer(context, (uint16 *)mxGetData(plhs[0]), TriImg16_DISPARITY, TriCam_REFERENCE);
  }
  else {
    plhs[0] = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
    tErr = triclopsSetImageBuffer(context, (uint8 *)mxGetData(plhs[0]), TriImg_DISPARITY, TriCam_REFERENCE);
  }
  if (tErr != TriclopsErrorOk) mexErrMsgTxt(triclopsErrorToString(tErr));

  inputData.inputType = TriInp_RGB;
  inputData.nrows = rightData.nrows;
  inputData.ncols = rightData.ncols;
  inputData.rowinc = rightData.rowinc;
  inputData.timeStamp.sec = 0;
  inputData.timeStamp.u_sec = 0;
  inputData.u.rgb.red = rightData.u.rgb.green;
  inputData.u.rgb.green = leftData.u.rgb.green;
  inputData.u.rgb.blue = rightData.u.rgb.red; // placeholder

  /* Process stereo disparity */
  tErr = triclopsPreprocess(context, &inputData);
  if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));

  tErr = triclopsStereo(context);
  if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));

  if (subpixelOn) {
    tErr = triclopsUnsetImageBuffer(context, TriImg_DISPARITY, TriCam_REFERENCE);
  }
  else {
    tErr = triclopsUnsetImageBuffer(context, TriImg_DISPARITY, TriCam_REFERENCE);
  }
  if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));

  return 1;
}

int imageRGB(mxArray *plhs[])
{
  // Put image rows into Matlab matrix columns
  int dims[3];
  dims[0] = outputCols;
  dims[1] = outputRows;
  dims[2] = 3;

  plhs[0] = mxCreateNumericArray(3,dims,mxUINT8_CLASS,mxREAL);
  uint8 *pr = (uint8 *) mxGetData(plhs[0]);

  // By setting image buffer, triclops writes directly to array
  TriclopsError tErr =
    triclopsSetColorImageBuffer(context, TriCam_REFERENCE,
				pr,
				pr+outputCols*outputRows,
				pr+2*outputCols*outputRows);
  if (tErr != TriclopsErrorOk) mexErrMsgTxt(triclopsErrorToString(tErr));

  // rightData is reference
  tErr = triclopsRectifyColorImage(context, TriCam_REFERENCE, &rightData, &colorImage);
  if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));

  tErr = triclopsUnsetColorImageBuffer(context, TriCam_REFERENCE);
  if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));

  return 1;
}

int imageRGBl(mxArray *plhs[])
{
  // Put image rows into Matlab matrix columns
  int dims[3];
  dims[0] = outputCols;
  dims[1] = outputRows;
  dims[2] = 3;

  plhs[0] = mxCreateNumericArray(3,dims,mxUINT8_CLASS,mxREAL);
  uint8 *pr = (uint8 *) mxGetData(plhs[0]);

  // By setting image buffer, triclops writes directly to array
  TriclopsError tErr =
    triclopsSetColorImageBuffer(context, TriCam_REFERENCE,
				pr,
				pr+outputCols*outputRows,
				pr+2*outputCols*outputRows);
  if (tErr != TriclopsErrorOk) mexErrMsgTxt(triclopsErrorToString(tErr));

  // leftData
  tErr = triclopsRectifyColorImage(context, TriCam_REFERENCE, &leftData, &colorImage);
  if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));

  tErr = triclopsUnsetColorImageBuffer(context, TriCam_REFERENCE);
  if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));

  return 1;
}



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const int buflen = 256;
  char buf[buflen];
  int dims[3];
  TriclopsError tErr;

  // Get input arguments
  if (nrhs == 0) {
    mexErrMsgTxt("Need input argument");
    return;
  }

  if (mxGetString(prhs[0], buf, buflen) != 0) 
    mexErrMsgTxt("Could not read string.");

  if (strcmp(buf, "loadContext") == 0) {
    if ((nrhs < 2) || (mxGetString(prhs[1], buf, buflen) != 0))
      mexErrMsgTxt("Could not read string.");

    tErr = triclopsGetDefaultContextFromFile(&context, buf);
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));

    plhs[0] = mxCreateDoubleScalar(tErr);

    tErr = triclopsGetResolution(context, &outputRows, &outputCols);
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "loadTransform") == 0) {
    if ((nrhs < 2) || (mxGetString(prhs[1], buf, buflen) != 0))
      mexErrMsgTxt("Could not read string.");

    TriclopsTransform transform;
    tErr = triclopsGetTransformFromFile(buf, &transform);
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));

    tErr = triclopsSetTriclopsToWorldTransform(context, transform);
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));

    plhs[0] = mxCreateDoubleScalar(tErr);
  }

  else if (strcmp(buf, "imageParameters") == 0) {
    imageParameters(plhs);
    return;
  }

  else if (strcmp(buf, "imageDisparity") == 0) {
    imageDisparity(plhs);
    return;
  }

  else if (strcmp(buf, "imageRGB") == 0) {
    imageRGB(plhs);
    return;
  }
  else if (strcmp(buf, "imageRGBl") == 0) {
    imageRGBl(plhs);
    return;
  }

  else if (strcmp(buf, "setInputLeft") == 0) {
    if ((nrhs < 2) || (mxGetNumberOfDimensions(prhs[1]) != 3)) {
      mexErrMsgTxt("Matrix input should be 3 dimensional.");
    }

    const int *input_dims = mxGetDimensions(prhs[1]);
    if (input_dims[2] != 3) {
      mexErrMsgTxt("Matrix input dimensions should be m-n-3.");
    }
    int m = input_dims[0]; // Matlab nrows = Triclops ncols
    int n = input_dims[1]; // Matlab ncols = Triclops nrows
    uint8 *pr = (uint8 *) mxGetData(prhs[1]);

    leftData.inputType = TriInp_RGB;
    leftData.nrows = n;
    leftData.ncols = m;
    leftData.rowinc = m;
    leftData.timeStamp.sec = 0;
    leftData.timeStamp.u_sec = 0;
    leftData.u.rgb.red = pr;
    leftData.u.rgb.green = pr + m*n;
    leftData.u.rgb.blue = pr + 2*m*n;
  }

  else if (strcmp(buf, "setInputRight") == 0) {
    if ((nrhs < 2) || (mxGetNumberOfDimensions(prhs[1]) != 3)) {
      mexErrMsgTxt("Matrix input should be 3 dimensional.");
    }

    const int *input_dims = mxGetDimensions(prhs[1]);
    if (input_dims[2] != 3) {
      mexErrMsgTxt("Matrix input dimensions should be m-n-3.");
    }
    int m = input_dims[0]; // Matlab nrows = Triclops ncols
    int n = input_dims[1]; // Matlab ncols = Triclops nrows
    uint8 *pr = (uint8 *) mxGetData(prhs[1]);

    rightData.inputType = TriInp_RGB;
    rightData.nrows = n;
    rightData.ncols = m;
    rightData.rowinc = m;
    rightData.timeStamp.sec = 0;
    rightData.timeStamp.u_sec = 0;
    rightData.u.rgb.red = pr;
    rightData.u.rgb.green = pr + m*n;
    rightData.u.rgb.blue = pr + 2*m*n;
  }

  else if (strcmp(buf, "triclopsVersion") == 0) {
    plhs[0] = mxCreateString(triclopsVersion());
    return;
  }

  else if (strcmp(buf, "setResolution") == 0) {
    if (nrhs >= 3) {
      outputRows = (int) mxGetScalar(prhs[1]);
      outputCols = (int) mxGetScalar(prhs[2]);
    }
    else {
      mexErrMsgTxt("Need to input resolution rows and cols.");
    }
    TriclopsError tErr =
      triclopsSetResolutionAndPrepare(context, outputRows, outputCols,
				      inputRows, inputCols);
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "setDisparity") == 0) {
    tErr = triclopsSetDisparity(context, (int)mxGetScalar(prhs[1]), (int)mxGetScalar(prhs[2]));
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "setSubpixelInterpolation") == 0) {
    tErr = triclopsSetSubpixelInterpolation(context, (int)mxGetScalar(prhs[1]));
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "setStereoMask") == 0) {
    tErr = triclopsSetStereoMask(context, (int)mxGetScalar(prhs[1]));
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "setTextureValidation") == 0) {
    tErr = triclopsSetTextureValidation(context, (int)mxGetScalar(prhs[1]));
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "setTextureValidationThreshold") == 0) {
    tErr = triclopsSetTextureValidationThreshold(context, mxGetScalar(prhs[1]));
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "setUniquenessValidation") == 0) {
    tErr = triclopsSetUniquenessValidation(context, (int)mxGetScalar(prhs[1]));
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "setUniquenessValidationThreshold") == 0) {
    tErr = triclopsSetUniquenessValidationThreshold(context, mxGetScalar(prhs[1]));
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "setSurfaceValidation") == 0) {
    tErr = triclopsSetSurfaceValidation(context, (int)mxGetScalar(prhs[1]));
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "setSurfaceValidationDifference") == 0) {
    tErr = triclopsSetSurfaceValidationDifference(context, mxGetScalar(prhs[1]));
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else if (strcmp(buf, "setSurfaceValidationSize") == 0) {
    tErr = triclopsSetSurfaceValidationSize(context, (int)mxGetScalar(prhs[1]));
    if (tErr != TriclopsErrorOk) mexWarnMsgTxt(triclopsErrorToString(tErr));
  }

  else {
    mexErrMsgTxt("Unknown option");
  }

  // Return default output:
  plhs[0] = mxCreateDoubleScalar((double) tErr);

}
