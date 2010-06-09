#include "mapConverter.h"

#define OBS_THRESH 50

//If you use an outRes that is not a multiple of the msg->resolution the downsampling will not be as accurate!!!
void convertMap(GP_MAGIC_MAP_PTR msg, bool makeAllMaps, float outRes, 
                unsigned char* costmap, int16_t* elevmap, unsigned char* covmap,
                int* new_size_x, int* new_size_y){
  
  int size_x = msg->size_x;
  int size_y = msg->size_y;

  costmap = new unsigned char[size_x*size_y];
  if(makeAllMaps){
    elevmap = new int16_t[size_x*size_y];
    covmap = new unsigned char[size_x*size_y];
  }

  int step = (int)(outRes/msg->resolution+0.5);
  int sx = size_x/step;
  int sy = size_y/step;
  *new_size_x = sx;
  *new_size_y = sy;
  for(int y=0; y<sy; y++){
    for(int x=0; x<sx; x++){
      bool isObstacle = false;
      for(int y1=step*y; y1<y+step; y1++){
        for(int x1=step*x; x1<x+step; x1++){
          if(msg->map[x1+size_x*y1] > OBS_THRESH)
            isObstacle = true;
        }
      }
      costmap[x+sx*y] = (isObstacle ? 250 : 0);
    }
  }

  if(makeAllMaps){
    for(int y=0; y<sy; y++)
      for(int x=0; x<sx; x++)
        elevmap[x+size_x*y] = ((int16_t)costmap[x+size_x*y])*4;

    for(int y=0; y<sy; y++){
      for(int x=0; x<sx; x++){
        bool isExplored = false;
        for(int y1=step*y; y1<y+step; y1++){
          for(int x1=step*x; x1<x+step; x1++){
            if(msg->map[x1+size_x*y1] != 0)
              isExplored = true;
          }
        }
        covmap[x+sx*y] = (isExplored  ? 249 : 0);
      }
    }
  }

}
