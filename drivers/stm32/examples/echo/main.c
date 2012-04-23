#include "misc.h"
#include "config.h"
#include "uart1.h"
#include "systick.h"
#include "stm32f10x.h"
#include "stm32f10x_rcc.h"
#include "stm32f10x_gpio.h"
#include "stm32f10x_usart.h"

#define NVIC_CCR ((volatile unsigned long *)(0xE000ED14))

void ResetToFlash()
{
  volatile int cntr;

  //configure the reset pin
  GPIO_InitTypeDef  GPIO_InitStructure;
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  GPIOB->BSRR = GPIO_Pin_8;

  for (cntr=0; cntr<10000; cntr++)
  {
    volatile int asdf=0;
  }

  NVIC_SystemReset();
}

void init()
{
  // Configure the NVIC Preemption Priority Bits
  NVIC_PriorityGroupConfig(NVIC_PriorityGroup_0);
  *NVIC_CCR = *NVIC_CCR | 0x200; // Set STKALIGN in NVIC - not sure whether this is needed

  //configure and initialize uarts
  HL_COM_PORT_INIT();
  HL_COM_PORT_SETBAUD(HL_BAUD_RATE);
  
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);
}

int main(void)
{
  init();
  int c;  //make sure c is int (not uint), cause getchar will return EOF (-1) if no char is available

/*
  GPIO_InitTypeDef  GPIO_InitStructure;
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  GPIOB->BSRR = GPIO_Pin_8;
*/
  while(1)
  {
    c = HL_COM_PORT_GETCHAR();
    if (c != EOF)
    {
      HL_COM_PORT_PUTCHAR(c);
      
      if (c == 'f')
      {
        HL_COM_PORT_PUTSTR("System resetting to flash!!!..\r\n");
        ResetToFlash();
      }
      else if (c == 'r')
      {
        HL_COM_PORT_PUTSTR("System resetting..\r\n");
        NVIC_SystemReset();
      }
    }
  }

  return 0;
}
