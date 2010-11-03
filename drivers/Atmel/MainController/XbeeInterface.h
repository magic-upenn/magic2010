#ifndef XBEE_INTERFACE_H
#define XBEE_INTERFACE_H

#include <stdint.h>
#include "DynamixelPacket.h"
#include "config.h"

int XbeeInit();
int XbeeReceivePacket(DynamixelPacket * packet);
int XbeeSendPacket(uint8_t id, uint8_t type, uint8_t * buf, uint8_t size);
int XbeeSendRawPacket(DynamixelPacket * packet);

#endif //XBEE_INTERFACE_H