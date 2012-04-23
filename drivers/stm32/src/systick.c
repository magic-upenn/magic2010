#include "systick.h"

int systick_init()
{
  systick_set_reload_value(SYSTICK_DEF_RELOAD_VALUE);
  systick_set_clock_div1();
  systick_enable();
  systick_reset();
  
  NVIC_SetPriority (SysTick_IRQn, (1<<__NVIC_PRIO_BITS) - 1);
  return 0;
}

void systick_reset()
{
  SysTick->VAL   = 0;
}

void systick_enable()
{
  SysTick->CTRL |= SysTick_CTRL_ENABLE_Msk;
}

void systick_disable()
{
  SysTick->CTRL &= ~(SysTick_CTRL_ENABLE_Msk);
}

int systick_int_enable()
{
  SysTick->CTRL |= SysTick_CTRL_TICKINT_Msk;
  return 0;
}

int systick_int_disable()
{
  SysTick->CTRL &= ~(SysTick_CTRL_TICKINT_Msk);
  return 0;
}

void systick_set_clock_div8()
{
  SysTick->CTRL  &= ~(SysTick_CTRL_CLKSOURCE_Msk);
}

void systick_set_clock_div1()
{
  SysTick->CTRL  |= SysTick_CTRL_CLKSOURCE_Msk;
}

int systick_set_reload_value(uint32_t ticks)
{
  if (ticks > SysTick_LOAD_RELOAD_Msk)  return (-1);            // Reload value impossible
  SysTick->LOAD  = (ticks & SysTick_LOAD_RELOAD_Msk) - 1;       // set reload register
  return 0;
}

int systick_get_val()
{
  return SysTick->VAL;
}



