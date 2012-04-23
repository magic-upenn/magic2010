#ifndef __UART3_H
#define __UART3_H

#include <stdio.h>
#include <stdint.h>
#include "kBotPacket.h"

void    uart3_init(void);
int32_t uart3_setbaud(int32_t baud);
int32_t uart3_getchar();
int32_t uart3_putchar(char c);
int32_t uart3_putstr(char *str);
int32_t uart3_printf(char *fmt, ...);
int32_t uart3_putdata(char *data, int32_t size);
int32_t uart3_putdpacket(kBotPacket * dpacket);
int32_t uart3_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size);

#endif // __UART3_H

