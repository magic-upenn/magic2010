#ifndef __UART1_H
#define __UART1_H

#include <stdio.h>
#include <stdint.h>
#include "kBotPacket.h"

void    uart1_init(void);
int32_t uart1_setbaud(int32_t baud);
int32_t uart1_getchar();
int32_t uart1_putchar(char c);
int32_t uart1_putstr(char *str);
int32_t uart1_printf(char *fmt, ...);
int32_t uart1_putdata(char *data, int32_t size);
int32_t uart1_putdpacket(kBotPacket * dpacket);
int32_t uart1_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size);

#endif // __UART1_H

