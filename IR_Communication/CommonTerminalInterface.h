#pragma once
#include <stdint.h>
#include <stdbool.h>
#include "uart0.h"
#include "uart7.h"
#include "strings.h"

#define MAX_CHARS 80
#define MAX_FIELDS 10

typedef struct _USER_DATA
{
    char buffer[MAX_CHARS+1];
    uint8_t fieldCount;
    uint8_t fieldPosition[MAX_FIELDS];
    char fieldType[MAX_FIELDS];
} USER_DATA;

void getsUart0(USER_DATA *data);
bool isCommand(USER_DATA *data, const char strCommand[], uint8_t minArguments);
void parseFields(USER_DATA *data);
char* getFieldString(USER_DATA *data , uint8_t fieldNumber);
int32_t getFieldInteger(USER_DATA *data, uint8_t fieldNumber);
