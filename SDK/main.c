/***************************** Include Files *********************************/

#include "xaxidma.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xscugic.h"
#include "stdio.h"
#include "xgpiops.h"
#include "sleep.h"

/************************** Constant Definitions *****************************/

#define DMA_DEV_ID          XPAR_AXIDMA_0_DEVICE_ID
#define RX_INTR_ID          XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID
#define TX_INTR_ID          XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID
#define INTC_DEVICE_ID      XPAR_SCUGIC_SINGLE_DEVICE_ID
#define DDR_BASE_ADDR       XPAR_PS7_DDR_0_S_AXI_BASEADDR   //0x00100000
#define MEM_BASE_ADDR       (DDR_BASE_ADDR + 0x1000000)     //0x01100000
#define TX_BUFFER_BASE      (MEM_BASE_ADDR + 0x00100000)    //0x01200000
#define RX_BUFFER_BASE      (MEM_BASE_ADDR + 0x00300000)    //0x01400000
#define CONTROL_BASE_ADDR   XPAR_AXI_LITE_CONTROL_0_S00_AXI_BASEADDR //0x43C00000
#define GPIOPS_ID XPAR_XGPIOPS_0_DEVICE_ID   //PS  GPIO ID

#define GPIO_SW_LEFT 	54  //GPIO_SW_LEFT EMIO0
#define GPIO_LED_LEFT 	55  //GPIO_LED_LEFT EMIO1
#define GPIO_TIK 		56  //PMOD1_1_LS TIK EMIO2
#define GPIO_RESET 		57  //PMOD1_2_LS RESET EMIO3

#define GET_BIT(x, bit)    ((x & (1 << bit)) >> bit)  
/************************** Function Prototypes ******************************/

static void tx_intr_handler(void *callback);
static void rx_intr_handler(void *callback);
static int setup_intr_system(XScuGic * int_ins_ptr, XAxiDma * axidma_ptr,
        u16 tx_intr_id, u16 rx_intr_id);
static void disable_intr_system(XScuGic * int_ins_ptr, u16 tx_intr_id,
        u16 rx_intr_id);

XGpioPs GPIO_Init(XGpioPs gpiops_inst);
XGpioPs Darwin_Reset(XGpioPs gpiops_inst);
XGpioPs Darwin_Tik(XGpioPs gpiops_inst);
u64 parsePKG(u32 b3, u32 b4);
void set_direction(char d);
void parseDirection(u32 d);

/************************** Variable Definitions *****************************/

static XAxiDma axidma;     
static XScuGic intc;       
volatile int tx_done;      
volatile int rx_done;      
volatile int error;        
int send_length;
int rece_length;


/************************** Function Definitions *****************************/

