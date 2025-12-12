/*
 * debug.c
 *
 *  Created on: Oct 8, 2025
 *      Author: devinv
 */

#include "debug.h"
#include <stdint.h>

char* toAsciiHex(char* buff,uint32_t val)
{
    int8_t i;
    for(i = 7; i >=0 ; i--)
    {
        uint8_t character = val & 0xF;
        if(character < 10)
        {
           buff[i] = '0' + character;

        }
        else
        {
            buff[i] = 'a' + (character-10);
        }
        val = val >> 4;
    }

    buff[8]= '\0';
    return buff;
}

int atoi_(const char *strg)
{

    int res = 0;
    int i = 0;

    while (strg[i] != '\0')
    {
        res = res * 10 + (strg[i] - '0');
        i++;
    }

    return res;
}


