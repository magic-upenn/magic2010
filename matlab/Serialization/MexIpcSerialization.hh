#ifndef MEX_IPC_SERIALIZATION
#define MEX_IPC_SERIALIZATION

#ifdef MATLAB_MEX_FILE
  #include <mex.h>
  #include <string.h>
  #include <ipc.h>

  #define INSERT_SERIALIZATION_DECLARATIONS \
        int ReadFromMatlab(mxArray * mxArr, int index); \
        static int CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n); \
        int WriteToMatlab(mxArray * mxArr, int index);
  
  void CreateSerializedOutputAndFreeVarcontent(mxArray ** output, IPC_VARCONTENT_TYPE * varcontent)
  {
    int dims[2];
    dims[0] = 1;
    dims[1] = varcontent->length;
    output[0]  = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL);
    memcpy(mxGetData(output[0]),varcontent->content,varcontent->length);
    IPC_freeByteArray(varcontent->content);
  }

  #define MEX_READ_FIELD( mxArr, index, fieldName, cntr ) \
  { \
    mxArray * mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      fieldName = mxGetPr(mxArrTemp)[0]; \
      cntr++; \
    } \
  }
  
  #define MEX_READ_FIELD_ARRAY_UINT8( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxUINT8_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not uint8"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      fieldName.size = mxGetNumberOfElements(mxArrTemp); \
      if (fieldName.size > 0) \
      { \
        fieldName.data = mxGetData(mxArrTemp); \
        cntr++; \
      }\
      else \
        fieldName.data = NULL; \
    } \
  }
  
  #define MEX_READ_FIELD_RAW_ARRAY_UINT8( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxUINT8_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not uint8"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int size = mxGetNumberOfElements(mxArrTemp); \
      if (size > 0) \
      { \
        fieldName = (uint8_t*)mxGetData(mxArrTemp); \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }
  
  #define MEX_TRANSPOSE_COPY( src, dest, sizex, sizey ) \
  { \
    for (int ii=0; ii<sizex; ii++) \
    { \
      for (int jj=0; jj<sizey; jj++) \
      { \
        dest[jj*sizex + ii] = src[ii*sizey + jj];\
      }\
    }\
  }
  
  #define MEX_READ_FIELD_RAW_ARRAY2D_UINT8( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxUINT8_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not uint8"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int sizex = mxGetN(mxArrTemp); \
      int sizey = mxGetM(mxArrTemp); \
      int len   = sizex * sizey; \
      uint8_t * matData = (uint8_t*)mxGetData(mxArrTemp); \
      if (len > 0) \
      { \
        fieldName = matData; \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }

  #define MEX_READ_FIELD_RAW_ARRAY2D_CHAR( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if ((mxGetClassID(mxArrTemp) != mxCHAR_CLASS) && (mxGetClassID(mxArrTemp) != mxUINT8_CLASS))\
        mexErrMsgTxt("field "#fieldName" is not char"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int sizex = mxGetN(mxArrTemp); \
      int sizey = mxGetM(mxArrTemp); \
      int len   = sizex * sizey; \
      char * matData = (char*)mxGetData(mxArrTemp); \
      if (len > 0) \
      { \
        fieldName = matData; \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }

  #define MEX_READ_FIELD_RAW_ARRAY2D_INT16( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxINT16_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not int16"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int sizex = mxGetN(mxArrTemp); \
      int sizey = mxGetM(mxArrTemp); \
      int len   = sizex * sizey; \
      int16_t * matData = (int16_t*)mxGetData(mxArrTemp); \
      if (len > 0) \
      { \
        fieldName = matData; \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }

  #define MEX_READ_FIELD_RAW_ARRAY2D_UINT16( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxUINT16_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not uint16"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int sizex = mxGetN(mxArrTemp); \
      int sizey = mxGetM(mxArrTemp); \
      int len   = sizex * sizey; \
      uint16_t * matData = (uint16_t*)mxGetData(mxArrTemp); \
      if (len > 0) \
      { \
        fieldName = matData; \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }

  #define MEX_READ_FIELD_RAW_ARRAY2D_FLOAT( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxSINGLE_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not float"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int sizex = mxGetN(mxArrTemp); \
      int sizey = mxGetM(mxArrTemp); \
      int len   = sizex * sizey; \
      float * matData = (float*)mxGetData(mxArrTemp); \
      if (len > 0) \
      { \
        fieldName = matData; \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }

  #define MEX_READ_FIELD_RAW_ARRAY2D_DOUBLE( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxDOUBLE_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not double"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int sizex = mxGetN(mxArrTemp); \
      int sizey = mxGetM(mxArrTemp); \
      int len   = sizex * sizey; \
      double * matData = (double*)mxGetData(mxArrTemp); \
      if (len > 0) \
      { \
        fieldName = matData; \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }


  #define MEX_READ_FIELD_RAW_ARRAY3D_FLOAT( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxSINGLE_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not float"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int sizex = mxGetN(mxArrTemp); \
      int sizey = mxGetM(mxArrTemp); \
      int len   = sizex * sizey; \
      float * matData = (float*)mxGetData(mxArrTemp); \
      if (len > 0) \
      { \
        fieldName = matData; \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }
  
  #define MEX_READ_FIELD_ARRAY_UINT16( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxUINT16_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not uint16"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      fieldName.size = mxGetNumberOfElements(mxArrTemp); \
      if (fieldName.size > 0) \
      { \
        fieldName.data = (uint16_t*)mxGetData(mxArrTemp); \
        cntr++; \
      } \
      else \
        fieldName.data = NULL; \
    } \
  }

  #define MEX_READ_FIELD_ARRAY_UINT32( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxUINT32_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not uint32"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      fieldName.size = mxGetNumberOfElements(mxArrTemp); \
      if (fieldName.size > 0) \
      { \
        fieldName.data = (uint32_t*)mxGetData(mxArrTemp); \
        cntr++; \
      } \
      else \
        fieldName.data = NULL; \
    } \
  }
  
  #define MEX_READ_FIELD_ARRAY_FLOAT( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxSINGLE_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not float"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      fieldName.size = mxGetNumberOfElements(mxArrTemp); \
      if (fieldName.size > 0) \
      { \
        fieldName.data = (float*)mxGetData(mxArrTemp); \
        cntr++; \
      } \
      else \
        fieldName.data = NULL; \
    } \
  }
  
  #define MEX_READ_FIELD_ARRAY_DOUBLE( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxDOUBLE_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not double"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      fieldName.size = mxGetNumberOfElements(mxArrTemp); \
      if (fieldName.size > 0) \
      { \
        fieldName.data = (double*)mxGetData(mxArrTemp); \
        cntr++; \
      } \
      else \
        fieldName.data = NULL; \
    } \
  }
  
  #define MEX_READ_FIELD_RAW_ARRAY_FLOAT( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxSINGLE_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not float"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int size = mxGetNumberOfElements(mxArrTemp); \
      if (size > 0) \
      { \
        fieldName = (float*)mxGetData(mxArrTemp); \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }

  #define MEX_READ_FIELD_RAW_ARRAY_UINT32( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxUINT32_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not uint32"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int size = mxGetNumberOfElements(mxArrTemp); \
      if (size > 0) \
      { \
        fieldName = (uint32_t*)mxGetData(mxArrTemp); \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }

  #define MEX_READ_FIELD_RAW_ARRAY_DOUBLE( mxArr, index, fieldName, cntr ) \
  { \
    mxArray *  mxArrTemp = mxGetField(mxArr,index,#fieldName); \
    if (mxArrTemp) \
    { \
      if (mxGetClassID(mxArrTemp) != mxDOUBLE_CLASS) \
        mexErrMsgTxt("field "#fieldName" is not double"); \
      if (mxGetNumberOfElements(mxArrTemp) == 0) \
        mexErrMsgTxt("field "#fieldName" is empty"); \
      int size = mxGetNumberOfElements(mxArrTemp); \
      if (size > 0) \
      { \
        fieldName = (double*)mxGetData(mxArrTemp); \
        cntr++; \
      } \
      else \
        fieldName = NULL; \
    } \
  }
  

  #define MEX_WRITE_FIELD(mxArr,index,fieldName) \
  { \
    mxSetField(mxArr,index,#fieldName,mxCreateDoubleScalar(fieldName)); \
  }

  #define MEX_WRITE_FIELD_ARRAY_UINT8(mxArr,index,fieldName) \
  { \
    int dims[2]; \
    dims[0] = fieldName.size > 0 ? 1 : 0; \
    dims[1] = fieldName.size; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName.data,fieldName.size*sizeof(uint8_t)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }
  
  #define MEX_WRITE_FIELD_RAW_ARRAY_UINT8(mxArr,index,fieldName,size) \
  { \
    int dims[2]; \
    dims[0] = size > 0 ? 1 : 0; \
    dims[1] = size; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,size*sizeof(uint8_t)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_ARRAY_UINT16(mxArr,index,fieldName) \
  { \
    int dims[2]; \
    dims[0] = fieldName.size > 0 ? 1 : 0; \
    dims[1] = fieldName.size; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxUINT16_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName.data,fieldName.size*sizeof(uint16_t)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_ARRAY_UINT32(mxArr,index,fieldName) \
  { \
    int dims[2]; \
    dims[0] = fieldName.size > 0 ? 1 : 0; \
    dims[1] = fieldName.size; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxUINT32_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName.data,fieldName.size*sizeof(uint32_t)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_RAW_ARRAY_UINT32(mxArr,index,fieldName,size) \
  { \
    int dims[2]; \
    dims[0] = size > 0 ? 1 : 0; \
    dims[1] = size; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxUINT32_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,size*sizeof(uint32_t)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_ARRAY_FLOAT(mxArr,index,fieldName) \
  { \
    int dims[2]; \
    dims[0] = fieldName.size > 0 ? 1 : 0; \
    dims[1] = fieldName.size; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxSINGLE_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName.data,fieldName.size*sizeof(float)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_RAW_ARRAY_FLOAT(mxArr,index,fieldName,size) \
  { \
    int dims[2]; \
    dims[0] = size > 0 ? 1 : 0; \
    dims[1] = size; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxSINGLE_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,size*sizeof(float)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }
  
  #define MEX_WRITE_FIELD_ARRAY_DOUBLE(mxArr,index,fieldName) \
  { \
    int dims[2]; \
    dims[0] = fieldName.size > 0 ? 1 : 0; \
    dims[1] = fieldName.size; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName.data,fieldName.size*sizeof(double)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  
  #define MEX_WRITE_FIELD_RAW_ARRAY_DOUBLE(mxArr,index,fieldName,size) \
  { \
    int dims[2]; \
    dims[0] = size > 0 ? 1 : 0; \
    dims[1] = size; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,size*sizeof(double)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,fieldName,sizex,sizey) \
  { \
    int dims[2]; \
    dims[0] = sizex; \
    dims[1] = sizey; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxUINT8_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,sizex*sizey*sizeof(uint8_t)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_RAW_ARRAY2D_INT16(mxArr,index,fieldName,sizex,sizey) \
  { \
    int dims[2]; \
    dims[0] = sizex; \
    dims[1] = sizey; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxINT16_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,sizex*sizey*sizeof(int16_t)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_RAW_ARRAY2D_UINT16(mxArr,index,fieldName,sizex,sizey) \
  { \
    int dims[2]; \
    dims[0] = sizex; \
    dims[1] = sizey; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxUINT16_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,sizex*sizey*sizeof(uint16_t)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_RAW_ARRAY2D_CHAR(mxArr,index,fieldName,sizex,sizey) \
  { \
    int dims[2]; \
    dims[0] = sizex; \
    dims[1] = sizey; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxCHAR_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,sizex*sizey*sizeof(char)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_RAW_ARRAY2D_FLOAT(mxArr,index,fieldName,sizex,sizey) \
  { \
    int dims[2]; \
    dims[0] = sizex; \
    dims[1] = sizey; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxSINGLE_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,sizex*sizey*sizeof(float)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,fieldName,sizex,sizey) \
  { \
    int dims[2]; \
    dims[0] = sizex; \
    dims[1] = sizey; \
    mxArray * mxa = mxCreateNumericArray(2,dims,mxDOUBLE_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,sizex*sizey*sizeof(double)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

  #define MEX_WRITE_FIELD_RAW_ARRAY3D_FLOAT(mxArr,index,fieldName,sizex,sizey,sizez) \
  { \
    int dims[3]; \
    dims[0] = sizex; \
    dims[1] = sizey; \
    dims[2] = sizez; \
    mxArray * mxa = mxCreateNumericArray(3,dims,mxSINGLE_CLASS,mxREAL); \
    memcpy(mxGetData(mxa),fieldName,sizex*sizey*sizez*sizeof(float)); \
    mxSetField(mxArr,index,#fieldName,mxa); \
  }

#endif

#endif //MEX_IPC_SERIALIZATION
