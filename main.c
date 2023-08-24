/***************************** Include Files *********************************/

#include <stdio.h>
#include "xaxidma.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xscugic.h"
#include "xil_cache.h"
#include "xparameters_ps.h"
#include "xil_printf.h"
#include "xil_io.h"
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
#define RESET_TIMEOUT_COUNTER   10000    //复位时间
#define GPIO_DEVICE_ID  	XPAR_XGPIOPS_0_DEVICE_ID
#define PL_KEY_LEFT     	54
#define PL_KEY_RIGHT 		55
#define GPIO_TIK 			56
#define GPIO_RESET 			57

#define ZERO                0x0
#define ONE                 0x1



/************************** Function Prototypes ******************************/
void Darwin_system_reset();
void  TIK_generation(u32 tik_time);
static void tx_intr_handler(void *callback);
static void rx_intr_handler(void *callback);
static int setup_intr_system(XScuGic * int_ins_ptr, XAxiDma * axidma_ptr,
        u16 tx_intr_id, u16 rx_intr_id);
static void disable_intr_system(XScuGic * int_ins_ptr, u16 tx_intr_id,
        u16 rx_intr_id);

/************************** Variable Definitions *****************************/

static XAxiDma axidma;     //XAxiDma实例
static XScuGic intc;       //中断控制器的实例
volatile int tx_done;      //发送完成标志
volatile int rx_done;      //接收完成标志
volatile int error;        //传输出错标志
XGpioPs Gpio;	/* The driver instance for GPIO Device. */
XGpioPs_Config *ConfigPtr;

/************************** Function Definitions *****************************/

int main(void)
{
    int i;
    int status;
    u32 *tx_buffer_ptr;
    u32 *rx_buffer_ptr;
    XAxiDma_Config *config;

    xil_printf("\r\n--- Entering main() --- \r\n");
    Xil_DCacheDisable();   //禁用cache

	/* Initialize the GPIO driver. */
	ConfigPtr = XGpioPs_LookupConfig(GPIO_DEVICE_ID);
	XGpioPs_CfgInitialize(&Gpio, ConfigPtr, ConfigPtr->BaseAddr);
	/*  Set GPIO */
    XGpioPs_SetDirectionPin     (&Gpio, PL_KEY_LEFT , 1);
    XGpioPs_SetDirectionPin     (&Gpio, GPIO_RESET  , 1);
    XGpioPs_SetDirectionPin     (&Gpio, PL_KEY_RIGHT, 1);
    XGpioPs_SetDirectionPin     (&Gpio, GPIO_TIK    , 1);
	XGpioPs_SetOutputEnablePin  (&Gpio, PL_KEY_LEFT , 1);
	XGpioPs_SetOutputEnablePin  (&Gpio, GPIO_RESET  , 1);
	XGpioPs_SetOutputEnablePin  (&Gpio, PL_KEY_RIGHT, 1);
	XGpioPs_SetOutputEnablePin  (&Gpio, GPIO_TIK    , 1);


    tx_buffer_ptr = (u32 *) TX_BUFFER_BASE;
    rx_buffer_ptr = (u32 *) RX_BUFFER_BASE;

	/*  Reset */
    Darwin_system_reset( );

    config = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (!config) {
        xil_printf("No config found for %d\r\n", DMA_DEV_ID);
        return XST_FAILURE;
    }

    //初始化DMA引擎
    status = XAxiDma_CfgInitialize(&axidma, config);
    if (status != XST_SUCCESS) {
        xil_printf("Initialization failed %d\r\n", status);
        return XST_FAILURE;
    }

    if (XAxiDma_HasSg(&axidma)) {
        xil_printf("Device configured as SG mode \r\n");
        return XST_FAILURE;
    }

    //建立中断系统
    status = setup_intr_system(&intc, &axidma, TX_INTR_ID, RX_INTR_ID);
    if (status != XST_SUCCESS) {
        xil_printf("Failed intr setup\r\n");
        return XST_FAILURE;
    }

    //初始化标志信号
    u32 tx_length = 6;
    u32 rx_length = 0;
    u32 transmit_flag;
    tx_done = 0;
    rx_done = 0;
    error   = 0;
    i       = 0;
    //小端存储
    tx_buffer_ptr[i++] = 0x00208040;
    tx_buffer_ptr[i++] = 0x88780000;
    tx_buffer_ptr[i++] = 0x07f80000;
    tx_buffer_ptr[i++] = 0xfff847ff;
    tx_buffer_ptr[i++] = 0x00208080;
    tx_buffer_ptr[i++] = 0x88784000;


    XAxiDma_SimpleTransfer(&axidma, (UINTPTR) tx_buffer_ptr, tx_length * 4, XAXIDMA_DMA_TO_DEVICE); //字节为单位
    usleep(1000);
    transmit_flag = (unsigned int) Xil_In32(CONTROL_BASE_ADDR+4);
    while(!transmit_flag>>31); //rx_done;
    rx_length = (unsigned int) Xil_In32(CONTROL_BASE_ADDR+4);
    printf("rx_length = %x\n\r",(unsigned int) Xil_In32(CONTROL_BASE_ADDR+4));
    XAxiDma_SimpleTransfer(&axidma, (UINTPTR) rx_buffer_ptr, rx_length * 2, XAXIDMA_DEVICE_TO_DMA);
    u32 rx = RX_BUFFER_BASE;
    for(i = 0;i<rx_length/2;i++)
    {
    	xil_printf("the rx address %x is %x\n\r", rx, * (u32 *) rx);
    	rx+=4;
    }
    while (!tx_done && !rx_done && !error)
        ;
    //传输出错

    if (error) {
        xil_printf("Failed test transmit%s done, "
                "receive%s done\r\n", tx_done ? "" : " not",
                rx_done ? "" : " not");
        goto Done;
    }

    disable_intr_system(&intc, TX_INTR_ID, RX_INTR_ID);
    Done: xil_printf("--- Exiting main() --- \r\n");

    return XST_SUCCESS;
}

