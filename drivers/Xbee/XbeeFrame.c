#include "XbeeFrame.h"

void XbeeFrameInit(XbeeFrame * frame)
{
  frame->lenReceived = 0;
  frame->lenExpected = 0;
  frame->bp          = 0;
}


uint8_t XbeeFrameChecksum(uint8_t * data, uint16_t size)
{
  uint8_t sum = 0;
  uint16_t ii;
  
  for (ii=0; ii <size; ii++)
    sum += *data++;
  sum = 0xFF - sum;

  return sum;
}

uint8_t XbeeFrameGetApiId(XbeeFrame * frame)
{
  return frame->buffer[XBEE_FRAME_OFFSET_API_IDENTIFIER];
}

int16_t XbeeFrameProcessChar(uint8_t c, XbeeFrame * frame)
{
  int16_t ret = 0;
  uint8_t checksum;

  switch (frame->lenReceived)
  {
    case 0:
      frame->bp = frame->buffer;    //reset the pointer for storing data

      if (c == XBEE_FRAME_START_DELIMETER)
      {
        *(frame->bp)++ = c;
        frame->lenReceived++;
      }
      else
        frame->lenReceived = 0;
      break;

    case 1:
      *(frame->bp)++ = c;  //do nothing, just store the MSB of the length
      frame->lenReceived++;  
      break;     
    
    case 2:
      *(frame->bp)++ = c;
      frame->lenReceived++;
      frame->lenExpected = (frame->buffer[1]<<8) + frame->buffer[2] + 4;

      if (frame->lenExpected < XBEE_FRAME_MIN_SIZE ||
          frame->lenExpected > XBEE_FRAME_MAX_SIZE )
      {
        frame->lenReceived = 0;
        ret = -1;
      }
      break;

    default:
      *(frame->bp)++ = c;
      frame->lenReceived++;

      if (frame->lenReceived < frame->lenExpected)
        break;  // have not received enough yet

      //calculate the checksum
      checksum = XbeeFrameChecksum(frame->buffer+3,
                              frame->lenReceived-4);

      if (checksum == c)
        ret = frame->lenReceived;

      frame->lenReceived = 0;
  }

  return ret;
}

