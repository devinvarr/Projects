//IR Receive and Send main.c
#include <stdint.h>
#include "tm4c123gh6pm.h"
#include "clock.h"
#include "uart0.h"
#include "uart7.h"
#include "CommonTerminalInterface.h"
#include "pwmsetup.h"
#include "wait.h"
#include "debug.h"

#define MAX_CHARS 80
#define MAX_FIELDS 10                                                                               //
#define BLUE_LED      (*((volatile uint32_t *)(0x42000000 + (0x400253FC-0x40000000)*32 + 2*4))) //PF2
#define BLUE_LED_MASK   0x04                                                                    //PIN 2


void receiveMessage()
{
    BLUE_LED = 1;                             // Turn ON led to indicate ISR runs.
    if(UART7_MIS_R & UART_MIS_RXMIS)          //Receive Interrupt handler
    {
        while (!(UART7_FR_R & UART_FR_RXFE))  //While UART7 NOT EMPTY
        {
            char c = getcUart7();             //get character
            if(UART7_RSR_R & UART_RSR_PE)
            {
                putsUart0("Parity Error Occurred\r\n");      // UART Parity Error Report
            }

            if(UART7_RSR_R & UART_RSR_FE)
            {
                putsUart0("Framing Error Occurred\r\n");    //Report Framing Errors

            }
            if(c != '\0')                     //as long as its not null terminator, print whatever is in Uart7.
                putcUart0(c);
        }
        UART7_ICR_R |= UART_ICR_RXIC;         //Clear out UART7 Receive interrupt
    }


    if(UART7_MIS_R & UART_MIS_RTMIS)          //Uart Timeout Interrupt Handler
    {
        while (!(UART7_FR_R & UART_FR_RXFE))  //While UART7 NOT EMPTY
        {
            char c = getcUart7();             //get character
            if(UART7_RSR_R & UART_RSR_PE)
            {
                putsUart0("\r\nParity Error Occurred\r\n");      // UART Parity Error Report
            }

            if(UART7_RSR_R & UART_RSR_FE)
            {
                putsUart0("\r\nFraming Error Occurred\r\n");    //Report Framing Errors

            }
            UART7_ECR_R = UART_ECR_DATA_M;                  //Clear Error Register
            if(c != '\0')                     //as long as its not null terminator, print whatever is in Uart7.
                putcUart0(c);
        }
        UART7_ICR_R |= UART_ICR_RTIC;         //Clear out UART7 Time out interrupt
    }

   BLUE_LED = 0;                              //Blue LED OFF - ISR over
}

int main(void)
{
    initSystemClockTo40Mhz();
    USER_DATA data;

    initUart7();                                         //init UART 7, with format 8E1 set
    initUart0();                                         //init UART 0, with format 8N1 set. 115200 is default baud rate.
    setUart7BaudRate(300, 40000000);                     //Set for 300 baud Rate

    initPWM0();                                          //generate 38Khz PWM wave
    PWM0_ENABLE_R |= PWM_ENABLE_PWM0EN;                  //Start PWM wave

    NVIC_EN1_R = 0x80000000;                             //Uart7 = INT63, Set NVIC_EN register
    UART7_IM_R |= UART_IM_RXIM | UART_IM_RTIM ;          //Arm Receive, Time out Interrupt in Uart7 IM Register
    UART7_ICR_R |= UART_ICR_RXIC | UART_ICR_RTIC;        //Clear any existing interrupts just in case.

    SYSCTL_RCGCGPIO_R |= SYSCTL_RCGCGPIO_R5;             //Send Clock to GPIO Port F
    _delay_cycles(3);
    GPIO_PORTF_DIR_R |= BLUE_LED_MASK;                   //Set as Output
    GPIO_PORTF_DEN_R |= BLUE_LED_MASK;                   //Digital Enable
    BLUE_LED = 0;                                        //Ensure LED OFF
    while(1)
    {
        getsUart0(&data);
        parseFields(&data);                             //process information

        if(isCommand(&data, "send", 1))                 //Sending code
        {
            putsUart0("sent Message\r\n");
            uint32_t num;                               //Local variable to keep track of field position
            uint32_t FC = data.fieldCount;              //Get field count
            for(num = 1; num < FC; num++)               //Loop through all fields, starting from field at position 1
            {
                char * message = getFieldString( &data , num); //get string
                putsUart7(message);                            //print string
                if(FC > 2 && num < FC-1)                       //Space printing. If there are more than 2 fields, space is needed.
                {                                              //Print as many spaces as needed (as long as not on LAST field)
                    putcUart7(' ');
                }
            }

            putcUart7('\0');                                   //Print null terminator at very end of message
        }
        else if(isCommand(&data, "baud", 1))                   //Baud rate adjustment command. Supportable rates: [300,1200,2400,4800]
        {
            char buff[10];
            volatile uint32_t rate = atoi_(getFieldString(&data, 1)); //get desired rate

            UART7_CTL_R &= (~ UART_CTL_UARTEN);                       //Turn off uart for safety before changing baud rate
            setUart7BaudRate(rate, 40000000);                         //Set uart at desired rate
            UART7_CTL_R |= UART_CTL_UARTEN;                           //Enable Uart

            putsUart0("Baud Rate Set ");                              //Confirm Baud rate set
            putsUart0(toAsciiHex(buff, rate));
            putsUart0("\r\n");
        }
        else
            putsUart0("Invalid Command\n\r");                         //Message if not a supported command

    }
    return 0;
}

