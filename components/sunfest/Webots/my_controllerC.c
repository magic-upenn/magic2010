/*
 * File:         
 * Date:         
 * Description:  
 * Author:       
 * Modifications:
 */

/*
 * You may need to add include files like <webots/distance_sensor.h> or
 * <webots/differential_wheels.h>, etc.
 */
#include <webots/robot.h>
#include <webots/servo.h>

/*
 * You may want to add defines macro here.
 */
#define TIME_STEP 64
#define SPEED 5

/*
 * You should put some helper functions here
 */

/*
 * This is the main program.
 * The arguments of the main function can be specified by the
 * "controllerArgs" field of the Robot node
 */
int main(int argc, char **argv)
{
  /* necessary to initialize webots stuff */
  wb_robot_init();
  int new_key, left_speed = 0, right_speed = 0;
  wb_robot_keyboard_enable(TIME_STEP);
  /*
   * You should declare here DeviceTag variables for storing
   * robot devices like this:
   *  WbDeviceTag my_actuator = wb_robot_get_device("my_actuator");
   */
  WbDeviceTag front_right_wheel = wb_robot_get_device("front right wheel");
  WbDeviceTag front_left_wheel = wb_robot_get_device("front left wheel");
  WbDeviceTag back_right_wheel = wb_robot_get_device("back right wheel");
  WbDeviceTag back_left_wheel = wb_robot_get_device("back left wheel");
  //WbDeviceTag servoH = wb_robot_get_device("servoH");
  //WbDeviceTag servoV = wb_robot_get_device("servoV");
  //wb_servo_set_velocity(servoH, 2);
  //wb_servo_set_velocity(servoV, 2);
  
  //wb_servo_enable_position(front_right_wheel, TIME_STEP);
  //wb_servo_disable_position(servo);

  
  /* main loop */
  do {
    
   new_key = wb_robot_keyboard_get_key();
    
    switch (new_key) {
      case WB_ROBOT_KEYBOARD_LEFT:
        left_speed = 0;
        right_speed = SPEED;
        wb_servo_set_position(front_right_wheel, -INFINITY);
        wb_servo_set_position(back_right_wheel, -INFINITY);
        //wb_servo_set_position(servoH, -1);
        break;
      case WB_ROBOT_KEYBOARD_RIGHT:
        left_speed = SPEED;
        right_speed = 0;
        wb_servo_set_position(front_left_wheel, -INFINITY);
        wb_servo_set_position(back_left_wheel, -INFINITY);
        //wb_servo_set_position(servoH, 1);
        break;
      case WB_ROBOT_KEYBOARD_UP:
        left_speed = SPEED;
        right_speed = SPEED;
        wb_servo_set_position(front_right_wheel, -INFINITY);
        wb_servo_set_position(back_right_wheel, -INFINITY);
        wb_servo_set_position(front_left_wheel, -INFINITY);
        wb_servo_set_position(back_left_wheel, -INFINITY);
        //wb_servo_set_position(servoV, 1);
        break;
      case WB_ROBOT_KEYBOARD_DOWN:
        left_speed = SPEED;
        right_speed = SPEED;
        wb_servo_set_position(front_right_wheel, INFINITY);
        wb_servo_set_position(back_right_wheel, INFINITY);
        wb_servo_set_position(front_left_wheel, INFINITY);
        wb_servo_set_position(back_left_wheel, INFINITY);
        //wb_servo_set_position(servoV, -1);
        break;
    }
    
    wb_servo_set_velocity(front_right_wheel, right_speed);
    wb_servo_set_velocity(back_right_wheel, right_speed);
    wb_servo_set_velocity(front_left_wheel, left_speed);
    wb_servo_set_velocity(back_left_wheel, left_speed);
    
    //wb_differential_wheels_set_speed(left_speed, right_speed);

    /* 
     * Read the sensors :
     * Enter here functions to read sensor data, like:
     *  double val = wb_distance_sensor_get_value(my_sensor);
     */
    
    /* Process sensor data here */
    
    /*
     * Enter here functions to send actuator commands, like:
     * wb_differential_wheels_set_speed(100.0,100.0);
     */
    
    /* 
     * Perform a simulation step of 64 milliseconds
     * and leave the loop when the simulation is over
     */
  } while (wb_robot_step(TIME_STEP) != -1);
  
  /* Enter here exit cleanup code */
  
  /* Necessary to cleanup webots stuff */
  wb_robot_cleanup();
  
  return 0;
}
