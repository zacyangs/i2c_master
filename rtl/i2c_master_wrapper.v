// +FHDR------------------------------------------------------------
//                 Copyright (c) 2022 .
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : i2c_master_wrapper.v
// Author        : 
// Created On    : 2022-08-29 10:36
// Last Modified : 2022/08/29 11:30
// -----------------------------------------------------------------
// Description:
//
//
// -FHDR------------------------------------------------------------

module i2c_master_wrapper (/*autoarg*/
    //Inputs
    UART_rxd, clk_in1, resetn, 
    //Outputs
    DDR2_addr, DDR2_ba, 
    DDR2_cas_n, DDR2_ck_n, 
    DDR2_ck_p, DDR2_cke, 
    DDR2_cs_n, DDR2_dm, 
    DDR2_odt, DDR2_ras_n, 
    DDR2_we_n, LED_tri_o, 
    UART_txd, seg, anodes, 
    //Inouts
    DDR2_dq, DDR2_dqs_n, 
    DDR2_dqs_p, i2c_scl, 
    i2c_sda
);

output [12:0]DDR2_addr;
output [2:0]DDR2_ba;
output DDR2_cas_n;
output [0:0]DDR2_ck_n;
output [0:0]DDR2_ck_p;
output [0:0]DDR2_cke;
output [0:0]DDR2_cs_n;
output [1:0]DDR2_dm;
inout [15:0]DDR2_dq;
inout [1:0]DDR2_dqs_n;
inout [1:0]DDR2_dqs_p;
output [0:0]DDR2_odt;
output DDR2_ras_n;
output DDR2_we_n;
output [15:0]LED_tri_o;
input UART_rxd;
output UART_txd;
input clk_in1;
input resetn;
output [7:0]seg;
output [7:0]anodes;
inout i2c_scl;
inout i2c_sda;


/*AutoDef*/
    //Start of automatic define
    //Start of automatic reg
    //Define flip-flop registers here
    //Define combination registers here
    //End of automatic reg
    //Start of automatic wire
    //Define assign wires here
    //Define instance wires here
    wire                        irq                             ;
    wire                        clk                             ;
    wire                        rst                             ;
    wire                        apb_sel                         ;
    wire                        apb_en                          ;
    wire                        apb_write                       ;
    wire                        apb_ready                       ;
    wire [31:0]                 apb_addr                        ;
    wire [31:0]                 apb_wdata                       ;
    wire [31:0]                 apb_rdata                       ;
    //End of automatic wire
    //End of automatic define




bd_top_wrapper U0_bd_top_wrapper (
    /*autoinst*/
    .APB_M_0_paddr   (apb_addr   ),
    .APB_M_0_penable (apb_en ),
    .APB_M_0_prdata  (apb_rdata  ),
    .APB_M_0_pready  (apb_ready  ),
    .APB_M_0_psel    (apb_sel    ),
    .APB_M_0_pslverr (0 ),
    .APB_M_0_pwdata  (apb_wdata  ),
    .APB_M_0_pwrite  (apb_write  ),
    .DDR2_addr       (DDR2_addr       ),
    .DDR2_ba         (DDR2_ba         ),
    .DDR2_cas_n      (DDR2_cas_n      ),
    .DDR2_ck_n       (DDR2_ck_n       ),
    .DDR2_ck_p       (DDR2_ck_p       ),
    .DDR2_cke        (DDR2_cke        ),
    .DDR2_cs_n       (DDR2_cs_n       ),
    .DDR2_dm         (DDR2_dm         ),
    .DDR2_dq         (DDR2_dq         ),
    .DDR2_dqs_n      (DDR2_dqs_n      ),
    .DDR2_dqs_p      (DDR2_dqs_p      ),
    .DDR2_odt        (DDR2_odt        ),
    .DDR2_ras_n      (DDR2_ras_n      ),
    .DDR2_we_n       (DDR2_we_n       ),
    .LED_tri_o       (LED_tri_o       ),
    .UART_rxd        (UART_rxd        ),
    .UART_txd        (UART_txd        ),
    .anodes_0        (anodes        ),
    .clk_in1         (clk_in1         ),
    .eth_phy_rstn    (    ),
    .intr_in         (irq         ),
    .resetn          (resetn          ),
    .seg_0           (seg           ),
    .sys_clk         (clk         ),
    .sys_rst         (rst         )
);


i2c_master_top U0_i2c_master_top (
    /*autoinst*/
    .clk                    (clk                            ), //input
    .rst                    (rst                            ), //input
    .apb_sel                (apb_sel                        ), //input
    .apb_en                 (apb_en                         ), //input
    .apb_write              (apb_write                      ), //input
    .apb_ready              (apb_ready                      ), //output
    .apb_addr               (apb_addr[31:0]                 ), //input
    .apb_wdata              (apb_wdata[31:0]                ), //input
    .apb_rdata              (apb_rdata[31:0]                ), //output
    // I2C signals
    .i2c_scl                (i2c_scl                        ), //inout
    .i2c_sda                (i2c_sda                        ), //inout
    .irq                    (irq                            )  //output
);




endmodule
//Local Variables:
//verilog-library-directories ("/mnt/hgfs/share/iic_master/iic_master_proj/iic_master.srcs/sources_1/bd/bd_top/hdl")
//verilog-library-directories-recursive:0
//End:
