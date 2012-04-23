#include "uart5.h"
#include "stm32f10x_rcc.h"
#include "stm32f10x_gpio.h"
#include "stm32f10x_usart.h"
#include <stdarg.h>
#include "CBUF.h"
#include "common.h"
#include "config.h"
#include "misc.h"


#define USART5_TX_PORT      GPIOC
#define USART5_RX_PORT      GPIOD
#define USART5_TX_GPIO_CLK  RCC_APB2Periph_GPIOC
#define USART5_RX_GPIO_CLK  RCC_APB2Periph_GPIOD
#define USART5_TX_PIN       GPIO_Pin_12
#define USART5_RX_PIN       GPIO_Pin_2

#define DEFAULT_BAUDRATE    57600

#define uart5_getbuf_SIZE   UART5_GETBUF_SIZE
#define uart5_putbuf_SIZE   UART5_PUTBUF_SIZE
#define UART5_TEMPBUF_SIZE  UART5_PUTBUF_SIZE

#define UART5_PRINTF_BUF_LEN 100

//bit locations for interrupt and status flags
#define RXNEIE5 5
#define TCIE5   6
#define TXEIE5  7
#define RXNE5   5
#define TC5     6
#define TXE5    7
#define ORE5    3

volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart5_getbuf_SIZE ];
} uart5_getbuf;
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart5_putbuf_SIZE ];
} uart5_putbuf;

uint8_t uart5_tempbuf[UART5_TEMPBUF_SIZE];

void uart5_init(void)
{
  CBUF_Init(uart5_getbuf);
  CBUF_Init(uart5_putbuf);

  //use the stm32 lib to initialize the UART (does not have to be fast)
  GPIO_InitTypeDef GPIO_InitStructure;
  NVIC_InitTypeDef NVIC_InitStructure;

  //enable the IO clock for the ports and uart hardware
  RCC_APB2PeriphClockCmd(USART5_TX_GPIO_CLK | USART5_RX_GPIO_CLK, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_UART5, ENABLE);
  
  // Configure USART Tx as alternate function push-pull
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Pin   = USART5_TX_PIN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(USART5_TX_PORT, &GPIO_InitStructure);


  // Configure USART Rx as input with a pull-up
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU; //GPIO_Mode_IN_FLOATING;
  GPIO_InitStructure.GPIO_Pin  = USART5_RX_PIN;
  GPIO_Init(USART5_RX_PORT, &GPIO_InitStructure);

  uart5_setbaud(DEFAULT_BAUDRATE);

  //enable RX interrupt
  UART5->CR1 |= _BV(RXNEIE5);

  // Enable the USART1 Interrupt
  NVIC_InitStructure.NVIC_IRQChannel            = UART5_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = UART5_PRIORITY;
  NVIC_InitStructure.NVIC_IRQChannelCmd         = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}


int32_t uart5_setbaud(int32_t baud)
{
  //use the stm32 lib to initialize the UART (does not have to be fast)
  USART_InitTypeDef USART_InitStructure;
  USART_InitStructure.USART_BaudRate            = baud;
  USART_InitStructure.USART_WordLength          = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits            = USART_StopBits_1;
  USART_InitStructure.USART_Parity              = USART_Parity_No;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode                = USART_Mode_Rx | USART_Mode_Tx;

  USART_Init(UART5,&USART_InitStructure);
  USART_Cmd(UART5, ENABLE);
}


void UART5_IRQHandler(void)
{
  char c;

  //figure out which flag triggered the interrupt
  uint32_t status = UART5->SR;

  if (status & _BV(RXNE5))                    //received a byte
  {
    c = UART5->DR;
    CBUF_Push(uart5_getbuf, c);
  }
  else if (status & _BV(ORE5))               //this is a weird condition when another byte came in
    c = UART5->DR;                           //at exact moment of reading DR, causing ORE, but not RXNE

  if (status & _BV(TXE5))                    //transmit buffer is empty
  {
    if (!CBUF_IsEmpty(uart5_putbuf)) 
      UART5->DR = CBUF_Pop(uart5_putbuf);   //push next character
    else 
      UART5->CR1 &= ~(_BV(TXEIE5));         // Disable interrupt
  }
}


int32_t uart5_getchar()
{
  return ( CBUF_IsEmpty(uart5_getbuf) ? EOF : CBUF_Pop(uart5_getbuf) );
}


int32_t uart5_putchar(char c)
{
  CBUF_Push(uart5_putbuf, c);               //push the byte into circular buffer
  
  UART5->CR1 |= _BV(TXEIE5);               //re-enable interrupt (or just enable)
  
  return c;
}


int32_t uart5_putstr(char *str)
{
  char * str2 = str;
  while(*str != 0)
    CBUF_Push(uart5_putbuf, *str++);

  UART5->CR1 |= _BV(TXEIE5);               //re-enable interrupt (or just enable)
  return (str-str2);
}


int32_t uart5_printf(char *fmt, ...)
{
  va_list args;
  int tmp;
  char buffer[UART5_PRINTF_BUF_LEN];
  va_start(args,fmt);
#ifdef UART5_PRINTF_USE_FLOAT
  tmp=vsnprintf(buffer, UART5_PRINTF_BUF_LEN, fmt, args);
#else
  tmp=vsniprintf(buffer, UART5_PRINTF_BUF_LEN, fmt, args);
#endif
  va_end(args);
  uart5_putstr(buffer);
  return tmp;
}


int32_t uart5_putdata(char *data, int32_t size)
{
  int32_t size2 = size;
  while(size--)
    CBUF_Push(uart5_putbuf, *data++);

  UART5->CR1 |= _BV(TXEIE5);              //re-enable interrupt (or just enable)
    
  return size2;
}

int32_t uart5_putdpacket(kBotPacket * dpacket)
{
  int32_t ret = uart5_putdata((char*)dpacket->buffer, dpacket->lenExpected);
  return ret;
}

int32_t uart5_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size)
{
  int32_t len = kBotPacketWrapData(id,type,data,size,
                           uart5_tempbuf,UART5_TEMPBUF_SIZE);

  if (len > 0) uart5_putdata((char*)uart5_tempbuf,len);

  return len;
}

