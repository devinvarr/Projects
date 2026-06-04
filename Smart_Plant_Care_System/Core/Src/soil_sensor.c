#include "soil_sensor.h"
#include "stm32_registers.h"
/* these are the calibration levels I tested previously */
#define DRY_VALUE  2600
#define WET_VALUE  600

extern volatile uint32_t ms_ticks;
extern void print_msg(char *msg);
extern void print_num(uint32_t n);

int soil_is_on = 0;
uint32_t last_print_time = 0;

void soil_init(void) {
    /* enabling pa0 for sensor analog input */
    RCC_AHB1ENR |= (1 << 0);
    RCC_APB2ENR |= (1 << 8);
    GPIOA->MODER |= (3 << (0 * 2));
    ADC1->SQR3 = 0;
    ADC1->CR2 |= (1 << 0);
}

uint32_t adc_read(void) {
    /* trigger conversion and wait for it to finish */
    ADC1->CR2 |= (1 << 30);
    while (!(ADC1->SR & (1 << 1)));
    return ADC1->DR;
}

void soil_enable(int enable) {
    soil_is_on = enable;
}

uint32_t soil_update(void) {
    /* print current soil reading every 1 second if turned on */

            uint32_t raw = adc_read();
            int moisture_pc = (uint32_t)(( (long long)(DRY_VALUE - (int)raw) * 100 ) / (DRY_VALUE - WET_VALUE));

            /* clamping it if it goes below 0 or above 100 */
            if (moisture_pc > 100) moisture_pc = 100;
            if (moisture_pc < 0)   moisture_pc = 0;

//            /* printing everything without using heavy sprintfs */
//            print_msg("Sensor Raw: ");
//            print_num(raw);
//            print_msg(" | Moisture: ");
//            print_num((uint32_t)moisture_pc);
//            print_msg("% \r\n");
            return moisture_pc;


}
