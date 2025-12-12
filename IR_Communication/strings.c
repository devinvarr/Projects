#include "strings.h"

bool strcmp_ (const char *String1, const char *String2) //Strcmp implementation. Purely comparison implementation.
{
    uint32_t i = 0;
    while(String1[i]!= '\0' && String2[i]!= '\0') //Compare entirety of both strings
    {
        if(String1 [i] != String2[i])
            return false;
        i++;
    }
    if(String1[i] == '\0' && String2[i] == '\0')
        return true;
    else
        return false;
}
