#ifndef __TIMER2_H
#define __TIMER2_H

void timer2_init(void);
void timer2_set_overflow_callback(void (*callback)(void));

#endif // __TIMER2_H
