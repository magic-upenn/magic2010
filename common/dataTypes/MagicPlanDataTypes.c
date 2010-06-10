#include "MexIpcSerialization.hh"
#include "MagicPlanDataTypes.h"



int GP_SET_STATE::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,shouldRun,numFieldsRead);

  return numFieldsRead;
}

int GP_SET_STATE::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "shouldRun"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GP_SET_STATE::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,shouldRun);

  return 0;
}




int GP_MAGIC_MAP::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,size_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,size_y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,resolution,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,UTM_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,UTM_y,numFieldsRead);
  

  MEX_READ_FIELD_RAW_ARRAY2D_INT16(mxArr,index,map,numFieldsRead);

  return numFieldsRead;
}

int GP_MAGIC_MAP::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "size_x","size_y","resolution","UTM_x","UTM_y","map"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GP_MAGIC_MAP::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,size_x);
  MEX_WRITE_FIELD(mxArr,index,size_y);
  MEX_WRITE_FIELD(mxArr,index,resolution);
  MEX_WRITE_FIELD(mxArr,index,UTM_x);
  MEX_WRITE_FIELD(mxArr,index,UTM_y);
  

  MEX_WRITE_FIELD_RAW_ARRAY2D_INT16(mxArr,index,map,size_x,size_y);

  return 0;
}






int GP_MAP_DATA::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,timestamp,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,cost_size_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,cost_size_y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,elev_size_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,elev_size_y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,coverage_size_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,coverage_size_y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,cost_cell_size,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,elev_cell_size,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,coverage_cell_size,numFieldsRead);

  return numFieldsRead;
}

int GP_MAP_DATA::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "timestamp","cost_size_x","cost_size_y","elev_size_x",
                           "elev_size_y","coverage_size_x","coverage_size_y",
                           "cost_cell_size","elev_cell_size","coverage_cell_size"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GP_MAP_DATA::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,timestamp);
  MEX_WRITE_FIELD(mxArr,index,cost_size_x);
  MEX_WRITE_FIELD(mxArr,index,cost_size_y);
  MEX_WRITE_FIELD(mxArr,index,elev_size_x);
  MEX_WRITE_FIELD(mxArr,index,elev_size_y);
  MEX_WRITE_FIELD(mxArr,index,coverage_size_x);
  MEX_WRITE_FIELD(mxArr,index,coverage_size_y);
  MEX_WRITE_FIELD(mxArr,index,cost_cell_size);
  MEX_WRITE_FIELD(mxArr,index,elev_cell_size);
  MEX_WRITE_FIELD(mxArr,index,coverage_cell_size);
  
  return 0;
}





int GP_ROBOT_PARAMETER::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,MAX_VELOCITY,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,MAX_TURN_RATE,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,I_DIMENSION,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,J_DIMENSION,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sensor_radius,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sensor_height,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,PerimeterArray,numFieldsRead);

  return numFieldsRead;
}

int GP_ROBOT_PARAMETER::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "MAX_VELOCITY","MAX_TURN_RATE","I_DIMENSION","J_DIMENSION",
                           "sensor_radius","sensor_height","PerimeterArray"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GP_ROBOT_PARAMETER::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,MAX_VELOCITY);
  MEX_WRITE_FIELD(mxArr,index,MAX_TURN_RATE);
  MEX_WRITE_FIELD(mxArr,index,I_DIMENSION);
  MEX_WRITE_FIELD(mxArr,index,J_DIMENSION);
  MEX_WRITE_FIELD(mxArr,index,sensor_radius);
  MEX_WRITE_FIELD(mxArr,index,sensor_height);
  
  MEX_WRITE_FIELD_RAW_ARRAY2D_DOUBLE(mxArr,index,PerimeterArray,I_DIMENSION,J_DIMENSION);
  
  return 0;
}




int GP_POSITION_UPDATE::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,timestamp,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,theta,numFieldsRead);

  return numFieldsRead;
}

int GP_POSITION_UPDATE::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "timestamp","x","y","theta"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GP_POSITION_UPDATE::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,timestamp);
  MEX_WRITE_FIELD(mxArr,index,x);
  MEX_WRITE_FIELD(mxArr,index,y);
  MEX_WRITE_FIELD(mxArr,index,theta);
  return 0;
}






int GP_FULL_UPDATE::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,timestamp,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,UTM_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,UTM_y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_cover_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_cover_y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_cost_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_cost_y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_elev_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_elev_y,numFieldsRead);
  

  MEX_READ_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,coverage_map,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,cost_map,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_INT16(mxArr,index,elev_map,numFieldsRead);

  return numFieldsRead;
}

