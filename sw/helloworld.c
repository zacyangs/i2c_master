/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
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
#define ACK_MASK 0x08
#define IACK_MASK 0x0

#define WR  0
#define RD  1
#define SENSOR_ADDR 0x96


void iic_init(int clk){
	Xil_Out32(IIC_ADDR + PRER, clk);
	Xil_Out32(IIC_ADDR + CTR, 1 << 8);
}

int read_temp(){
	int ret;
	int temp;

	Xil_Out32(IIC_ADDR + TXR, SENSOR_ADDR | WR); // fill in data
	Xil_Out32(IIC_ADDR + CR,  STA_MASK | WR_MASK);
	while(1){
		ret = Xil_In32(IIC_ADDR + SR);
		if(ret & 2 == 0) break;
	}

	Xil_Out32(IIC_ADDR + TXR, WR); // fill in data
	Xil_Out32(IIC_ADDR + CR,  WR_MASK);
	while(1){
		ret = Xil_In32(IIC_ADDR + SR);
		if(ret & 2 == 0) break;
	}

	Xil_Out32(IIC_ADDR + TXR, SENSOR_ADDR | RD); // fill in data
	Xil_Out32(IIC_ADDR + CR,  STA_MASK | WR_MASK);
	while(1){
		ret = Xil_In32(IIC_ADDR + SR);
		if(ret & 2 == 0) break;
	}

	Xil_Out32(IIC_ADDR + CR,  RD_MASK);
	while(1){
		ret = Xil_In32(IIC_ADDR + SR);
		if(ret & 2 == 0) break;
	}
	temp = Xil_In32(IIC_ADDR + RXR);
	Xil_Out32(IIC_ADDR + CR,  RD_MASK | ACK_MASK);
	while(1){
		ret = Xil_In32(IIC_ADDR + SR);
		if(ret & 2 == 0) break;
	}
	temp = temp << 8 | Xil_In32(IIC_ADDR + RXR);
	return temp;
}


int main()
{
	int temp;
    init_platform();

    xil_printf("Hello World\n\r");

    temp = read_temp();
    xil_printf("Temp is %d", temp);

    cleanup_platform();
    return 0;
}
