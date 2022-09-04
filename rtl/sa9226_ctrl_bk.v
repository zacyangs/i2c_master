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
    output reg[7:0]       dout
);

parameter SLAVE_ADDR = 7'b1010111;
localparam WR = 1'b0;
localparam RD = 1'b1;

localparam PRER    = 3'b000;
localparam CTR     = 3'b010;
localparam RXR     = 3'b011;
localparam TXR     = 3'b011;
localparam CR      = 3'b100;
localparam SR      = 3'b100;
localparam NOP     = 3'b111;

reg [10:0] init_seq [1:0];
reg [10:0] cmd_seq [16:0];
reg [4:0]  cmd_cnt;
reg        init_done;
reg        write_or_read;
reg        irq_r = 0;
wire       irq_puls;

/*autodef*/
    //Start of automatic define
    //Start of automatic reg
    //Define flip-flop registers here
    reg                         valid_apb                       ;
    reg  [31:0]                 addr_apb                        ;
    reg                         write_apb                       ;
    reg  [31:0]                 din_apb                         ;
    //Define combination registers here
    //End of automatic reg
    //Start of automatic wire
    //Define assign wires here
    //Define instance wires here
    wire                        ready_apb                       ;
    wire                        dout_vld                        ;
    wire [31:0]                 dout_apb                        ;
    //End of automatic wire
    //End of automatic define

    localparam IDLE  = 3'b000;
    localparam INIT  = 3'b001;
    localparam READY = 3'b010;
    localparam WRITE_ADDR_WR = 3'b011;
    localparam WRITE_DATA_WR = 3'b100;
    localparam WRITE_ADDR_RD = 3'b101;
    localparam READ_DATA = 3'b110;
    reg [2:0]   state = IDLE, nstate;

assign irq_puls = irq && ~irq_r;

always@(*)
begin
    nstate = state;
    case(state)
        IDLE : nstate = INIT;
        INIT : 
            if(init_done) nsate = READY;
        READY : 
            if(valid && ready)
                nstate = WRITE_ADDR_WR;

        WRITE_ADDR_WR :
            if()
        WRITE_ADDR_RD :

        WRITE_DATA_WR :

        READ_DATA :

        default:;
    endcase
end

always@(posedge clk)
begin
    if(rst) begin
        cmd_cnt <= 0;
        ready <= 0;
        init_done <= 0;
        write_or_read <= 0;
        init_seq[0] <= {PRER, 8'hc0};
        init_seq[1] <= {CTR,  8'hc0};  // enable irq

        cmd_seq[ 0] <= {TXR, {SLAVE_ADDR, WR}};
        cmd_seq[ 1] <= {CR,  8'h90}; //start, write
        cmd_seq[ 2] <= {NOP, 8'h00}; //start, write
        cmd_seq[ 3] <= {CR,  8'h01}; // clear intr

        cmd_seq[ 4] <= {TXR, 8'h0};
        cmd_seq[ 5] <= {CR,  8'h10}; //write
        cmd_seq[ 6] <= {NOP, 8'h00}; //start, write
        cmd_seq[ 7] <= {CR,  8'h01}; // clear intr

        cmd_seq[ 8] <= {TXR, {SLAVE_ADDR, RD}};
        cmd_seq[ 9] <= {CR,  8'h90}; //start, write
        cmd_seq[10] <= {NOP, 8'h00}; //start, write
        cmd_seq[11] <= {CR,  8'h01}; // clear intr

        cmd_seq[12] <= {TXR, 8'h0};
        cmd_seq[13] <= {CR,  8'h68}; //stop, read
        cmd_seq[14] <= {NOP, 8'h00}; //nop
        cmd_seq[15] <= {CR,  8'h01}; // clear intr

        cmd_seq[16] <= {RXR, 8'h00}; // clear intr
        state <= IDLE;
    end 
    else begin
        state <= nstate;
        if(valid & ready) begin
            cmd_seq[4] <= {TXR, addr};
            write_or_read <= direct;
            if(direct == WR) begin
                cmd_seq[8] <= {TXR, din};
                cmd_seq[9] <= {CR,  8'h50};
            end else begin
                cmd_seq[8] <= {TXR, {SLAVE_ADDR, RD}};
                cmd_seq[9] <= {CR,  8'h90};
            end
            irq_r <= irq;
        end
    end
end


always@(posedge clk)
begin
   end else if(init_done == 0) begin
        valid_apb <= 1'b1;
        addr_apb  <= {init_seq[cmd_cnt][10:8], 2'b0};
        din_apb   <= init_seq[cmd_cnt][7:0];
        write_apb <= 1'b1;
        if(ready_apb && valid_apb) begin
            if(cmd_cnt == 1) begin
                valid_apb <= 1'b0;
                init_done <= 1'b1;
                cmd_cnt <= 0;
                ready <= 1'b1;
            end else
                cmd_cnt <= cmd_cnt + 1;
        end
    end else if(valid & ready) begin
        ready <= 1'b0;
        write_or_read <= direct;
    end else if(!ready) begin
        valid_apb <= cmd_seq[cmd_cnt][10:8] != NOP;
        addr_apb  <= {cmd_seq[cmd_cnt][10:8], 2'b0};
        din_apb   <= cmd_seq[cmd_cnt][7:0];
        if(cmd_cnt == 16)
            write_apb <= 1'b0;
        else
            write_apb <= 1'b1;
        if(valid_apb && ready_apb || irq_puls) begin
            if(cmd_cnt == 16 && write_or_read || cmd_cnt == 11 && !write_or_read) begin
                cmd_cnt     <= 0;
                ready       <= 1;
                valid_apb   <= 0;
            end else
                cmd_cnt <= cmd_cnt + 1;
        end
    end
end

always@(posedge clk)
begin
    if(dout_vld) dout <= dout_apb;
end


apb_adapter U0_apb_adapter (/*autoinst*/
    .clk                    (clk                            ), //input
    .rst                    (rst                            ), //input
    .ready                  (ready_apb                      ), //output
    .valid                  (valid_apb                      ), //input
    .write                  (write_apb                      ), //input
    .addr                   (addr_apb[31:0]                 ), //input
    .din                    (din_apb[31:0]                  ), //input
    .dout_vld               (dout_vld                       ), //output
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

