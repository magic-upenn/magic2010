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

//for seeeduino mega
#define USB_FLUSH_DDR DDRA
#define USB_FLUSH_PORT PORTA
#define USB_FLUSH_PIN PINA7

//for arduino mega:
//#define USB_FLUSH_DDR DDRB
//#define USB_FLUSH_PORT PORTB
//#define USB_FLUSH_PIN PINB1


//dynamixel bus
#include "rs485.h"

//for seeeduino mega
#define RS485_TX_ENABLE_PORT PORTH
#define RS485_TX_ENABLE_PIN PORTH5
#define RS485_TX_ENABLE_DDR DDRH

//for arduino mega
//#define RS485_TX_ENABLE_PORT PORTB
//#define RS485_TX_ENABLE_PIN PORTB0
//#define RS485_TX_ENABLE_DDR DDRB


#define BUS_BAUD_RATE 115200
#define BUS_COM_PORT_INIT    rs485_init
#define BUS_COM_PORT_SETBAUD rs485_setbaud
#define BUS_COM_PORT_GETCHAR rs485_getchar
#define BUS_COM_PORT_PUTCHAR rs485_putchar 

//gps
#include "uart2.h"
#define GPS_BAUD_RATE 4800
#define GPS_COM_PORT_INIT uart2_init
#define GPS_COM_PORT_SETBAUD uart2_setbaud
#define GPS_COM_PORT_GETCHAR uart2_getchar

//debug interface
#include "uart3.h"
#define DEBUG_BAUD_RATE 115200
#define DEBUG_COM_PORT_INIT    uart3_init
#define DEBUG_COM_PORT_SETBAUD uart3_setbaud
#define DEBUG_COM_PORT_GETCHAR uart3_getchar
#define DEBUG_COM_PORT_PUTCHAR uart3_putchar 
#define DEBUG_COM_PORT_PUTSTR  uart3_putstr



//LEDs
#define LED_ERROR_PIN   PH4
#define LED_ERROR_PORT  PORTH
#define LED_ERROR_DDR   DDRH
#define LED_ERROR_PINN  PINH

#define LED_PC_ACT_PIN  PH3
#define LED_PC_ACT_PORT PORTH
#define LED_PC_ACT_DDR  DDRH
#define LED_PC_ACT_PINN PINH

#define LED_ESTOP_PIN   PE3
#define LED_ESTOP_PORT  PORTE
#define LED_ESTOP_DDR   DDRE
#define LED_ESTOP_PINN  PINE

#define LED_GPS_PIN     PG5
#define LED_GPS_PORT    PORTG
#define LED_GPS_DDR     DDRG
#define LED_GPS_PINN    PING

#define LED_RC_PIN      PE5
#define LED_RC_PORT     PORTE
#define LED_RC_DDR      DDRE
#define LED_RC_PINN     PINE



#define TOGGLE_LED_ERROR   LED_ERROR_PINN  |= _BV(LED_ERROR_PIN)
#define TOGGLE_LED_PC_ACT  LED_PC_ACT_PINN |= _BV(LED_PC_ACT_PIN)
#define TOGGLE_LED_ESTOP   LED_ESTOP_PINN  |= _BV(LED_ESTOP_PIN)
#define TOGGLE_LED_GPS     LED_GPS_PINN    |= _BV(LED_GPS_PIN)
#define TOGGLE_LED_RC      LED_RC_PINN     |= _BV(LED_RC_PIN)

//index of each control in the array of RC channels
#define RC_V_IND 2
#define RC_W_IND 1

#define RC_V_BIAS 512
#define RC_W_BIAS 512

#define RC_V_RANGE 230
#define RC_W_RANGE 230

#endif //CONFIG_H
