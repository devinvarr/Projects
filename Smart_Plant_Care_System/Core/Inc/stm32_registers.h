#ifndef STM32_REGISTERS_H
#define STM32_REGISTERS_H

#include <stdint.h>

/* all addresses for my project */
#define RCC_BASE      0x40023800
#define GPIOA_BASE    0x40020000
#define GPIOC_BASE    0x40020800
#define ADC1_BASE     0x40012000
#define USART2_BASE   0x40004400

/* turning on bits for different things */
#define RCC_AHB1ENR   (*(volatile uint32_t *)(RCC_BASE + 0x30))
#define RCC_APB1ENR   (*(volatile uint32_t *)(RCC_BASE + 0x40))
#define RCC_APB2ENR   (*(volatile uint32_t *)(RCC_BASE + 0x44))

/* gpio struct for talking to motor and sensor */
typedef struct {
    volatile uint32_t MODER;
    volatile uint32_t OTYPER;
    volatile uint32_t OSPEEDR;
    volatile uint32_t PUPDR;
    volatile uint32_t IDR;
    volatile uint32_t ODR;
    volatile uint32_t BSRR;
    volatile uint32_t LCKR;
    volatile uint32_t AFR[2];
} GPIO_TypeDef;

#define GPIOA         ((GPIO_TypeDef *)GPIOA_BASE)
#define GPIOC         ((GPIO_TypeDef *)GPIOC_BASE)

/* adc for moisture sensor */
typedef struct {
    volatile uint32_t SR;
    volatile uint32_t CR1;
    volatile uint32_t CR2;
    volatile uint32_t SMPR1;
    volatile uint32_t SMPR2;
    volatile uint32_t JOFR[4];
    volatile uint32_t HTR;
    volatile uint32_t LTR;
    volatile uint32_t SQR1;
    volatile uint32_t SQR2;
    volatile uint32_t SQR3;
    volatile uint32_t JSQR;
    volatile uint32_t JDR[4];
    volatile uint32_t DR;
    volatile uint32_t CSR;
} ADC_TypeDef;

#define ADC1          ((ADC_TypeDef *)ADC1_BASE)

/* usart for pc serial monitor */
typedef struct {
    volatile uint32_t SR;
    volatile uint32_t DR;
    volatile uint32_t BRR;
    volatile uint32_t CR1;
    volatile uint32_t CR2;
    volatile uint32_t CR3;
    volatile uint32_t GTPR;
} USART_TypeDef;

#define USART2        ((USART_TypeDef *)USART2_BASE)

#endif
