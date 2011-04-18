#ifndef __TIMER3_H
#define __TIMER3_H

void timer3_init(void);
void timer3_set_overflow_callback(void (*callback)(void));
void timer3_set_compa_callback(void (*callback)(void));

#endif // __TIMER3_H
