#include "uart3.h"
#include "stm32f10x_rcc.h"
#include "stm32f10x_gpio.h"
#include "stm32f10x_usart.h"
#include <stdarg.h>
#include "CBUF.h"
#include "common.h"
#include "config.h"
#include "misc.h"


#define USART3_TX_PORT      GPIOB
#define USART3_RX_PORT      GPIOB
#define USART3_TX_GPIO_CLK  RCC_APB2Periph_GPIOB
#define USART3_RX_GPIO_CLK  RCC_APB2Periph_GPIOB
#define USART3_TX_PIN       GPIO_Pin_10
#define USART3_RX_PIN       GPIO_Pin_11

#define DEFAULT_BAUDRATE 57600

#define uart3_getbuf_SIZE UART3_GETBUF_SIZE
#define uart3_putbuf_SIZE UART3_PUTBUF_SIZE
#define UART3_TEMPBUF_SIZE UART3_PUTBUF_SIZE

#define UART3_PRINTF_BUF_LEN 100

//bit locations for interrupt and status flags
#define RXNEIE3 5
#define TCIE3   6
#define TXEIE3  7
#define RXNE3   5
#define TC3     6
#define TXE3    7
#define ORE3    3

volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart3_getbuf_SIZE ];
} uart3_getbuf;
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart3_putbuf_SIZE ];
} uart3_putbuf;

uint8_t uart3_tempbuf[UART3_TEMPBUF_SIZE];

void uart3_init(void)
{
  CBUF_Init(uart3_getbuf);
  CBUF_Init(uart3_putbuf);

  //use the stm32 lib to initialize the UART (does not have to be fast)
  GPIO_InitTypeDef GPIO_InitStructure;
  NVIC_InitTypeDef NVIC_InitStructure;

  //enable the IO clock for the ports and uart hardware
  RCC_APB2PeriphClockCmd(USART3_TX_GPIO_CLK | USART3_RX_GPIO_CLK, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART3, ENABLE);
  
  // Configure USART Tx as alternate function push-pull
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Pin   = USART3_TX_PIN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(USART3_TX_PORT, &GPIO_InitStructure);


  // Configure USART Rx as input with a pull-up
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU; //GPIO_Mode_IN_FLOATING;
  GPIO_InitStructure.GPIO_Pin  = USART3_RX_PIN;
  GPIO_Init(USART3_RX_PORT, &GPIO_InitStructure);

  uart3_setbaud(DEFAULT_BAUDRATE);

  //enable RX interrupt
  USART3->CR1 |= _BV(RXNEIE3);

  // Enable the USART3 Interrupt
  NVIC_InitStructure.NVIC_IRQChannel            = USART3_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = UART3_PRIORITY;
  NVIC_InitStructure.NVIC_IRQChannelCmd         = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}


int32_t uart3_setbaud(int32_t baud)
{
  //use the stm32 lib to initialize the UART (does not have to be fast)
  USART_InitTypeDef USART_InitStructure;
  USART_InitStructure.USART_BaudRate            = baud;
  USART_InitStructure.USART_WordLength          = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits            = USART_StopBits_1;
  USART_InitStructure.USART_Parity              = USART_Parity_No;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode                = USART_Mode_Rx | USART_Mode_Tx;

  USART_Init(USART3,&USART_InitStructure);
  USART_Cmd(USART3, ENABLE);
}


void USART3_IRQHandler(void)
{
  char c;

  //figure out which flag triggered the interrupt
  uint32_t status = USART3->SR;

  if (status & _BV(RXNE3))                    //received a byte
  {
    c = USART3->DR;
    CBUF_Push(uart3_getbuf, c);
  }
  else if (status & _BV(ORE3))               //this is a weird condition when another byte came in
    c = USART3->DR;                           //at exact moment of reading DR, causing ORE, but not RXNE

  if (status & _BV(TXE3))                    //transmit buffer is empty
  {
    if (!CBUF_IsEmpty(uart3_putbuf)) 
      USART3->DR = CBUF_Pop(uart3_putbuf);   //push next character
    else 
      USART3->CR1 &= ~(_BV(TXEIE3));         // Disable interrupt
  }
}


int32_t uart3_getchar()
{
  return ( CBUF_IsEmpty(uart3_getbuf) ? EOF : CBUF_Pop(uart3_getbuf) );
}


int32_t uart3_putchar(char c)
{
  CBUF_Push(uart3_putbuf, c);               //push the byte into circular buffer
  
  USART3->CR1 |= _BV(TXEIE3);               //re-enable interrupt (or just enable)
  
  return c;
}


int32_t uart3_putstr(char *str)
{
  char * str2 = str;
  while(*str != 0)
    CBUF_Push(uart3_putbuf, *str++);

  USART3->CR1 |= _BV(TXEIE3);               //re-enable interrupt (or just enable)
  return (str-str2);
}


int32_t uart3_printf(char *fmt, ...)
{
  va_list args;
  int tmp;
  char buffer[UART3_PRINTF_BUF_LEN];
  va_start(args,fmt);
#ifdef UART3_PRINTF_USE_FLOAT
  tmp=vsnprintf(buffer, UART3_PRINTF_BUF_LEN, fmt, args);
#else
  tmp=vsniprintf(buffer, UART3_PRINTF_BUF_LEN, fmt, args);
#endif
  va_end(args);
  uart3_putstr(buffer);
  return tmp;
}


int32_t uart3_putdata(char *data, int32_t size)
{
  int32_t size2 = size;
  while(size--)
    CBUF_Push(uart3_putbuf, *data++);

  USART3->CR1 |= _BV(TXEIE3);              //re-enable interrupt (or just enable)
    
  return size2;
}

int32_t uart3_putdpacket(kBotPacket * dpacket)
{
  int32_t ret = uart3_putdata((char*)dpacket->buffer, dpacket->lenExpected);
  return ret;
}

int32_t uart3_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size)
{
  int32_t len = kBotPacketWrapData(id,type,data,size,
                           uart3_tempbuf,UART3_TEMPBUF_SIZE);

  if (len > 0) uart3_putdata((char*)uart3_tempbuf,len);

  return len;
}

