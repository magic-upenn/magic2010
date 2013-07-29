/* Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use. */
#include "Joystick.hh"

using namespace std;

Joystick::Joystick()
{
  this->connected = false;
  this->sd       = NULL;
}

Joystick::~Joystick()
{
  this->Disconnect();
  if (this->sd) delete this->sd;
}

int Joystick::Connect(string dev)
{
  if (this->connected)
  {
    printf("already connected\n");
    return -1;
  }

  this->sd = new SerialDevice();
  if (this->sd->Connect(dev.c_str()))
  {
    printf("Unable to connect\n");
    return -1;
  }
  
  this->connected = true;
  return 0;
}

int Joystick::Disconnect()
{
  if (!this->connected)
    return 0;

  this->sd->Disconnect();
  this->connected = false;
  return 0;
}

int Joystick::Read(input_event * ev, double timeoutSec)
{
  if (!this->connected)
  {
    printf("not connected\n");
    return -1;
  }

  int num = this->sd->ReadChars((char*)ev,sizeof(input_event),(int)(timeoutSec*1000000));
  if (num>0)
  {
    if (0)
    {
      printf("Event: time %ld.%06ld, type %d, code %d, value %d\n",
			         ev->time.tv_sec, ev->time.tv_usec, ev->type,
			         ev->code, ev->value);
    }
    return 0;
  }

  return -1;
}