int GP_FULL_UPDATE::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "timestamp","UTM_x","UTM_y","sent_cover_x","sent_cover_y","sent_cost_x",
                            "sent_cost_y","sent_elev_x","sent_elev_y","coverage_map",
                            "cost_map","elev_map"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GP_FULL_UPDATE::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,timestamp);
  MEX_WRITE_FIELD(mxArr,index,UTM_x);
  MEX_WRITE_FIELD(mxArr,index,UTM_y);
  MEX_WRITE_FIELD(mxArr,index,sent_cover_x);
  MEX_WRITE_FIELD(mxArr,index,sent_cover_y);
  MEX_WRITE_FIELD(mxArr,index,sent_cost_x);
  MEX_WRITE_FIELD(mxArr,index,sent_cost_y);
  MEX_WRITE_FIELD(mxArr,index,sent_elev_x);
  MEX_WRITE_FIELD(mxArr,index,sent_elev_y);
  

  MEX_WRITE_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,coverage_map,sent_cover_x,sent_cover_y);
  MEX_WRITE_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,cost_map,sent_cost_x,sent_cost_y);
  MEX_WRITE_FIELD_RAW_ARRAY2D_INT16(mxArr,index,elev_map,sent_elev_x,sent_elev_y);

  return 0;
}



int GP_SHORT_UPDATE::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,timestamp,numFieldsRead);
  
  MEX_READ_FIELD(mxArr,index,sent_cover_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_cover_y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_cost_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_cost_y,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_elev_x,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,sent_elev_y,numFieldsRead);
  
  MEX_READ_FIELD(mxArr,index,x_cover_start,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,y_cover_start,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,x_cost_start,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,y_cost_start,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,x_elev_start,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,y_elev_start,numFieldsRead);
  

  MEX_READ_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,coverage_map,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,cost_map,numFieldsRead);
  MEX_READ_FIELD_RAW_ARRAY2D_INT16(mxArr,index,elev_map,numFieldsRead);
  return numFieldsRead;
}

int GP_SHORT_UPDATE::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "timestamp","sent_cover_x","sent_cover_y","sent_cost_x",
                            "sent_cost_y","sent_elev_x","sent_elev_y","coverage_map",
                            "cost_map","elev_map"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GP_SHORT_UPDATE::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,timestamp);
  
  MEX_WRITE_FIELD(mxArr,index,sent_cover_x);
  MEX_WRITE_FIELD(mxArr,index,sent_cover_y);
  MEX_WRITE_FIELD(mxArr,index,sent_cost_x);
  MEX_WRITE_FIELD(mxArr,index,sent_cost_y);
  MEX_WRITE_FIELD(mxArr,index,sent_elev_x);
  MEX_WRITE_FIELD(mxArr,index,sent_elev_y);
  
  MEX_WRITE_FIELD(mxArr,index,x_cover_start);
  MEX_WRITE_FIELD(mxArr,index,y_cover_start);
  MEX_WRITE_FIELD(mxArr,index,x_cost_start);
  MEX_WRITE_FIELD(mxArr,index,y_cost_start);
  MEX_WRITE_FIELD(mxArr,index,x_elev_start);
  MEX_WRITE_FIELD(mxArr,index,y_elev_start);
  
  MEX_WRITE_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,coverage_map,sent_cover_x,sent_cover_y);
  MEX_WRITE_FIELD_RAW_ARRAY2D_UINT8(mxArr,index,cost_map,sent_cost_x,sent_cost_y);
  MEX_WRITE_FIELD_RAW_ARRAY2D_INT16(mxArr,index,elev_map,sent_elev_x,sent_elev_y);
  return 0;
}



int GP_TRAJECTORY::ReadFromMatlab(mxArray * mxArr, int index)
{
  int numFieldsRead = 0;

  MEX_READ_FIELD(mxArr,index,num_traj_pts,numFieldsRead);
  MEX_READ_FIELD(mxArr,index,traj_dim,numFieldsRead);
  
  MEX_READ_FIELD_RAW_ARRAY2D_FLOAT(mxArr,index,traj_array,numFieldsRead);
  return numFieldsRead;
}

int GP_TRAJECTORY::CreateMatlabStructMatrix(mxArray ** mxArrPP,int m, int n)
{
  const char * fields[]= { "num_traj_pts","traj_dim","traj_array"};
  const int nfields = sizeof(fields)/sizeof(*fields);
    
  *mxArrPP = mxCreateStructMatrix(m,n,nfields,fields);
  return 0;
}

int GP_TRAJECTORY::WriteToMatlab(mxArray * mxArr, int index)
{
  MEX_WRITE_FIELD(mxArr,index,num_traj_pts);
  MEX_WRITE_FIELD(mxArr,index,traj_dim);
  
  MEX_WRITE_FIELD_RAW_ARRAY2D_FLOAT(mxArr,index,traj_array,num_traj_pts,traj_dim);
  return 0;
}







