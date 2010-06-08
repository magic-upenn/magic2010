#ifndef MAGIC_MICRO_COM_H
#define MAGIC_MICRO_COM_H

#include <stdio.h>


#define MMC_READY_MSG "\r\nMAGIC Controller Ready\r\n"
#define MMC_GPS_LINE_SIZE_MAX 128

enum { MMC_MAIN_CONTROLLER_DEVICE_ID,
       MMC_GPS_DEVICE_ID,
       MMC_IMU_DEVICE_ID,
       MMC_MOTOR_CONTROLLER_DEVICE_ID,
       MMC_DYNAMIXEL0_DEVICE_ID,
       MMC_DYNAMIXEL1_DEVICE_ID,
       MMC_GATEWAY_DEVICE_ID,
       MMC_RC_DEVICE_ID,
       MMC_ESTOP_DEVICE_ID
     };

//gps packet types
enum { MMC_GPS_ASCII };

//imu packet types
enum { MMC_IMU_RAW, 
       MMC_IMU_FILTERED, 
       MMC_IMU_ROT, 
       MMC_MAG_RAW,
       MMC_IMU_RESET
     };

//motor controller packet types
enum { MMC_MOTOR_CONTROLLER_ENCODERS_REQUEST,
       MMC_MOTOR_CONTROLLER_ENCODERS_RESPONSE,
       MMC_MOTOR_CONTROLLER_VELOCITY_SETTING,
       MMC_MOTOR_CONTROLLER_VELOCITY_CONFIRMATION
     };
     
//rc packet types
enum { MMC_RC_RAW,
       MMC_RC_DECODED
     };

//estop packet types
enum { MMC_ESTOP_STATE
     };


#endif //MAGIC_MIRCO_COM_H

