#include "uart4.h"
#include "stm32f10x_rcc.h"
#include "stm32f10x_gpio.h"
#include "stm32f10x_usart.h"
#include <stdarg.h>
#include "CBUF.h"
#include "common.h"
#include "config.h"
#include "misc.h"


#define USART4_TX_PORT      GPIOC
#define USART4_RX_PORT      GPIOC
#define USART4_TX_GPIO_CLK  RCC_APB2Periph_GPIOC
#define USART4_RX_GPIO_CLK  RCC_APB2Periph_GPIOC
#define USART4_TX_PIN       GPIO_Pin_10
#define USART4_RX_PIN       GPIO_Pin_11

#define DEFAULT_BAUDRATE    57600

#define uart4_getbuf_SIZE   UART4_GETBUF_SIZE
#define uart4_putbuf_SIZE   UART4_PUTBUF_SIZE
#define UART4_TEMPBUF_SIZE  UART4_PUTBUF_SIZE

#define UART4_PRINTF_BUF_LEN 100

//bit locations for interrupt and status flags
#define RXNEIE4 5
#define TCIE4   6
#define TXEIE4  7
#define RXNE4   5
#define TC4     6
#define TXE4    7
#define ORE4    3

volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart4_getbuf_SIZE ];
} uart4_getbuf;
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart4_putbuf_SIZE ];
} uart4_putbuf;

uint8_t uart4_tempbuf[UART4_TEMPBUF_SIZE];

void uart4_init(void)
{
  CBUF_Init(uart4_getbuf);
  CBUF_Init(uart4_putbuf);

  //use the stm32 lib to initialize the UART (does not have to be fast)
  GPIO_InitTypeDef GPIO_InitStructure;
  NVIC_InitTypeDef NVIC_InitStructure;

  //enable the IO clock for the ports and uart hardware
  RCC_APB2PeriphClockCmd(USART4_TX_GPIO_CLK | USART4_RX_GPIO_CLK, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_UART4, ENABLE);
  
  // Configure USART Tx as alternate function push-pull
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Pin   = USART4_TX_PIN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(USART4_TX_PORT, &GPIO_InitStructure);


  // Configure USART Rx as input with a pull-up
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU; //GPIO_Mode_IN_FLOATING;
  GPIO_InitStructure.GPIO_Pin  = USART4_RX_PIN;
  GPIO_Init(USART4_RX_PORT, &GPIO_InitStructure);

  uart4_setbaud(DEFAULT_BAUDRATE);

  //enable RX interrupt
  UART4->CR1 |= _BV(RXNEIE4);

  // Enable the USART1 Interrupt
  NVIC_InitStructure.NVIC_IRQChannel            = UART4_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = UART4_PRIORITY;
  NVIC_InitStructure.NVIC_IRQChannelCmd         = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}


int32_t uart4_setbaud(int32_t baud)
{
  //use the stm32 lib to initialize the UART (does not have to be fast)
  USART_InitTypeDef USART_InitStructure;
  USART_InitStructure.USART_BaudRate            = baud;
  USART_InitStructure.USART_WordLength          = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits            = USART_StopBits_1;
  USART_InitStructure.USART_Parity              = USART_Parity_No;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode                = USART_Mode_Rx | USART_Mode_Tx;

  USART_Init(UART4,&USART_InitStructure);
  USART_Cmd(UART4, ENABLE);
}


void UART4_IRQHandler(void)
{
  char c;

  //figure out which flag triggered the interrupt
  uint32_t status = UART4->SR;

  if (status & _BV(RXNE4))                    //received a byte
  {
    c = UART4->DR;
    CBUF_Push(uart4_getbuf, c);
  }
  else if (status & _BV(ORE4))               //this is a weird condition when another byte came in
    c = UART4->DR;                           //at exact moment of reading DR, causing ORE, but not RXNE

  if (status & _BV(TXE4))                    //transmit buffer is empty
  {
    if (!CBUF_IsEmpty(uart4_putbuf)) 
      UART4->DR = CBUF_Pop(uart4_putbuf);   //push next character
    else 
      UART4->CR1 &= ~(_BV(TXEIE4));         // Disable interrupt
  }
}


int32_t uart4_getchar()
{
  return ( CBUF_IsEmpty(uart4_getbuf) ? EOF : CBUF_Pop(uart4_getbuf) );
}


int32_t uart4_putchar(char c)
{
  CBUF_Push(uart4_putbuf, c);               //push the byte into circular buffer
  
  UART4->CR1 |= _BV(TXEIE4);               //re-enable interrupt (or just enable)
  
  return c;
}


int32_t uart4_putstr(char *str)
{
  char * str2 = str;
  while(*str != 0)
    CBUF_Push(uart4_putbuf, *str++);

  UART4->CR1 |= _BV(TXEIE4);               //re-enable interrupt (or just enable)
  return (str-str2);
}


int32_t uart4_printf(char *fmt, ...)
{
  va_list args;
  int tmp;
  char buffer[UART4_PRINTF_BUF_LEN];
  va_start(args,fmt);
#ifdef UART4_PRINTF_USE_FLOAT
  tmp=vsnprintf(buffer, UART4_PRINTF_BUF_LEN, fmt, args);
#else
  tmp=vsniprintf(buffer, UART4_PRINTF_BUF_LEN, fmt, args);
#endif
  va_end(args);
  uart4_putstr(buffer);
  return tmp;
}


int32_t uart4_putdata(char *data, int32_t size)
{
  int32_t size2 = size;
  while(size--)
    CBUF_Push(uart4_putbuf, *data++);

  UART4->CR1 |= _BV(TXEIE4);              //re-enable interrupt (or just enable)
    
  return size2;
}

int32_t uart4_putdpacket(kBotPacket * dpacket)
{
  int32_t ret = uart4_putdata((char*)dpacket->buffer, dpacket->lenExpected);
  return ret;
}

int32_t uart4_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size)
{
  int32_t len = kBotPacketWrapData(id,type,data,size,
                           uart4_tempbuf,UART4_TEMPBUF_SIZE);

  if (len > 0) uart4_putdata((char*)uart4_tempbuf,len);

  return len;
}

