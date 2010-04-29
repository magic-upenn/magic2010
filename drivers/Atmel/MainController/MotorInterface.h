#ifndef MOTOR_INTERFACE_H
#define MOTOR_INTERFACE_H

#define MOTOR_INTERFACE_BAUD_RATE 1000000

int MotorsInit();

//read off data from the circular buffer and see
//whether a complete packet came in.
int MotorsReceiveEncoderData(uint8_t ** buf);

int MotorsSendControls(float v, float w);

#endif //MOTOR_INTERFACE_H
