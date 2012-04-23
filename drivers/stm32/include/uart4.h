#ifndef __UART4_H
#define __UART4_H

#include <stdio.h>
#include <stdint.h>
#include "kBotPacket.h"

void    uart4_init(void);
int32_t uart4_setbaud(int32_t baud);
int32_t uart4_getchar();
int32_t uart4_putchar(char c);
int32_t uart4_putstr(char *str);
int32_t uart4_printf(char *fmt, ...);
int32_t uart4_putdata(char *data, int32_t size);
int32_t uart4_putdpacket(kBotPacket * dpacket);
int32_t uart4_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size);

#endif // __UART4_H

