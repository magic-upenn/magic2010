#ifndef __UART5_H
#define __UART5_H

#include <stdio.h>
#include <stdint.h>
#include "kBotPacket.h"

void    uart5_init(void);
int32_t uart5_setbaud(int32_t baud);
int32_t uart5_getchar();
int32_t uart5_putchar(char c);
int32_t uart5_putstr(char *str);
int32_t uart5_printf(char *fmt, ...);
int32_t uart5_putdata(char *data, int32_t size);
int32_t uart5_putdpacket(kBotPacket * dpacket);
int32_t uart5_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size);

#endif // __UART5_H

