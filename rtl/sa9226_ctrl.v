module sa9226_ctrl(
    input               clk,
    input               rst,

    input               irq,
    output              apb_sel    ,
    output              apb_en     ,
    output              apb_write  ,
    input               apb_ready  ,
    output [31:0]       apb_addr   ,
    output [31:0]       apb_wdata  ,
    input  [31:0]       apb_rdata  ,

    input               valid,
    output reg          ready,
    input               direct,
    input   [7:0]       addr,
    input   [7:0]       din,
    output reg          dout_vld,
    output reg[7:0]     dout,
    output reg          dout_err
);

parameter SLAVE_ADDR = 7'b1010111;
localparam WR = 1'b0;
localparam RD = 1'b1;

localparam PRER    = 5'b00000;
localparam CTR     = 5'b01000;
localparam RXR     = 5'b01100;
localparam TXR     = 5'b01100;
localparam CR      = 5'b10000;
localparam SR      = 5'b10000;
localparam NOP     = 5'b11100;

localparam IDLE          = 4'h0;
localparam INIT_0        = 4'h1;
localparam INIT_1        = 4'h2;
localparam ADDR_WR_0     = 4'h3;
localparam ADDR_WR_1     = 4'h4;
localparam ADDR_0        = 4'h5;
localparam ADDR_1        = 4'h6;
localparam ADDR_RD_0     = 4'h7;
localparam ADDR_RD_1     = 4'h8;
localparam READ_0        = 4'h9;
localparam DATA_OUT      = 4'ha;
localparam WAIT_IRQ      = 4'hb;
localparam READ_ACK      = 4'hc;
localparam READY_TO_WORK = 4'hd;
localparam STOP          = 4'he;
localparam CLEAR_IRQ     = 4'hf;


reg [10:0] init_seq [1:0];
reg [10:0] cmd_seq [16:0];
reg [4:0]  cmd_cnt;
reg        init_done;
reg        write_or_read;
reg        irq_r = 0;
wire       irq_pulse;

/*autodef*/
    //Start of automatic define
    //Start of automatic reg
    //Define flip-flop registers here
    reg  [3:0]                  state                           ;
    reg  [3:0]                  state_pre                       ;
    //Define combination registers here
    reg  [3:0]                  state_nxt                          ;
    reg                         valid_apb                       ;
    reg  [31:0]                 addr_apb                        ;
    reg                         write_apb                       ;
    reg  [7:0]                  addr_r;
    //End of automatic reg
    //Start of automatic wire
    //Define assign wires here
    //Define instance wires here
    wire                        ready_apb                       ;
    reg  [31:0]                 din_apb                         ;
    wire                        dout_vld_apb                    ;
    wire [31:0]                 dout_apb                        ;
    //End of automatic wire
    //End of automatic define

always@(*)
begin
    state_nxt[3:0] = state[3:0];
    case(state[3:0])
        IDLE : state_nxt[3:0] = INIT_0;
        READY_TO_WORK : if(valid && ready) state_nxt[3:0] = ADDR_WR_0;
        INIT_0    : if(ready_apb & valid_apb) state_nxt[3:0] = INIT_1;
        INIT_1    : if(ready_apb & valid_apb) state_nxt[3:0] = READY_TO_WORK;
        ADDR_WR_0 : if(ready_apb & valid_apb) state_nxt[3:0] = ADDR_WR_1;
        ADDR_WR_1 : if(ready_apb & valid_apb) state_nxt[3:0] = WAIT_IRQ;
        ADDR_0    : if(ready_apb & valid_apb) state_nxt[3:0] = ADDR_1;
        ADDR_1    : if(ready_apb & valid_apb) state_nxt[3:0] = WAIT_IRQ;
        ADDR_RD_0 : if(ready_apb & valid_apb) state_nxt[3:0] = ADDR_RD_1;
        ADDR_RD_1 : if(ready_apb & valid_apb) state_nxt[3:0] = WAIT_IRQ;
        READ_0    : if(ready_apb & valid_apb) state_nxt[3:0] = WAIT_IRQ;
        STOP      : if(ready_apb & valid_apb) state_nxt[3:0] = WAIT_IRQ;
        DATA_OUT  : if(dout_vld_apb) state_nxt[3:0] = READY_TO_WORK;
        WAIT_IRQ  : if(irq_pulse)    state_nxt[3:0] = CLEAR_IRQ;
        CLEAR_IRQ : if(ready_apb && valid_apb)state_nxt[3:0] = READ_ACK;
        READ_ACK  : 
            if(dout_vld_apb) begin
                if(state_pre[3:0] == STOP)
                    state_nxt = READY_TO_WORK;
                else if(~dout_apb[7]) 
                    state_nxt[3:0] = state_pre[3:0] + 1;
                else  begin
                    state_nxt = STOP;
                end
            end
    endcase
