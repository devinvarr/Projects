#ifndef MOTOR_H
#define MOTOR_H

/* simple control for the water pump motor */
void motor_init(void);
void motor_forward(void);
void motor_reverse(void);
void motor_stop(void);
void motor_update(void);
void motor_start_timed(int seconds);
void motor_reverse_timed(int seconds);

#endif
