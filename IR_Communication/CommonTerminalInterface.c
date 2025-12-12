#include "CommonTerminalInterface.h"

void getsUart0(USER_DATA *data)
{
    uint32_t count = 0;
    while(1)
    {
        uint32_t character = getcUart0();
        if((character == 8|| character == 127)&& count > 0) //Decrement if backspace detected
        {
            count --;
        }
        else if(character == 13 || character == 10)
        {
            data -> buffer[count] = '\0';//if null carriage received, add null terminator at end of current string position
            return;
        }
        else if(character >= 32)
        {
            if(count < MAX_CHARS)
            {
                data->buffer[count] = character; //if valid char,  add to buffer at [count], then increase count
                count++;
            }

            else if (count == MAX_CHARS)
            {
                data -> buffer[MAX_CHARS - 1] = '\0'; //if at max chars, add null terminator at end.
                return;
            }


        }
    }

}

bool isCommand(USER_DATA *data, const char strCommand[], uint8_t minArguments)
{
     char *dataCommand = getFieldString(data,0);                                    //get first field
             if(data->fieldCount == 0)                                              //if empty, return false
                 return false;
     if((strcmp_(strCommand,dataCommand)) && (data->fieldCount -1 >= minArguments)) //compare first entry to provided command.
         return true;                                                               //if the two match, and # args >= min args, return true
     else
         return false;                                                           //else return false
    }

void parseFields(USER_DATA *data)
{
    uint32_t dataPos = 0;
    char lastType = 'D';
    char currentType;
    uint32_t fieldPos = 0;
    while (data -> buffer[dataPos] != '\0')
    {
        char c = data->buffer [dataPos];

        if((c >= 'a' && c <= 'z')|| (c >= 'A' && c <= 'Z'))                 //check for Alpha character
            currentType = 'A';
        else if ((c >= '0' && c <= '9')|| c == '-' || c == '.' || c == ',') //check for numeric (including - , .)
            currentType = 'N';
        else                                                                //everything else is a delimiter
            currentType = 'D';

            if(currentType != 'D' && lastType == 'D')                       //if previous is delimeter, and current is NOT delimeter, store
            {
                if(fieldPos < MAX_FIELDS)
                {
                data->fieldType [fieldPos] = currentType;                   //current datatype,
                data->fieldPosition [fieldPos ]= dataPos;                   //and location information of this transition
                fieldPos++;                                                 //increment the field count
                }
            }

            else if(currentType == 'D')                                     //if any delimeter is found, convert to null terminator
                data->buffer [dataPos] = '\0';

            lastType = currentType;
            dataPos++;

    }
    data->fieldCount = fieldPos;                                            //place final field position as total fields.

}

char* getFieldString(USER_DATA *data , uint8_t fieldNumber)
{

    if(fieldNumber < data->fieldCount)                           //check if field # provided is within range of fieldCount
         return &data->buffer [data->fieldPosition[fieldNumber]];//if so, find data position in fieldPosition array, then get string at that position.
     else
         return 0;                                               //else return NULL
}


int32_t getFieldInteger(USER_DATA *data, uint8_t fieldNumber)
{
    if((fieldNumber <= data->fieldCount) && data->fieldType[fieldNumber] == 'N' ) //check if within max fieldCount, and if its a numeric data type
        return data->buffer[data->fieldPosition[fieldNumber]];                    //return the integer in the field.
    else return 0;
}