//DMA TX中断处理函数
static void tx_intr_handler(void *callback)
{
    int timeout;
    u32 irq_status;
    XAxiDma *axidma_inst = (XAxiDma *) callback;

    //读取待处理的中断
    irq_status = XAxiDma_IntrGetIrq(axidma_inst, XAXIDMA_DMA_TO_DEVICE);
    //确认待处理的中断
    XAxiDma_IntrAckIrq(axidma_inst, irq_status, XAXIDMA_DMA_TO_DEVICE);

    //Tx出错
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

    //Tx完成
    if ((irq_status & XAXIDMA_IRQ_IOC_MASK))
        tx_done = 1;
}

//DMA RX中断处理函数
static void rx_intr_handler(void *callback)
{
    u32 irq_status;
    int timeout;
    XAxiDma *axidma_inst = (XAxiDma *) callback;

    irq_status = XAxiDma_IntrGetIrq(axidma_inst, XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrAckIrq(axidma_inst, irq_status, XAXIDMA_DEVICE_TO_DMA);

    //Rx出错
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

    //Rx完成
    if ((irq_status & XAXIDMA_IRQ_IOC_MASK))
        rx_done = 1;
}

//建立DMA中断系统
//  @param   int_ins_ptr是指向XScuGic实例的指针
//  @param   AxiDmaPtr是指向DMA引擎实例的指针
//  @param   tx_intr_id是TX通道中断ID
//  @param   rx_intr_id是RX通道中断ID
//  @return：成功返回XST_SUCCESS，否则返回XST_FAILURE
static int setup_intr_system(XScuGic * int_ins_ptr, XAxiDma * axidma_ptr,
        u16 tx_intr_id, u16 rx_intr_id)
{
    int status;
    XScuGic_Config *intc_config;

    //初始化中断控制器驱动
    intc_config = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (NULL == intc_config) {
        return XST_FAILURE;
    }
    status = XScuGic_CfgInitialize(int_ins_ptr, intc_config,
            intc_config->CpuBaseAddress);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    //设置优先级和触发类型
    XScuGic_SetPriorityTriggerType(int_ins_ptr, tx_intr_id, 0xA0, 0x3);
    XScuGic_SetPriorityTriggerType(int_ins_ptr, rx_intr_id, 0xA0, 0x3);

    //为中断设置中断处理函数
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

    //启用来自硬件的中断
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
            (Xil_ExceptionHandler) XScuGic_InterruptHandler,
            (void *) int_ins_ptr);
    Xil_ExceptionEnable();

    //使能DMA中断
    XAxiDma_IntrEnable(&axidma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrEnable(&axidma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    return XST_SUCCESS;
}

//此函数禁用DMA引擎的中断
static void disable_intr_system(XScuGic * int_ins_ptr, u16 tx_intr_id,
        u16 rx_intr_id)
{
    XScuGic_Disconnect(int_ins_ptr, tx_intr_id);
    XScuGic_Disconnect(int_ins_ptr, rx_intr_id);
}

void Darwin_system_reset( )
{
	XGpioPs_WritePin            (&Gpio, PL_KEY_LEFT , 0);
	XGpioPs_WritePin            (&Gpio, GPIO_RESET  , 0);
	XGpioPs_WritePin            (&Gpio, PL_KEY_RIGHT, 0);
	XGpioPs_WritePin            (&Gpio, GPIO_TIK    , 0);
	usleep(1000);
	XGpioPs_WritePin            (&Gpio, PL_KEY_LEFT , 1);
	XGpioPs_WritePin            (&Gpio, GPIO_RESET  , 1);
}

void  TIK_generation(u32 tik_time)
{
	XGpioPs_WritePin            (&Gpio, PL_KEY_RIGHT, 1);
	XGpioPs_WritePin            (&Gpio, GPIO_TIK    , 1);
	usleep(tik_time);
	XGpioPs_WritePin            (&Gpio, PL_KEY_RIGHT, 0);
	XGpioPs_WritePin            (&Gpio, GPIO_TIK    , 0);
}
