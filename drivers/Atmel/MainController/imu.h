#ifndef ATTITUDE_FILTER_H
#define ATTITUDE_FILTER_H

#define ADC_VOLTAGE_MV 2560.0

//accelerometer biases
//#define BIAS_ACC_X 665
//#define BIAS_ACC_Y 671
//#define BIAS_ACC_Z 670

#define NOMINAL_GYRO_BIAS 485
#define GYRO_BIAS_MARGIN 30

#define MAX_GYRO_CALIB_NOSE 20

//accelerometer sensitivities (g/bit)
#define SENS_ACC_X 1.0/139.0
#define SENS_ACC_Y 1.0/139.0
#define SENS_ACC_Z 1.0/133.0

//rate gyro bias (rad/mV)
#define SENS_GYRO_X M_PI/180.0/3.5
#define SENS_GYRO_Y M_PI/180.0/3.5
#define SENS_GYRO_Z M_PI/180.0/3.5


//number of calibration samples for rate gyros
#define NUM_GYRO_CALIB_SAMPLES 100

//mapping of the ADC measurements to appropriate values
#define ADC_AX_IND 0
#define ADC_AY_IND 1
#define ADC_AZ_IND 2
#define ADC_WX_IND 5
#define ADC_WY_IND 4
#define ADC_WZ_IND 3


int ProcessImuReadings(uint16_t * adcVals, float * rpy, float *wrpy);
int SetImuBiases(uint16_t biasax, uint16_t biasay, uint16_t biasaz,
                 uint16_t biaswx, uint16_t biaswy, uint16_t biaswz);

int SetImuSensitivities(float accSenX, float accSenY, float accSenZ,
                        float gyroSenX, float gyroSenY, float gyroSenZ);

void ResetImu();

#endif //ATTITUDE_FILTER_H