int main(void)
{
    int i;
    int status;
    u32 *tx_buffer_ptr;
    u32 *rx_buffer_ptr;
    XAxiDma_Config *config;

    tx_buffer_ptr = (u32 *) TX_BUFFER_BASE;
    rx_buffer_ptr = (u32 *) RX_BUFFER_BASE;

    xil_printf("\r\n--- Entering main() --- \r\n");
    Xil_DCacheDisable();    //disable cache

    XGpioPs gpiops_inst;           
    gpiops_inst = GPIO_Init(gpiops_inst); //init GPIO
    gpiops_inst = Darwin_Reset(gpiops_inst);  //Darwin reset
    u32 GPIO_SW_LEFT_value = XGpioPs_ReadPin(&gpiops_inst, GPIO_SW_LEFT);
    XGpioPs_WritePin(&gpiops_inst, GPIO_LED_LEFT, ~GPIO_SW_LEFT_value);

    config = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (!config) {
        xil_printf("No config found for %d\r\n", DMA_DEV_ID);
        return XST_FAILURE;
    }

    //init DMA
    status = XAxiDma_CfgInitialize(&axidma, config);
    if (status != XST_SUCCESS) {
        xil_printf("Initialization failed %d\r\n", status);
        return XST_FAILURE;
    }

    if (XAxiDma_HasSg(&axidma)) {
        xil_printf("Device configured as SG mode \r\n");
        return XST_FAILURE;
    }

    //init DMA intr
    status = setup_intr_system(&intc, &axidma, TX_INTR_ID, RX_INTR_ID);
    if (status != XST_SUCCESS) {
        xil_printf("Failed intr setup\r\n");
        return XST_FAILURE;
    }

    //first transfer
    tx_done = 0;
    rx_done = 0;
    error   = 0;
    i       = 0;
    send_length = 0;

   tx_buffer_ptr[i++] = 0x00208040;
   tx_buffer_ptr[i++] = 0x88780000;
   tx_buffer_ptr[i++] = 0x07f80000;
   tx_buffer_ptr[i++] = 0xfff847ff;
   tx_buffer_ptr[i++] = 0x00208080;
   tx_buffer_ptr[i++] = 0x88784000;

//    tx_buffer_ptr[i++] = 0x00208040;
//    tx_buffer_ptr[i++] = 0x58780000;
//    tx_buffer_ptr[i++] = 0x07f80000;
//    tx_buffer_ptr[i++] = 0xfff847ff;
//    tx_buffer_ptr[i++] = 0x00208040;
//    tx_buffer_ptr[i++] = 0x5f800000;
//    tx_buffer_ptr[i++] = 0x07f80000;
//    tx_buffer_ptr[i++] = 0xfff847ff;
//    tx_buffer_ptr[i++] = 0x00208040;
//    tx_buffer_ptr[i++] = 0x60780000;
//    tx_buffer_ptr[i++] = 0x07f80000;
//    tx_buffer_ptr[i++] = 0xfff847ff;
//    tx_buffer_ptr[i++] = 0x00208040;
//    tx_buffer_ptr[i++] = 0x67800000;
//    tx_buffer_ptr[i++] = 0x07f80000;
//    tx_buffer_ptr[i++] = 0xfff847ff;
//    tx_buffer_ptr[i++] = 0x00208040;
//    tx_buffer_ptr[i++] = 0x68780000;
//    tx_buffer_ptr[i++] = 0x07f80000;
//    tx_buffer_ptr[i++] = 0xfff847ff;
//    tx_buffer_ptr[i++] = 0x00208040;
//    tx_buffer_ptr[i++] = 0x6f800000;
//    tx_buffer_ptr[i++] = 0x07f80000;
//    tx_buffer_ptr[i++] = 0xfff847ff;
//    tx_buffer_ptr[i++] = 0x00208040;
//    tx_buffer_ptr[i++] = 0x10780000;
//    tx_buffer_ptr[i++] = 0x05300000;
//    tx_buffer_ptr[i++] = 0x80004780;
//    tx_buffer_ptr[i++] = 0x00208040;
//    tx_buffer_ptr[i++] = 0x17800000;
//    tx_buffer_ptr[i++] = 0x05300000;
//    tx_buffer_ptr[i++] = 0xf0104000;

   


    //NORTH / SOUTH
    tx_buffer_ptr[i++] = 0x00028280;
    tx_buffer_ptr[i++] = 0x00004000;

    // EAST / WEST
    //tx_buffer_ptr[i++] = 0x00208280;
    //tx_buffer_ptr[i++] = 0x00004000;

    send_length = i;
    xil_printf("the tx length is %d\n\r", send_length);

    set_direction('S');
    status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) tx_buffer_ptr, send_length * 4, XAXIDMA_DMA_TO_DEVICE);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    xil_printf("the flag is %08x\n\r", (unsigned int)Xil_In32(CONTROL_BASE_ADDR + 2 * 4));
    while(!GET_BIT((unsigned int)Xil_In32(CONTROL_BASE_ADDR + 2 * 4), 1)); //tx done
    while(GET_BIT((unsigned int)Xil_In32(CONTROL_BASE_ADDR + 2 * 4), 0)); //enter rx 
    while(!GET_BIT((unsigned int)Xil_In32(CONTROL_BASE_ADDR + 2 * 4), 0)); //rx done 

    u32 direction = ((unsigned int)Xil_In32(CONTROL_BASE_ADDR + 2 * 4) >> 2) & 3;
    parseDirection(direction);

    rece_length = (unsigned int)Xil_In32(CONTROL_BASE_ADDR + 3 * 4);
    xil_printf("the flag is %08x\n\r", (unsigned int)Xil_In32(CONTROL_BASE_ADDR + 2 * 4));
    xil_printf("the rx length %d\n\r", rece_length);

    status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) rx_buffer_ptr, rece_length * 2, XAXIDMA_DEVICE_TO_DMA);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    int j = 0;
    for(i = 0; i < rece_length/2; i++)
    {
    	xil_printf("the rx address %x is %08x\n\r", rx_buffer_ptr + i, * (u32 *) (rx_buffer_ptr + i));
    	u32 value = * (u32 *) (rx_buffer_ptr + i);
        value = (value <<16) >>16;
        if(j == i && (value >> 6 & 7) == 1)
        {
        	printf("receive data is %016llx\n\r", parsePKG(* (u32 *) (rx_buffer_ptr + i + 2), * (u32 *) (rx_buffer_ptr + i + 3)));
        	j = i + 4;
        }
    }

    gpiops_inst = Darwin_Tik(gpiops_inst); //tik
    usleep(1000);

	//sencond transfer
    config = XAxiDma_LookupConfig(DMA_DEV_ID);
    status = XAxiDma_CfgInitialize(&axidma, config);

    tx_done = 0;
    rx_done = 0;
    error   = 0;
    i       = 0;
    send_length = 0;


    tx_buffer_ptr[i++] = 0x00028280;
    tx_buffer_ptr[i++] = 0x00004000;


    send_length = i;

    xil_printf("the tx length %d\n\r", send_length);
    status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) tx_buffer_ptr, send_length * 4, XAXIDMA_DMA_TO_DEVICE);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    xil_printf("the flag is %08x\n\r", (unsigned int)Xil_In32(CONTROL_BASE_ADDR + 2 * 4));
    while(!GET_BIT((unsigned int)Xil_In32(CONTROL_BASE_ADDR + 2 * 4), 1)); 

    while(!GET_BIT((unsigned int)Xil_In32(CONTROL_BASE_ADDR + 2 * 4), 0)); 
    rece_length = (unsigned int)Xil_In32(CONTROL_BASE_ADDR + 3 * 4);
    xil_printf("the rx length %d\n\r", rece_length);
    xil_printf("the flag is %08x\n\r", (unsigned int)Xil_In32(CONTROL_BASE_ADDR + 2 * 4));
    status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) rx_buffer_ptr, rece_length * 2, XAXIDMA_DEVICE_TO_DMA);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    j = 0;
    xil_printf("----------\n\r");// %08x\n\r", rx_buffer_ptr);//, * (u32 *) (rx_buffer_ptr));
    for(i = 0; i < rece_length/2; i++)
    {
    	xil_printf("the rx address %x is %08x\n\r", rx_buffer_ptr + i, * (u32 *) (rx_buffer_ptr + i));
    	u32 value = * (u32 *) (rx_buffer_ptr + i);
    	value = (value <<16) >>16;
    	if(j == i && (value >> 6 & 7) == 1)
    	{
    		printf("receive data is %016llx\n\r", parsePKG(* (u32 *) (rx_buffer_ptr + i + 2), * (u32 *) (rx_buffer_ptr + i + 3)));
    		j = i + 4;
    	}
    }


    


    xil_printf("Successfully ran AXI DMA Loop\r\n");
    disable_intr_system(&intc, TX_INTR_ID, RX_INTR_ID);

    xil_printf("--- Exiting main() --- \r\n");
    return XST_SUCCESS;
}


