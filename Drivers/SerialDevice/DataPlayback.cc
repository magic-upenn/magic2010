#include "DataPlayback.hh"
#include "ErrorMessage.hh"

using namespace std;
using namespace Upenn;


DataPlayback::DataPlayback()
{
  this->lastReturnedTime  = -1.0;
  this->lastLogTime       = -1.0;
  this->playStartTime     = -1.0;
  this->logStartTime      = -1.0;
  this->logPausedTime     = 0.0;
  this->playOffset        = 0.0;
  this->fileOpen          = false;
  this->speed             = 1.0;
  this->dir               = 1;
}

DataPlayback::~DataPlayback()
{
}

int DataPlayback::SetPlaySpeed(double playSpeed)
{
  if (playSpeed < 0)
  {
    PRINT_ERROR("playback speed must be greater than zero. Trying to set it to "<<playSpeed<<"\n");
    return -1;
  }
  this->speed = playSpeed;
  return 0;
}

int DataPlayback::SetPlayDir(int playDir)
{
  if ( (playDir != 1) && (playDir != -1))
  {
    PRINT_ERROR("playback direction must be either 1 or -1. Trying to set it to "<<playDir<<"\n");
    return -1;
  }
  this->dir   = playDir;
  return 0;
}

int DataPlayback::SetPlayOffset(double offset)
{
  this->playOffset = offset;
  return 0;
}

