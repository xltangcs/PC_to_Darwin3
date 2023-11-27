#ifndef XIL_IO_H
#define XIL_IO_H

#include "Xil_IO.c"

void Xil_Out32(uint64_t phyaddr, uint32_t val);

int Xil_In32(uint64_t phyaddr);

void set_direction(char d);


#endif