end

// apb adapter read/write timing generate
always@(*)
begin
    valid_apb = 1; 
    addr_apb = 0;
    din_apb = 0; 
    write_apb = 1'b1;
    ready = 1'b0;
    case(state[3:0])
        IDLE          : valid_apb = 0;
        READY_TO_WORK : begin valid_apb = 0; ready = 1'b1; end
        INIT_0        : begin addr_apb = PRER; din_apb = 32'h100; end
        INIT_1        : begin addr_apb = CTR ; din_apb = 32'h0c0; end
        ADDR_WR_0     : begin addr_apb = TXR ; din_apb = {SLAVE_ADDR, WR}; end
        ADDR_WR_1     : begin addr_apb = CR  ; din_apb = 32'h90; end // start write
        ADDR_0        : begin addr_apb = TXR ; din_apb = addr_r; end
        ADDR_1        : begin addr_apb = CR  ; din_apb = 32'h10; end // write
        ADDR_RD_0     : begin addr_apb = TXR ; din_apb = {SLAVE_ADDR, RD}; end
        ADDR_RD_1     : begin addr_apb = CR  ; din_apb = 32'h90; end // start write
        READ_0        : begin addr_apb = CR  ; din_apb = 32'h60; end // stop read 
        STOP          : begin addr_apb = CR  ; din_apb = 32'h40; end // stop 
        DATA_OUT      : begin addr_apb = RXR ; write_apb = 1'b0; end
        READ_ACK      : begin addr_apb = SR  ; write_apb = 1'b0; end
        WAIT_IRQ      : begin valid_apb = 1'b0; end
        CLEAR_IRQ     : begin addr_apb = CR  ; din_apb = 32'h01; end // clear IRQ
    endcase
end


always@(posedge clk)
begin
    if(rst) begin
        irq_r      <= 1'b0;
        state[3:0] <= IDLE;
        state_pre[3:0] <= IDLE;
        dout_err <= 1'b0;
    end else begin
        irq_r <= irq;
        state[3:0] <= state_nxt[3:0];

        if(valid && ready)
            addr_r <= addr;

        if(state_nxt[3:0] == WAIT_IRQ && state != state_nxt)
            state_pre[3:0] <= state[3:0];

        if(dout_vld_apb) begin
            dout <= dout_apb;
            if(state == DATA_OUT) begin
                dout_vld <= 1'b1;
                dout_err <= 1'b0;
            end else if(state == READ_ACK && state_nxt == READY_TO_WORK) begin
                dout_err <= 1;
                if(dout_apb[7]) dout_vld <= 1'b1;
            end
        end
        else
            dout_vld <= 1'b0;
    end
end

assign irq_pulse = irq && ~irq_r;


apb_adapter U0_apb_adapter (/*autoinst*/
    .clk                    (clk                            ), //input
    .rst                    (rst                            ), //input
    .ready                  (ready_apb                      ), //output
    .valid                  (valid_apb                      ), //input
    .write                  (write_apb                      ), //input
    .addr                   (addr_apb[31:0]                 ), //input
    .din                    (din_apb[31:0]                  ), //input
    .dout_vld               (dout_vld_apb                   ), //output
    .dout                   (dout_apb[31:0]                 ), //output
    // apb master
    .apb_sel                (apb_sel                        ), //output
    .apb_en                 (apb_en                         ), //output
    .apb_write              (apb_write                      ), //output
    .apb_ready              (apb_ready                      ), //input
    .apb_addr               (apb_addr[31:0]                 ), //output
    .apb_wdata              (apb_wdata[31:0]                ), //output
    .apb_rdata              (apb_rdata[31:0]                )  //input
);


endmodule

