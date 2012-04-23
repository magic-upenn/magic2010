#ifndef __UART2_H
#define __UART2_H

#include <stdio.h>
#include <stdint.h>
#include "kBotPacket.h"

void    uart2_init(void);
int32_t uart2_setbaud(int32_t baud);
int32_t uart2_getchar();
int32_t uart2_putchar(char c);
int32_t uart2_putstr(char *str);
int32_t uart2_printf(char *fmt, ...);
int32_t uart2_putdata(char *data, int32_t size);
int32_t uart2_putdpacket(kBotPacket * dpacket);
int32_t uart2_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size);

#endif // __UART2_H

