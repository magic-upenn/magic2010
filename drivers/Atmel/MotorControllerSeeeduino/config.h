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
#define BUS_BAUD_RATE 1000000
#define BUS_COM_PORT_INIT    rs485_init
#define BUS_COM_PORT_SETBAUD rs485_setbaud
#define BUS_COM_PORT_GETCHAR rs485_getchar
#define BUS_COM_PORT_PUTCHAR rs485_putchar


#include "uart3.h"
#define RC_BAUD_RATE 115200

#define ENCODER0_TRIGGER_PORT PIND
#define ENCODER1_TRIGGER_PORT PIND
#define ENCODER2_TRIGGER_PORT PINE
#define ENCODER3_TRIGGER_PORT PINE

#define ENCODER0_TRIGGER_PIN PD0
#define ENCODER1_TRIGGER_PIN PD1
#define ENCODER2_TRIGGER_PIN PE4
#define ENCODER3_TRIGGER_PIN PE5

#define ENCODER0_VALUE_PORT PINF
#define ENCODER1_VALUE_PORT PINF
#define ENCODER2_VALUE_PORT PINF
#define ENCODER3_VALUE_PORT PINF

#define ENCODER0_VALUE_PIN PF4
#define ENCODER1_VALUE_PIN PF5
#define ENCODER2_VALUE_PIN PF6
#define ENCODER3_VALUE_PIN PF7

#define ENCODER0_INT_vec INT0_vect
#define ENCODER1_INT_vec INT1_vect
#define ENCODER2_INT_vec INT4_vect
#define ENCODER3_INT_vec INT5_vect

#define STATUS_LED_PIN PB7
#define STATUS_LED_PORT PORTB
#define STATUS_LED_DDR DDRB
#define STATUS_LED_PINN PINB

#define ACT_LED_PIN PB6
#define ACT_LED_PORT PORTB
#define ACT_LED_DDR DDRB
#define ACT_LED_PINN PINB
#define TOGGLE_ACT_LED (ACT_LED_PINN |= _BV(ACT_LED_PIN))

#define MIN_V 5
#define MIN_W 5

//index of each control in the array of RC channels
#define RC_V_IND 2
#define RC_W_IND 1
#define RC_MODE_IND 5

enum {MODE_MANUAL,MODE_AUTONOMOUS};

#define RC_V_BIAS 512
#define RC_W_BIAS 512

#define RC_V_RANGE 230
#define RC_W_RANGE 230

#define RC_MODE_THRESH 600

#endif //CONFIG_H
