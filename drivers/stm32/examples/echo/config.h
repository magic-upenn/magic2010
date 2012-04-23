#ifndef CONFIG_H
#define CONFIG_H

#define _BV(x) (1<<x)

#define HL_BAUD_RATE         115200
#define HL_COM_PORT_INIT     uart1_init
#define HL_COM_PORT_SETBAUD  uart1_setbaud
#define HL_COM_PORT_GETCHAR  uart1_getchar
#define HL_COM_PORT_PUTCHAR  uart1_putchar
#define HL_COM_PORT_PUTSTR   uart1_putstr
#define HL_COM_PORT_PRINTF   uart1_printf
#define HL_COM_PORT_PUTDATA  uart1_putdata

#define UART1_GETBUF_SIZE 256
#define UART1_PUTBUF_SIZE 256
#define UART1_PRIORITY 0

#define UART2_GETBUF_SIZE 256
#define UART2_PUTBUF_SIZE 256
#define UART2_PRIORITY 0

#define UART3_GETBUF_SIZE 256
#define UART3_PUTBUF_SIZE 256
#define UART3_PRIORITY 0

//uncomment #define UART1_PRINTF_USE_FLOAT if want to print floats
//otherwise keep it off to reduce code size
//#define UART1_PRINTF_USE_FLOAT
//#define UART2_PRINTF_USE_FLOAT
//#define UART3_PRINTF_USE_FLOAT

#endif //CONFIG_H

