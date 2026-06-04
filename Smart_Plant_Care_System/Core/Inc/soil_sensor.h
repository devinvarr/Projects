#ifndef SOIL_SENSOR_H
#define SOIL_SENSOR_H

#include <stdint.h>

/* things to handle the soil moisture sensor */
void soil_init(void);
void soil_enable(int enable);
uint32_t adc_read(void);
uint32_t  soil_update(void);

#endif
