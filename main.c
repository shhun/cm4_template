#include <stdint.h>
#include <stdlib.h>
#include "hal.h"

int main()
{
    hal_setup();

    hal_send_str("Hello, world!");

    hal_send_str("EOF");
    while (1);
    
    return 0;
}