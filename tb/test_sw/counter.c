#include <stdint.h>

#define GPIO_REG        (*(volatile uint32_t *)0x80000000u)
#define CYCLE_COUNT     (*(volatile uint32_t *)0x80000008u)

// Example of 100 Mhz
// Match the frequency in constraints
#define SYSCLK_HZ       100000000u

int main(void) {
    uint32_t count = 0;
    uint32_t prev_cycle = CYCLE_COUNT;

    GPIO_REG = count;

    for(;;){
        while((uint32_t)(CYCLE_COUNT - prev_cycle) < SYSCLK_HZ){}

        prev_cycle += SYSCLK_HZ;
        GPIO_REG = ++count;
    }
}

