/*
 * iic.c
 *
 *  Created on: Aug 29, 2022
 *      Author: zack
 */

#include "xparameters.h"
#include "xil_io.h"

#define IIC_ADDR XPAR_APB_M_0_BASEADDR
#define PRER 0
#define CTR  2
#define RXR  3
#define TXR  4
#define CR   5
#define SR   6

#define STA_MASK 0x80
#define STO_MASK 0x40
#define RD_MASK  0x20
#define WR_MASK  0x10
#define ACK_MASK 0x80
#define IACK_MASK 0x0



void iic_init(int clk){
	Xil_Out32(IIC_ADDR + PRER, clk);
	Xil_Out32(IIC_ADDR + CTR, 1 << 8);
}