//DMA  tx intr
static void tx_intr_handler(void *callback)
{
    int timeout;
    u32 irq_status;
    XAxiDma *axidma_inst = (XAxiDma *) callback;

    irq_status = XAxiDma_IntrGetIrq(axidma_inst, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrAckIrq(axidma_inst, irq_status, XAXIDMA_DMA_TO_DEVICE);

    //Tx
    if ((irq_status & XAXIDMA_IRQ_ERROR_MASK)) {
        error = 1;
        XAxiDma_Reset(axidma_inst);
        timeout = RESET_TIMEOUT_COUNTER;
        while (timeout) {
            if (XAxiDma_ResetIsDone(axidma_inst))
                break;
            timeout -= 1;
        }
        return;
    }

    //Tx
    if ((irq_status & XAXIDMA_IRQ_IOC_MASK))
        tx_done = 1;
}

//DMA rx intr
static void rx_intr_handler(void *callback)
{
    u32 irq_status;
    int timeout;
    XAxiDma *axidma_inst = (XAxiDma *) callback;

    irq_status = XAxiDma_IntrGetIrq(axidma_inst, XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrAckIrq(axidma_inst, irq_status, XAXIDMA_DEVICE_TO_DMA);

    if ((irq_status & XAXIDMA_IRQ_ERROR_MASK)) {
        error = 1;
        XAxiDma_Reset(axidma_inst);
        timeout = RESET_TIMEOUT_COUNTER;
        while (timeout) {
            if (XAxiDma_ResetIsDone(axidma_inst))
                break;
            timeout -= 1;
        }
        return;
    }

    if ((irq_status & XAXIDMA_IRQ_IOC_MASK))
        rx_done = 1;
}


static int setup_intr_system(XScuGic * int_ins_ptr, XAxiDma * axidma_ptr,
        u16 tx_intr_id, u16 rx_intr_id)
{
    int status;
    XScuGic_Config *intc_config;


    intc_config = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (NULL == intc_config) {
        return XST_FAILURE;
    }
    status = XScuGic_CfgInitialize(int_ins_ptr, intc_config,
            intc_config->CpuBaseAddress);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XScuGic_SetPriorityTriggerType(int_ins_ptr, tx_intr_id, 0xA0, 0x3);
    XScuGic_SetPriorityTriggerType(int_ins_ptr, rx_intr_id, 0xA0, 0x3);

    status = XScuGic_Connect(int_ins_ptr, tx_intr_id,
            (Xil_InterruptHandler) tx_intr_handler, axidma_ptr);
    if (status != XST_SUCCESS) {
        return status;
    }

    status = XScuGic_Connect(int_ins_ptr, rx_intr_id,
            (Xil_InterruptHandler) rx_intr_handler, axidma_ptr);
    if (status != XST_SUCCESS) {
        return status;
    }

    XScuGic_Enable(int_ins_ptr, tx_intr_id);
    XScuGic_Enable(int_ins_ptr, rx_intr_id);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
            (Xil_ExceptionHandler) XScuGic_InterruptHandler,
            (void *) int_ins_ptr);
    Xil_ExceptionEnable();

    XAxiDma_IntrEnable(&axidma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrEnable(&axidma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    return XST_SUCCESS;
}

static void disable_intr_system(XScuGic * int_ins_ptr, u16 tx_intr_id,
        u16 rx_intr_id)
{
    XScuGic_Disconnect(int_ins_ptr, tx_intr_id);
    XScuGic_Disconnect(int_ins_ptr, rx_intr_id);
}
XGpioPs GPIO_Init(XGpioPs gpiops_inst)
{
    XGpioPs_Config *gpiops_cfg_ptr; 

   
    gpiops_cfg_ptr = XGpioPs_LookupConfig(GPIOPS_ID);
   
    XGpioPs_CfgInitialize(&gpiops_inst, gpiops_cfg_ptr, gpiops_cfg_ptr->BaseAddr);

   
    XGpioPs_SetDirectionPin(&gpiops_inst, GPIO_SW_LEFT, 0);
    XGpioPs_SetDirectionPin(&gpiops_inst, GPIO_LED_LEFT, 1);
    XGpioPs_SetDirectionPin(&gpiops_inst, GPIO_TIK, 1);
    XGpioPs_SetDirectionPin(&gpiops_inst, GPIO_RESET, 1);

   
    XGpioPs_SetOutputEnablePin(&gpiops_inst, GPIO_LED_LEFT, 1);
    XGpioPs_SetOutputEnablePin(&gpiops_inst, GPIO_TIK, 1);
    XGpioPs_SetOutputEnablePin(&gpiops_inst, GPIO_RESET, 1);
    return gpiops_inst;
}

XGpioPs Darwin_Reset(XGpioPs gpiops_inst)
{
	XGpioPs_WritePin(&gpiops_inst, GPIO_RESET, 0);
	XGpioPs_WritePin(&gpiops_inst, GPIO_TIK, 0);
	usleep(1000);
	XGpioPs_WritePin(&gpiops_inst, GPIO_RESET, 1);
	usleep(1000);
	printf("Darwin Reset\n\r");
}

XGpioPs Darwin_Tik(XGpioPs gpiops_inst)
{
	XGpioPs_WritePin(&gpiops_inst, GPIO_TIK, 1);
	usleep(1000);
	XGpioPs_WritePin(&gpiops_inst, GPIO_TIK, 0);
	usleep(1000);
	printf("Darwin Tik\n\r");
}

u64 parsePKG(u32 b3, u32 b4)
{
    b3 = (b3 >> 16) | (b3 << 16);
    b4 = (b4 >> 16) | (b4 << 16);
    u64 h32 = (b3 << 5) >> 8;
    u64 l32 = (b4 << 5) >> 8;
    return (h32 << 24) | l32;
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

void parseDirection(u32 d)
{
	switch(d)
	{
		case 0:
			printf("rx from east\n");
			break;
		case 1:
			printf("rx from south\n");
			break;
		case 2:
			printf("rx from west\n");
			break;
		case 3:
			printf("rx from north\n");
			break;
		default:
			break;
	}
}

