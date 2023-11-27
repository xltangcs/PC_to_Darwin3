#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
 
#include <unistd.h>
#include <fcntl.h>

#define PAGE_SIZE  ((size_t)getpagesize())
#define PAGE_MASK ((uint64_t) (long)~(PAGE_SIZE - 1))
#define GET_BIT(x, bit)    ((x & (1 << bit)) >> bit)   /* 获取第bit位 */

#define CONTROL_BASE_ADDR 0x43c00000

 
void Xil_Out32(uint64_t phyaddr, uint32_t val)
{
	int fd;
	volatile uint8_t *map_base;
	uint64_t base = phyaddr & PAGE_MASK;
	uint64_t pgoffset = phyaddr & (~PAGE_MASK);
 
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1)
	{
		perror("open /dev/mem:");
	}
 
	map_base = mmap(NULL, PAGE_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED,
			fd, base);
	if(map_base == MAP_FAILED)
	{
		perror("mmap:");
	}
	*(volatile uint32_t *)(map_base + pgoffset) = val; 
	close(fd);
	munmap((void *)map_base, PAGE_SIZE);
}
 
int Xil_In32(uint64_t phyaddr)
{
	int fd;
	uint32_t val;
	volatile uint8_t *map_base;
	uint64_t base = phyaddr & PAGE_MASK;
	uint64_t pgoffset = phyaddr & (~PAGE_MASK);
	//open /dev/mem
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1)
	{
		perror("open /dev/mem:");
	}
	//mmap
	map_base = mmap(NULL, PAGE_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED,
			fd, base);
	if(map_base == MAP_FAILED)
	{
		perror("mmap:");
	}
	val = *(volatile uint32_t *)(map_base + pgoffset);
	close(fd);
	munmap((void *)map_base, PAGE_SIZE);
 
	return val;
}

void set_direction(char d)
{
	switch(d)
	{
		case 'E' :
			Xil_Out32(CONTROL_BASE_ADDR, 0);
			break;
		case 'S':
			Xil_Out32(CONTROL_BASE_ADDR, 1);
			break;
		case 'W':
			Xil_Out32(CONTROL_BASE_ADDR, 2);
			break;
		case 'N':
			Xil_Out32(CONTROL_BASE_ADDR, 3);
			break;
		default :
			Xil_Out32(CONTROL_BASE_ADDR, 0);
			break;
	}
}


#endif