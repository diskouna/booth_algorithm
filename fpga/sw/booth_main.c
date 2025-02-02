#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"

// BOOTH CORE REGISTERS
#define APB4_BOOTH_BASEADDR (0xA0000000)
#define APB4_BOOTH_OP_1     (APB4_BOOTH_BASEADDR + 0x00)
#define APB4_BOOTH_OP_2     (APB4_BOOTH_BASEADDR + 0x04)
#define APB4_BOOTH_RES      (APB4_BOOTH_BASEADDR + 0x08)
#define APB4_BOOTH_CTRL     (APB4_BOOTH_BASEADDR + 0x0C)
#define APB4_BOOTH_STAT     (APB4_BOOTH_BASEADDR + 0x10)
#define APB4_BOOTH_ID       (APB4_BOOTH_BASEADDR + 0x14)

// CONTROL REGISTER MASKS
#define APB4_BOOTH_CTRL_EN_BIT  (0x01)
// STATUS  REGISTER MASKS
#define APB4_BOOTH_STAT_RDY_BIT (0x01)
#define APB4_BOOTH_STAT_VLD_BIT (0x02)

#define addr_write32(ADDR, value) (*(volatile int32_t*)(ADDR)=(value))
#define addr_read32(ADDR)         (*(volatile int32_t*)(ADDR))

int test_booth_core(int test_id, int operand_1, int operand_2);

int main()
{
    init_platform();

    xil_printf("Running booth_core ID %0x\n\r", addr_read32(APB4_BOOTH_ID));
    
    test_booth_core(0, +42, +13);    
    test_booth_core(1, -42, +13); 
    test_booth_core(2, +42, -13);
    test_booth_core(3, -42, -13);
    
    cleanup_platform();
    return 0;
}

int test_booth_core(int test_id, int operand_1, int operand_2)
{
    int32_t result;
    
    xil_printf("TEST_ID: %0x\n\r", test_id);

    // Waiting for the core to be ready
    while (!(addr_read32(APB4_BOOTH_STAT) & APB4_BOOTH_STAT_RDY_BIT));

    // Set the core operands
    addr_write32(APB4_BOOTH_OP_1, operand_1);
    addr_write32(APB4_BOOTH_OP_2, operand_2);

    // Enable the multiplication operation
    addr_write32(APB4_BOOTH_CTRL, APB4_BOOTH_CTRL_EN_BIT);
    
    xil_printf("\t- operand_1: %d\n\r\t- operand_2: %d\n\r", addr_read32(APB4_BOOTH_OP_1), addr_read32(APB4_BOOTH_OP_2));

    // Waiting for the result to be valid
    // while (!(addr_read32(APB4_BOOTH_STAT) & APB4_BOOTH_STAT_VLD_BIT));
    // TODO: valid (pulse -> level)
    // QUICK PATCH: check the ready bit instead of the valid bit
    while (!(addr_read32(APB4_BOOTH_STAT) & APB4_BOOTH_STAT_RDY_BIT));

    // Retrieve the result
    result = addr_read32(APB4_BOOTH_RES);
    xil_printf("\t- result: %d\n\r", result);
        
    int status = (result == operand_1*operand_2);
    xil_printf("\t- status: %s (%d * %d %s= %d)\n\r", (char* []){"FAILED", "PASSED"}[status],
                operand_1, operand_2, (char* []){"!", "="}[status], result);

    xil_printf("----------------------------------------------------\n\r");
    return status;   
}
