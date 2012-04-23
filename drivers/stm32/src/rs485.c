#include "rs485.h"
#include "stm32f10x_rcc.h"
#include "stm32f10x_gpio.h"
#include "stm32f10x_usart.h"
#include <stdarg.h>
#include "CBUF.h"
#include "common.h"
#include "config.h"
#include "misc.h"


#define USART2_TX_PORT      GPIOA
#define USART2_RX_PORT      GPIOA
#define USART2_TX_GPIO_CLK  RCC_APB2Periph_GPIOA
#define USART2_RX_GPIO_CLK  RCC_APB2Periph_GPIOA
#define USART2_TX_PIN       GPIO_Pin_2
#define USART2_RX_PIN       GPIO_Pin_3

#define RS485_TX_ENABLE_PIN GPIO_Pin_0
#define RS485_TX_ENABLE_GPIO_CLK RCC_APB2Periph_GPIOC

#define DEFAULT_BAUDRATE 57600

#define uart2_getbuf_SIZE UART2_GETBUF_SIZE
#define uart2_putbuf_SIZE UART2_PUTBUF_SIZE
#define UART2_TEMPBUF_SIZE UART2_PUTBUF_SIZE

#define UART2_PRINTF_BUF_LEN 100

//bit locations for interrupt and status flags
#define RXNEIE2 5
#define TCIE2   6
#define TXEIE2  7
#define RXNE2   5
#define TC2     6
#define TXE2    7
#define ORE2    3

volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart2_getbuf_SIZE ];
} uart2_getbuf;
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart2_putbuf_SIZE ];
} uart2_putbuf;

uint8_t uart2_tempbuf[UART2_TEMPBUF_SIZE];

void rs485_init(void)
{
  CBUF_Init(uart2_getbuf);
  CBUF_Init(uart2_putbuf);

  //use the stm32 lib to initialize the UART (does not have to be fast)
  GPIO_InitTypeDef GPIO_InitStructure;
  NVIC_InitTypeDef NVIC_InitStructure;

  //enable the IO clock for the ports and uart hardware
  RCC_APB2PeriphClockCmd(USART2_TX_GPIO_CLK | USART2_RX_GPIO_CLK | RS485_TX_ENABLE_GPIO_CLK, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART2, ENABLE);

  // Configure USART Tx as alternate function push-pull
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Pin   = USART2_TX_PIN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(USART2_TX_PORT, &GPIO_InitStructure);

  // Configure TX EN pin as push-pull
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Pin   = RS485_TX_ENABLE_PIN;
  GPIO_Init(GPIOC, &GPIO_InitStructure);


  // Configure USART Rx as input with a pull-up
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU; //GPIO_Mode_IN_FLOATING;
  GPIO_InitStructure.GPIO_Pin  = USART2_RX_PIN;
  GPIO_Init(USART2_RX_PORT, &GPIO_InitStructure);

  rs485_setbaud(DEFAULT_BAUDRATE);

  //enable RX interrupt
  USART2->CR1 |= _BV(RXNEIE2);

  // Enable the USART2 Interrupt
  NVIC_InitStructure.NVIC_IRQChannel            = USART2_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = UART2_PRIORITY;
  NVIC_InitStructure.NVIC_IRQChannelCmd         = ENABLE;
  NVIC_Init(&NVIC_InitStructure);

  GPIOC->BSRR = GPIO_Pin_0;
}


int32_t rs485_setbaud(int32_t baud)
{
  //use the stm32 lib to initialize the UART (does not have to be fast)
  USART_InitTypeDef USART_InitStructure;
  USART_InitStructure.USART_BaudRate            = baud;
  USART_InitStructure.USART_WordLength          = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits            = USART_StopBits_1;
  USART_InitStructure.USART_Parity              = USART_Parity_No;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode                = USART_Mode_Rx | USART_Mode_Tx;

  USART_Init(USART2,&USART_InitStructure);
  USART_Cmd(USART2, ENABLE);
}


void USART2_IRQHandler(void)
{
  char c;

  //figure out which flag triggered the interrupt
  uint32_t status = USART2->SR;

  if (status & _BV(RXNE2))                    //received a byte
  {
    c = USART2->DR;
    CBUF_Push(uart2_getbuf, c);
  }
  else if (status & _BV(ORE2))               //this is a weird condition when another byte came in
    c = USART2->DR;                           //at exact moment of reading DR, causing ORE, but not RXNE

  if (status & _BV(TXE2))                    //transmit buffer is empty
  {
    if (!CBUF_IsEmpty(uart2_putbuf)) 
    {
      GPIOC->BSRR = GPIO_Pin_0;
      USART2->DR  = CBUF_Pop(uart2_putbuf);   //push next character
    }
    else
    {
      USART2->CR1 &= ~(_BV(TXEIE2));         // Disable interrupt
      //_delay_us(3);
      GPIOC->BRR  = GPIO_Pin_0;
    }
  }
}


int32_t rs485_getchar()
{
  return ( CBUF_IsEmpty(uart2_getbuf) ? EOF : CBUF_Pop(uart2_getbuf) );
}


int32_t rs485_putchar(char c)
{
  CBUF_Push(uart2_putbuf, c);               //push the byte into circular buffer
  
  USART2->CR1 |= _BV(TXEIE2);               //re-enable interrupt (or just enable)
  
  return c;
}


int32_t rs485_putstr(char *str)
{
  char * str2 = str;
  while(*str != 0)
    CBUF_Push(uart2_putbuf, *str++);
  
  CBUF_Push(uart2_putbuf, 0);  //add extra char to prevent TX_EN going low prematurely

  USART2->CR1 |= _BV(TXEIE2);               //re-enable interrupt (or just enable)
  return (str-str2);
}


int32_t rs485_printf(char *fmt, ...)
{
  va_list args;
  int tmp;
  char buffer[UART2_PRINTF_BUF_LEN];
  va_start(args,fmt);
#ifdef UART2_PRINTF_USE_FLOAT
  tmp=vsnprintf(buffer, UART2_PRINTF_BUF_LEN, fmt, args);
#else
  tmp=vsniprintf(buffer, UART2_PRINTF_BUF_LEN, fmt, args);
#endif
  va_end(args);
  rs485_putstr(buffer);
  return tmp;
}


int32_t rs485_putdata(char *data, int32_t size)
{
  int32_t size2 = size;
  
  CBUF_Push(uart2_putbuf, 0);
  
  while(size--)
    CBUF_Push(uart2_putbuf, *data++);
  
  CBUF_Push(uart2_putbuf, 0);  //add extra char to prevent TX_EN going low prematurely

  USART2->CR1 |= _BV(TXEIE2);              //re-enable interrupt (or just enable)
    
  return size2;
}

int32_t rs485_putdpacket(kBotPacket * dpacket)
{
  int32_t ret = rs485_putdata((char*)dpacket->buffer, dpacket->lenExpected);
  return ret;
}

int32_t rs485_putwdpacket(uint8_t id, uint8_t type,
                         uint8_t* data, uint8_t size)
{
  int32_t len = kBotPacketWrapData(id,type,data,size,
                           uart2_tempbuf,UART2_TEMPBUF_SIZE);

  if (len > 0) rs485_putdata((char*)uart2_tempbuf,len);

  return len;
}

