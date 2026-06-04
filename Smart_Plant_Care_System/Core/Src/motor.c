#include "motor.h"
#include "stm32_registers.h"

/* grabbing current clock tick from main file */
extern volatile uint32_t ms_ticks;
extern volatile uint8_t enclosureOpen;
int motor_is_running = 0;
uint32_t stop_time = 0;

void motor_init(void) {
    /* need clock for port C where motor pins are */
    RCC_AHB1ENR |= (1 << 2);

    /* setting pc8 and pc9 as output mode */
    GPIOC->MODER &= ~((3 << (8 * 2)) | (3 << (9 * 2)));
    GPIOC->MODER |=  ((1 << (8 * 2)) | (1 << (9 * 2)));

    motor_stop();
}

void motor_forward(void) {
    /* turning on in1 to make it move forward */
    GPIOC->BSRR = (1 << 8);
    GPIOC->BSRR = (1 << (9 + 16));
    motor_is_running = 1;
}

void motor_reverse(void) {
    /* turning on in2 to make it move backward */
    GPIOC->BSRR = (1 << (8 + 16));
    GPIOC->BSRR = (1 << 9);
    motor_is_running = 1;
}

void motor_stop(void) {
    /* putting both wires low stops the motor */
    GPIOC->BSRR = (1 << (8 + 16));
    GPIOC->BSRR = (1 << (9 + 16));
    motor_is_running = 0;
    stop_time = 0;
}

/*
 * This starts the motor FORWARD and waits for the time to pass.
 */
void motor_start_timed(int seconds) {
	if(enclosureOpen)
	{
    motor_forward();
    uint32_t stop_at = ms_ticks + (seconds * 1000);
    while ((int32_t)(ms_ticks - stop_at) < 0);
    motor_stop();
    enclosureOpen = 0;
	}
}

/*
 * This starts the motor BACKWARD and waits for the time to pass.
 */
void motor_reverse_timed(int seconds) {
	if(!enclosureOpen)
	{
    motor_reverse();
    uint32_t stop_at = ms_ticks + (seconds * 1000);
    while ((int32_t)(ms_ticks - stop_at) < 0);
    motor_stop();
    enclosureOpen = 1;
	}
}

void motor_update(void) {
    if (motor_is_running && stop_time > 0) {
        if ((int32_t)(ms_ticks - stop_time) >= 0) {
            motor_stop();
        }
    }
}
