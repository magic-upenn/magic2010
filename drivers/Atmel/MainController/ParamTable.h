#ifndef PARAM_TABLE_H
#define PARAM_TABLE_H

#include <stdint.h>

typedef struct
{
  uint8_t id;   //id of the robot
  uint8_t mode;  
  uint16_t accBiasX;

  uint16_t accBiasY;
  uint16_t accBiasZ;
  
  uint16_t gyroNomBias;
  uint8_t  servo1Mode;
  uint8_t  servo2Mode;

  int16_t  servo1MinAngle;
  int16_t  servo1MaxAngle;
  
  uint16_t servo1MaxSpeed;
  int16_t  servo2MinAngle;
  
  int16_t  servo2MaxAngle;
  uint16_t servo2MaxSpeed;
  
  uint8_t dummy;
  uint8_t checksum;
} ParamTable;


#define PT_ID_OFFSET                offsetof(ParamTable,id)
#define PT_MODE_OFFSET              offsetof(ParamTable,mode)
#define PT_ACC_BIAS_X_OFFSET        offsetof(ParamTable,accBiasX)
#define PT_ACC_BIAS_Y_OFFSET        offsetof(ParamTable,accBiasY)
#define PT_ACC_BIAS_Z_OFFSET        offsetof(ParamTable,accBiasZ)
#define PT_CHECKSUM_OFFSET          offsetof(ParamTable,checksum)


#endif //PARAM_TABLE_H

