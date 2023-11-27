#include "stdio.h"
#include "xparameters.h"
#include "xgpiops.h"
#include "sleep.h"

#define GPIOPS_ID XPAR_XGPIOPS_0_DEVICE_ID   //PS��  GPIO���� ID

#define GPIO_SW_LEFT 	54  //GPIO_SW_LEFT EMIO0
#define GPIO_LED_LEFT 	55  //GPIO_LED_LEFT EMIO1
#define GPIO_TIK 		56  //PMOD1_1_LS TIK EMIO2
#define GPIO_RESET 		57  //PMOD1_2_LS RESET EMIO3

XGpioPs GPIO_Init(XGpioPs gpiops_inst);
XGpioPs Darwin_Reset(XGpioPs gpiops_inst);
XGpioPs Darwin_Tik(XGpioPs gpiops_inst);

int main()
{
    printf("EMIO TEST!\n");

    XGpioPs gpiops_inst;            //PS�� GPIO ����ʵ��
    gpiops_inst = GPIO_Init(gpiops_inst);
    gpiops_inst = Darwin_Reset(gpiops_inst);
    //��ȡ����״̬�����ڿ���LED����
    while(1){
    	u32 GPIO_SW_LEFT_value = XGpioPs_ReadPin(&gpiops_inst, GPIO_SW_LEFT);
    	//printf("GPIO_SW_LEFT_value = %d \n\r",GPIO_SW_LEFT_value);
        XGpioPs_WritePin(&gpiops_inst, GPIO_LED_LEFT, ~GPIO_SW_LEFT_value);
        gpiops_inst = Darwin_Tik(gpiops_inst);
    }

    return 0;
}
XGpioPs GPIO_Init(XGpioPs gpiops_inst)
{
    XGpioPs_Config *gpiops_cfg_ptr; //PS�� GPIO ������Ϣ

    //��������ID����������Ϣ
    gpiops_cfg_ptr = XGpioPs_LookupConfig(GPIOPS_ID);
    //��ʼ����������
    XGpioPs_CfgInitialize(&gpiops_inst, gpiops_cfg_ptr, gpiops_cfg_ptr->BaseAddr);

    //�����������
    XGpioPs_SetDirectionPin(&gpiops_inst, GPIO_SW_LEFT, 0);
    XGpioPs_SetDirectionPin(&gpiops_inst, GPIO_LED_LEFT, 1);
    XGpioPs_SetDirectionPin(&gpiops_inst, GPIO_TIK, 1);
    XGpioPs_SetDirectionPin(&gpiops_inst, GPIO_RESET, 1);

    //ʹ�����
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
}

XGpioPs Darwin_Tik(XGpioPs gpiops_inst)
{
	XGpioPs_WritePin(&gpiops_inst, GPIO_TIK, 1);
	usleep(1000);
	XGpioPs_WritePin(&gpiops_inst, GPIO_TIK, 0);
	usleep(1000);
}
