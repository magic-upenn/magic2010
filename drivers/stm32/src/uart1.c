#include "uart1.h"
#include "stm32f10x_rcc.h"
#include "stm32f10x_gpio.h"
#include "stm32f10x_usart.h"
#include <stdarg.h>
#include "CBUF.h"
#include "common.h"
#include "config.h"
#include "misc.h"


#define USART1_TX_PORT      GPIOA
#define USART1_RX_PORT      GPIOA
#define USART1_TX_GPIO_CLK  RCC_APB2Periph_GPIOA
#define USART1_RX_GPIO_CLK  RCC_APB2Periph_GPIOA
#define USART1_TX_PIN       GPIO_Pin_9
#define USART1_RX_PIN       GPIO_Pin_10

#define DEFAULT_BAUDRATE 57600

#define uart1_getbuf_SIZE UART1_GETBUF_SIZE
#define uart1_putbuf_SIZE UART1_PUTBUF_SIZE
#define UART1_TEMPBUF_SIZE UART1_PUTBUF_SIZE

#define UART1_PRINTF_BUF_LEN 100

//bit locations for interrupt and status flags
#define RXNEIE1 5
#define TCIE1   6
#define TXEIE1  7
#define RXNE1   5
#define TC1     6
#define TXE1    7
#define ORE1    3

volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart1_getbuf_SIZE ];
} uart1_getbuf;

volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart1_putbuf_SIZE ];
} uart1_putbuf;

uint8_t uart1_tempbuf[UART1_TEMPBUF_SIZE];

void uart1_init(void)
{
  CBUF_Init(uart1_getbuf);
  CBUF_Init(uart1_putbuf);

  //use the stm32 lib to initialize the UART (does not have to be fast)
  GPIO_InitTypeDef GPIO_InitStructure;
  NVIC_InitTypeDef NVIC_InitStructure;

  //enable the IO clock for the ports and uart hardware
  RCC_APB2PeriphClockCmd(USART1_TX_GPIO_CLK | USART1_RX_GPIO_CLK | RCC_APB2Periph_USART1, ENABLE);
  
  // Configure USART Tx as alternate function push-pull
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Pin   = USART1_TX_PIN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(USART1_TX_PORT, &GPIO_InitStructure);


  // Configure USART Rx as input with a pull-up
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU; //GPIO_Mode_IN_FLOATING;
  GPIO_InitStructure.GPIO_Pin  = USART1_RX_PIN;
  GPIO_Init(USART1_RX_PORT, &GPIO_InitStructure);

  uart1_setbaud(DEFAULT_BAUDRATE);

  //enable RX interrupt
  USART1->CR1 |= _BV(RXNEIE1);

  // Enable the USART1 Interrupt
  NVIC_InitStructure.NVIC_IRQChannel            = USART1_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = UART1_PRIORITY;
  NVIC_InitStructure.NVIC_IRQChannelCmd         = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}


int32_t uart1_setbaud(int32_t baud)
{
  //use the stm32 lib to initialize the UART (does not have to be fast)
  USART_InitTypeDef USART_InitStructure;
  USART_InitStructure.USART_BaudRate            = baud;
  USART_InitStructure.USART_WordLength          = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits            = USART_StopBits_1;
  USART_InitStructure.USART_Parity              = USART_Parity_No;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode                = USART_Mode_Rx | USART_Mode_Tx;

  USART_Init(USART1,&USART_InitStructure);
  USART_Cmd(USART1, ENABLE);
}


void USART1_IRQHandler(void)
{
  char c;

  //figure out which flag triggered the interrupt
  uint32_t status = USART1->SR;

  if (status & _BV(RXNE1))                    //received a byte
  {
    c = USART1->DR;
    CBUF_Push(uart1_getbuf, c);
  }
  else if (status & _BV(ORE1))               //this is a weird condition when another byte came in
    c = USART1->DR;                           //at exact moment of reading DR, causing ORE, but not RXNE

  if (status & _BV(TXE1))                    //transmit buffer is empty
  {
    if (!CBUF_IsEmpty(uart1_putbuf)) 
      USART1->DR = CBUF_Pop(uart1_putbuf);   //push next character
    else 
      USART1->CR1 &= ~(_BV(TXEIE1));         // Disable interrupt
  }
}


int32_t uart1_getchar()
{
  return ( CBUF_IsEmpty(uart1_getbuf) ? EOF : CBUF_Pop(uart1_getbuf) );
}


int32_t uart1_putchar(char c)
{
  CBUF_Push(uart1_putbuf, c);               //push the byte into circular buffer
  
  USART1->CR1 |= _BV(TXEIE1);               //re-enable interrupt (or just enable)
  
  return c;
}


int32_t uart1_putstr(char *str)
{
  char * str2 = str;
  while(*str != 0)
    CBUF_Push(uart1_putbuf, *str++);

  USART1->CR1 |= _BV(TXEIE1);               //re-enable interrupt (or just enable)
  return (str-str2);
}


int32_t uart1_printf(char *fmt, ...)
{
  va_list args;
  int tmp;
  char buffer[UART1_PRINTF_BUF_LEN];
  va_start(args,fmt);
#ifdef UART1_PRINTF_USE_FLOAT
  tmp=vsnprintf(buffer, UART1_PRINTF_BUF_LEN, fmt, args);
#else
  tmp=vsniprintf(buffer, UART1_PRINTF_BUF_LEN, fmt, args);
#endif
  va_end(args);
  uart1_putstr(buffer);
  return tmp;
}


int32_t uart1_putdata(char *data, int32_t size)
{
  int32_t size2 = size;
  while(size--)
    CBUF_Push(uart1_putbuf, *data++);

  USART1->CR1 |= _BV(TXEIE1);              //re-enable interrupt (or just enable)
    
  return size2;
}

int32_t uart1_putdpacket(kBotPacket * dpacket)
{
  int32_t ret = uart1_putdata((char*)dpacket->buffer, dpacket->lenExpected);
  return ret;
}

int32_t uart1_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size)
{
  int32_t len = kBotPacketWrapData(id,type,data,size,
                           uart1_tempbuf,UART1_TEMPBUF_SIZE);

  if (len > 0) uart1_putdata((char*)uart1_tempbuf,len);

  return len;
}

