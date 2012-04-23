#ifndef __RS485_H
#define __RS485_H

#include <stdio.h>
#include <stdint.h>
#include "kBotPacket.h"

void    rs485_init(void);
int32_t rs485_setbaud(int32_t baud);
int32_t rs485_getchar();
int32_t rs485_putchar(char c);
int32_t rs485_putstr(char *str);
int32_t rs485_printf(char *fmt, ...);
int32_t rs485_putdata(char *data, int32_t size);
int32_t rs485_putdpacket(kBotPacket * dpacket);
int32_t rs485_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size);

#endif // __RS485_H

