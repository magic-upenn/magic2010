#ifndef PARAM_TABLE_H
#define PARAM_TABLE_H

#include <stdint.h>

typedef struct
{
  uint8_t id;   //id of the robot
  uint8_t dummy;  
  
  uint16_t accBiasX;
  uint16_t accBiasY;
  uint16_t accBiasZ;
  
  uint8_t checksum;
} ParamTable;

#endif //PARAM_TABLE_H

