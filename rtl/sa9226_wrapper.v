module sa9226_wrapper(
    input clk,
    input rst,
    input valid,
    output ready,
    input direct,
    input [7:0] addr,
    input [7:0] din,
    output           dout_vld,
    output [7:0]     dout,
    output           dout_err,
    inout i2c_scl,
    inout i2c_sda
);
parameter SLAVE_ADDR = 7'b1010111;
/*autodef*/
    //Start of automatic define
    //Start of automatic reg
    //Define flip-flop registers here
    //Define combination registers here
    //End of automatic reg
    //Start of automatic wire
    //Define assign wires here
    //Define instance wires here
    wire                        apb_sel                         ;
    wire                        apb_en                          ;
    wire                        apb_write                       ;
    wire                        apb_ready                       ;
    wire [31:0]                 apb_addr                        ;
    wire [31:0]                 apb_wdata                       ;
    wire [31:0]                 apb_rdata                       ;
    //End of automatic wire
    //End of automatic define

wire irq;

sa9226_ctrl#(.SLAVE_ADDR(SLAVE_ADDR)) U0_sa9226_ctrl(/*autoinst*/
        .clk                    (clk                            ), //input
        .rst                    (rst                            ), //input
        .irq                    (irq                            ), //input
        .apb_sel                (apb_sel                        ), //output
        .apb_en                 (apb_en                         ), //output
        .apb_write              (apb_write                      ), //output
        .apb_ready              (apb_ready                      ), //input
        .apb_addr               (apb_addr[31:0]                 ), //output
        .apb_wdata              (apb_wdata[31:0]                ), //output
        .apb_rdata              (apb_rdata[31:0]                ), //input
        .valid                  (valid                          ), //input
        .ready                  (ready                          ), //output
        .direct                 (direct                         ), //input
        .addr                   (addr[7:0]                      ), //input
        .din                    (din[7:0]                       ), //input
        .dout_vld               (dout_vld                       ), //output // INST_NEW
        .dout                   (dout[7:0]                      ), //output
        .dout_err               (dout_err                       )  //output // INST_NEW
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
        // done signal: command completed, clear command register
        // status register signals
        // hookup byte controller block
    );

endmodule
