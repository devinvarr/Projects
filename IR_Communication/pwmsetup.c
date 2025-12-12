//Function to enable setup of PWM0_0 Signal with 38Khz, 50% Duty Cycle output

#include "pwmsetup.h"
#define PB6 0x40

void initPWM0()
{
    SYSCTL_RCGCPWM_R |= SYSCTL_RCGCPWM_R0;                        //Disable
    SYSCTL_RCGCGPIO_R |= SYSCTL_RCGCGPIO_R1| SYSCTL_RCGCGPIO_R3 ; //enable Clock for GPIO Port D, Port B
    _delay_cycles(3);

    GPIO_PORTB_AFSEL_R |= PB6;                                    //AFSEL for PB6
    GPIO_PORTB_ODR_R &= ~(PB6);                                   //Open drain disable PB6
    GPIO_PORTB_DEN_R |= PB6;                                      //Digital Enable PB6
    GPIO_PORTB_AMSEL_R &= ~(PB6);                                 //Disable PB6 Analog Function
    GPIO_PORTB_PCTL_R &= ~(GPIO_PCTL_PB6_M);                      //Clear out PCTL field for Pin 6
    GPIO_PORTB_PCTL_R |= GPIO_PCTL_PB6_M0PWM0;                    //Wire PB6 For PWM Output


    SYSCTL_RCC_R &= ~SYSCTL_RCC_PWMDIV_M;
    SYSCTL_RCC_R |= SYSCTL_RCC_USEPWMDIV | SYSCTL_RCC_PWMDIV_4;   //Use 10Mhz Clock
    PWM0_CTL_R = 0x0;
    PWM0_0_GENA_R = PWM_0_GENA_ACTLOAD_M | PWM_0_GENA_ACTCMPAD_ZERO;
    PWM0_0_LOAD_R = 263-1;                                       //Configure for 38Khz PWM Signal
    PWM0_0_CMPA_R = 131;                                         //sets Duty cycle to 50%
    PWM0_CTL_R |= PWM_CTL_GLOBALSYNC0;                           //Update Changes
    PWM0_0_CTL_R |= PWM_0_CTL_ENABLE;                            //Enable Block

}
