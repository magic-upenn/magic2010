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
#define RS485_TX_ENABLE_PIN PH5
#define RS485_TX_ENABLE_DDR DDRH

//for arduino mega
//#define RS485_TX_ENABLE_PORT PORTB
//#define RS485_TX_ENABLE_PIN PORTB0
//#define RS485_TX_ENABLE_DDR DDRB


#define BUS_BAUD_RATE 1000000
#define BUS_COM_PORT_INIT    rs485_init
#define BUS_COM_PORT_SETBAUD rs485_setbaud
#define BUS_COM_PORT_GETCHAR rs485_getchar
#define BUS_COM_PORT_PUTCHAR rs485_putchar 

//gps
#include "uart2.h"
#define GPS_BAUD_RATE 9600
#define GPS_COM_PORT_INIT uart2_init
#define GPS_COM_PORT_SETBAUD uart2_setbaud
#define GPS_COM_PORT_GETCHAR uart2_getchar

//debug interface
#include "uart3.h"
#define XBEE_BAUD_RATE 115200
#define XBEE_COM_PORT_INIT    uart3_init
#define XBEE_COM_PORT_SETBAUD uart3_setbaud
#define XBEE_COM_PORT_GETCHAR uart3_getchar
#define XBEE_COM_PORT_PUTCHAR uart3_putchar 
#define XBEE_COM_PORT_PUTSTR  uart3_putstr
#define XBEE_COM_PORT_PRINTF  uart3_printf


//Estop input
#define ESTOP_PORT       PINB
#define ESTOP_PIN        PINB4

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

#define LASER0_PIN      PE4
#define LASER0_PORT     PORTE
#define LASER0_DDR      DDRE



#define LED_ERROR_TOGGLE   LED_ERROR_PORT  ^= _BV(LED_ERROR_PIN)
#define LED_PC_ACT_TOGGLE  LED_PC_ACT_PORT ^= _BV(LED_PC_ACT_PIN)
#define LED_ESTOP_TOGGLE   LED_ESTOP_PORT  ^= _BV(LED_ESTOP_PIN)
#define LED_GPS_TOGGLE     LED_GPS_PORT    ^= _BV(LED_GPS_PIN)
#define LED_RC_TOGGLE      LED_RC_PORT     ^= _BV(LED_RC_PIN)


#define LED_ERROR_ON       LED_ERROR_PORT  |= _BV(LED_ERROR_PIN)
#define LED_ERROR_OFF      LED_ERROR_PORT  &= ~(_BV(LED_ERROR_PIN))
#define LED_ESTOP_ON       LED_ESTOP_PORT  |= _BV(LED_ESTOP_PIN)
#define LED_ESTOP_OFF      LED_ESTOP_PORT  &= ~(_BV(LED_ESTOP_PIN)) 
#define LASER0_ON          LASER0_PORT     |= _BV(LASER0_PIN)
#define LASER0_OFF         LASER0_PORT     &= ~(_BV(LASER0_PIN))


/*
#define LED_ERROR_TOGGLE   
#define LED_PC_ACT_TOGGLE  
#define LED_ESTOP_TOGGLE   
#define LED_GPS_TOGGLE     
#define LED_RC_TOGGLE      


#define LED_ERROR_ON       
#define LED_ERROR_OFF      
#define LED_ESTOP_ON       
#define LED_ESTOP_OFF       
*/

#define BUZZER_DDR DDRB
#define BUZZER_PORT PORTB
#define BUZZER_PIN  PB6
#define BUZZER_ON BUZZER_PORT |= _BV(BUZZER_PIN)
#define BUZZER_OFF BUZZER_PORT &= ~(_BV(BUZZER_PIN))

//index of each control in the array of RC channels
#define RC_V_IND 2
#define RC_W_IND 1

#define RC_V_BIAS 512
#define RC_W_BIAS 512

#define RC_V_RANGE 230
#define RC_W_RANGE 230

#include "timer5.h"
#define NUM_ADC_CHANNELS 7
#define ADC_TIMER_PERIOD_TICS 2500 //2500 = 100Hz with 1/64 prescaler
#define ADC_TIMER_RESET timer5_reset
#define ADC_TIMER_INIT timer5_init
#define ADC_TIMER_SET_COMPA_CALLBACK timer5_set_compa_callback
#define ADC_TIMER_COMPA timer5_compa

#endif //CONFIG_H
