#include "MexIpcSerialization.hh"
#include "MagicPlanDataTypes.h"


int GP_DATA::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,NR,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,GP_PLAN_TIME,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,DIST_GAIN,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,MIN_RANGE,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,MAX_RANGE,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,DIST_PENALTY,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,REGION_PENALTY,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,map_cell_size,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,map_size_x,numFieldsRead); 
  MEX_READ_FIELD(mxArr,index,map_size_y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,UTM_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,UTM_y,numFieldsRead);

  MEX_READ_FIELD_RAW_ARRAY2D_INT16(mxArr,index,avail,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,x,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,y,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,theta,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,map,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,region_map,numFieldsRead);

    MEX_READ_FIELD(mxArr,index,num_regions,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,num_states,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,bias_table,numFieldsRead);


  return numFieldsRead;
}

int GP_DATA::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "NR", "GP_PLAN_TIME", "DIST_GAIN", "MIN_RANGE", "MAX_RANGE", "DIST_PENALTY", "REGION_PENALTY", "map_cell_size", "map_size_x", "map_size_y", "UTM_x", "UTM_y", "avail", "x", "y", "theta","map","region_map", "num_regions", "num_states", "bias_table" };
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GP_DATA::WriteToMatlab(mxArray * mxArr, int index)
{
 
  MEX_WRITE_FIELD(mxArr,index,NR);
  MEX_WRITE_FIELD(mxArr,index,GP_PLAN_TIME);
  MEX_WRITE_FIELD(mxArr,index,DIST_GAIN);
  MEX_WRITE_FIELD(mxArr,index,MIN_RANGE);
  MEX_WRITE_FIELD(mxArr,index,MAX_RANGE);
  MEX_WRITE_FIELD(mxArr,index,DIST_PENALTY);
  MEX_WRITE_FIELD(mxArr,index,REGION_PENALTY);
  MEX_WRITE_FIELD(mxArr,index,map_cell_size);
  MEX_WRITE_FIELD(mxArr,index,map_size_x); 
  MEX_WRITE_FIELD(mxArr,index,map_size_y);
  MEX_WRITE_FIELD(mxArr,index,UTM_x);
  MEX_WRITE_FIELD(mxArr,index,UTM_y);

  MEX_WRITE_FIELD_RAW_ARRAY2D_INT16(mxArr,index,avail,NR, 1);
  MEX_WRITE_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,x,NR, 1);
  MEX_WRITE_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,y,NR, 1);
  MEX_WRITE_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,theta,NR, 1);
  MEX_WRITE_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,map, map_size_x, map_size_y);
  MEX_WRITE_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,region_map, map_size_x, map_size_y);
  
    MEX_WRITE_FIELD(mxArr,index,num_regions);
  MEX_WRITE_FIELD(mxArr,index,num_states);
  MEX_WRITE_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,bias_table, num_states, num_regions);

  return 0;
}




int GP_TRAJ::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,NR,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_UINT16(mxArr,index, traj_size, numFieldsRead);
  MEX_READ_FIELD(mxArr,index,total_size,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,POSEX,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,POSEY,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,POSETHETA,numFieldsRead);


  return numFieldsRead;
}

int GP_TRAJ::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "NR", "traj_size", "total_size", "POSEX", "POSEY", "POSETHETA"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GP_TRAJ::WriteToMatlab(mxArray * mxArr, int index)
{
 
  MEX_WRITE_FIELD(mxArr,index,NR);
  MEX_WRITE_FIELD_RAW_ARRAY2D_UINT16(mxArr,index,traj_size,NR, 1);
  MEX_WRITE_FIELD(mxArr,index,total_size);
  MEX_WRITE_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,POSEX,total_size,1);
  MEX_WRITE_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,POSEY,total_size,1);
  MEX_WRITE_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,POSETHETA,total_size,1);
  
  return 0;
}

