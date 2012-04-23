#ifndef SYSTICK_H
#define SYSTICK_H

#include <stdint.h>
#include "stm32f10x.h"
#include "core_cm3.h"

#define SYSTICK_DEF_RELOAD_VALUE 16000000  //max is 2^24

int systick_init();
void systick_enable();
void systick_disable();
int systick_int_enable();
int systick_int_disable();
void systick_set_clock_div8();
void systick_set_clock_div1();
int systick_set_reload_value(uint32_t rval);
void systick_reset();
int systick_get_val();

#endif //SYSTICK_H

