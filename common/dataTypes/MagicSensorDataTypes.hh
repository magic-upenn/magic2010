#ifndef MAGIC_SENSOR_DATA_TYPES_HH
#define MAGIC_SENSOR_DATA_TYPES_HH

#ifndef  __APPLE__
#include "VisDataTypes.hh"
#else
#include <Vis/VisDataTypes.hh>
#endif

#include <string.h>

using namespace vis;

namespace Magic
{
  struct LidarScan
  {
    uint32_t      counter;
    uint32_t      id;
    FloatArray    ranges ;
    UInt16Array   intensities ;

    float         startAngle ; // radians
    float         stopAngle ;  // radians
    float         angleStep ;  // radians
    double        startTime ;  // seconds
    double        stopTime ;   // seconds

    #define MagicLidarScan_IPC_FORMAT "{ uint, uint," FloatArray_IPC_FORMAT \
                                 ", " UInt16Array_IPC_FORMAT ", "\
                                 " float, float, float, double, double}"

    static const char*  getIPCFormat() { return MagicLidarScan_IPC_FORMAT; };

#ifdef MATLAB_MEX_FILE
    int ReadFromMatlab(mxArray * mxArr, int index)
    {
      int numFieldsRead = 0;

      MEX_READ_FIELD(mxArr,index,counter,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,id,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,startAngle,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,stopAngle,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,angleStep,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,startTime,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,stopTime,numFieldsRead);
      
      MEX_READ_FIELD_ARRAY_FLOAT(mxArr,index,ranges,numFieldsRead);
      MEX_READ_FIELD_ARRAY_UINT16(mxArr,index,intensities,numFieldsRead);

      return numFieldsRead;
    }

    static int CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
    {
      const char * fields[]= { "counter","id","ranges","intensities","startAngle",
                               "stopAngle","angleStep","startTime","stopTime"};
      const int nfields = sizeof(fields)/sizeof(*fields);
      *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
      return 0;
    }
    
    int WriteToMatlab(mxArray * mxArr, int index)
    {
      MEX_WRITE_FIELD(mxArr,index,counter);
      MEX_WRITE_FIELD(mxArr,index,id);
      MEX_WRITE_FIELD_ARRAY_FLOAT(mxArr,index,ranges);
      MEX_WRITE_FIELD_ARRAY_UINT16(mxArr,index,intensities);
      MEX_WRITE_FIELD(mxArr,index,startAngle);
      MEX_WRITE_FIELD(mxArr,index,stopAngle);
      MEX_WRITE_FIELD(mxArr,index,angleStep);
      MEX_WRITE_FIELD(mxArr,index,startTime);
      MEX_WRITE_FIELD(mxArr,index,stopTime);

      return 0;
    }
#endif
  };

  struct ServoState
  {
    uint32_t  counter;
    uint32_t  id;
    float     position ;     // radians
    float     velocity ;     // radians / sec
    float     acceleration ; // radians / sec^2
    double    t;     // seconds

    #define MagicServoState_IPC_FORMAT "{ uint, uint, float, float, float, double }"

    static const char*  getIPCFormat() { return MagicServoState_IPC_FORMAT; };

#ifdef MATLAB_MEX_FILE
    int ReadFromMatlab(mxArray * mxArr, int index)
    {
      int numFieldsRead = 0;

      MEX_READ_FIELD(mxArr,index,counter,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,id,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,position,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,velocity,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,acceleration,numFieldsRead);
      MEX_READ_FIELD(mxArr,index,t,numFieldsRead);
      
      return numFieldsRead;
    }

    static int CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
    {
      const char * fields[]= { "counter","id","position","velocity","acceleration","t"};
      const int nfields = sizeof(fields)/sizeof(*fields);
      *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
      return 0;
    }
    
    int WriteToMatlab(mxArray * mxArr, int index)
    {
      MEX_WRITE_FIELD(mxArr,index,counter);
      MEX_WRITE_FIELD(mxArr,index,id);
      MEX_WRITE_FIELD(mxArr,index,position);
      MEX_WRITE_FIELD(mxArr,index,velocity);
      MEX_WRITE_FIELD(mxArr,index,acceleration);
      MEX_WRITE_FIELD(mxArr,index,t);
      return 0;
    }
#endif

  };
}

#endif //MAGIC_SENSOR_DATA_TYPES_HH

