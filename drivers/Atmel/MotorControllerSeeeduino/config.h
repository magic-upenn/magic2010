#ifndef CONFIG_H
#define CONFIG_H

//communications with host
#include "uart0.h"
#define HOST_BAUD_RATE 1000000
#define HOST_COM_PORT_INIT    uart0_init
#define HOST_COM_PORT_SETBAUD uart0_setbaud
#define HOST_COM_PORT_GETCHAR uart0_getchar
#define HOST_COM_PORT_PUTCHAR uart0_putchar
#define HOST_COM_PORT_PUTSTR  uart0_putstr

//pin for flushing the usb buffer to host
#define USB_FLUSH_DDR DDRA
#define USB_FLUSH_PORT PORTA
#define USB_FLUSH_PIN PINA7


//dynamixel bus
#include "rs485.h"
#define RS485_TX_ENABLE_PORT PORTG
#define RS485_TX_ENABLE_PIN PORTG5
#define RS485_TX_ENABLE_DDR DDRG
#define BUS_BAUD_RATE 115200
#define BUS_COM_PORT_INIT    rs485_init
#define BUS_COM_PORT_SETBAUD rs485_setbaud
#define BUS_COM_PORT_GETCHAR rs485_getchar
#define BUS_COM_PORT_PUTCHAR rs485_putchar 

#endif //CONFIG_H
