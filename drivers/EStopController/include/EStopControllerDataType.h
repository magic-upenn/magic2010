#ifndef E_STOP_CONTROLLER_DATA_TYPES_H
#define E_STOP_CONTROLLER_DATA_TYPES_H

#include <string.h>


typedef struct EStopController {
        //remote and on-board estops
//        uint8_t vscEStop, srcEStop;

        //joystick
        int leftX, leftY, leftZ;
        int rightX, rightY, rightZ;

        //buttons
        uint8_t bD, bR, bU, bL;
        uint8_t b1, b2, b3, b4;

#define EStopController_IPC_FORMAT "{int,int,int,int,int,int,ubyte,ubyte,ubyte,ubyte,ubyte,ubyte,ubyte,ubyte}"
        
#ifdef MEX_IPC_SERIALIZATION
        INSERT_SERIALIZATION_DECLARATIONS
#endif
} EStopController;

#endif //E_STOP_CONTROLLER_DATA_TYPES_H
