/* Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use. */
#ifndef JOYSTICK_HH
#define JOYSTICK_HH

#include <termios.h>
#include <fcntl.h>
#include <stdio.h>
#include <linux/input.h>
#include <string>
#include "SerialDevice.hh"

using namespace std;

class Joystick
{
  public: Joystick();
  public: ~Joystick();
  public: int Connect(string dev);
  public: int Disconnect();
  public: int Read(input_event * ev, double timeoutSec);
  
  private: bool connected;
  private: SerialDevice * sd;
};

#endif //JOYSTICK_HH
