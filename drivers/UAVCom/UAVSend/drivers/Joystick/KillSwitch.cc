/* Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use. */
#include "Joystick.hh"
#include "ipc.h"

using namespace std;

int main(int argc, char * argv[])
{
  Joystick * joy;
  
  
  char * dev = (char*)"/dev/powermate";
  
  if (argc > 1)
    dev = argv[1];

  joy = new Joystick();
  
  if (joy->Connect(dev))
  {
    printf("could not open device\n");
    delete joy;
    return -1;
  }
  
  char * killMsgName = (char*)"KillSwitch";
  char * startMsgName = (char*)"StartSwitch";
  
  
  IPC_connectModule("KillSwitch","localhost");
  IPC_defineMsg(killMsgName,IPC_VARIABLE_LENGTH,NULL);
  IPC_defineMsg(startMsgName,IPC_VARIABLE_LENGTH,NULL);

  input_event ev;
  double timeoutSec = 1.0;

  while(1)
  {
    if (joy->Read(&ev,timeoutSec) == 0)
    {
      if ((ev.type == 1) && (ev.code == 256) && (ev.value == 1))
      {
        int switchState = 1;
        IPC_publish(killMsgName,sizeof(int),&switchState);
        printf("[%f] Published kill messaged\n",Timer::GetUnixTime());
      }
      else if ((ev.type == 2) && (ev.code == 7))
      {
	int switchState = 1;
        IPC_publish(startMsgName,sizeof(int),&switchState);
        printf("[%f] Published start message \n",Timer::GetUnixTime());
      }
    }
    //usleep(10000);
  }


  joy->Disconnect();
  delete joy;
  return 0;
}
