#ifndef XBEE_FRAME_H
#define XBEE_FRAME_H

#include <stdint.h>

#define XBEE_FRAME_MAX_SIZE 250
#define XBEE_FRAME_MIN_SIZE 10
#define XBEE_FRAME_START_DELIMETER 0x7E
#define XBEE_FRAME_OFFSET_LENGTH 1
#define XBEE_FRAME_OFFSET_API_IDENTIFIER 3
#define XBEE_FRAME_OFFSET_PAYLOAD 8
#define XBEE_FRAME_RX_OVERHEAD 9

typedef struct
{
  uint16_t lenReceived;
  uint16_t lenExpected;
  uint8_t * bp;
  uint8_t buffer[XBEE_FRAME_MAX_SIZE];
} XbeeFrame;

void XbeeFrameInit(XbeeFrame * frame);
int16_t  XbeeFrameProcessChar(uint8_t c, XbeeFrame * frame);
uint8_t  XbeeFrameChecksum(uint8_t * data, uint16_t size);
uint8_t  XbeeFrameGetApiId(XbeeFrame * frame);

#endif //XBEE_FRAME_H

