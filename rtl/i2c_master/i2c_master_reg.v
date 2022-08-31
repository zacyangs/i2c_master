module i2c_master_reg(
    input               clk,
    input               rst,

    input               apb_sel,
    input               apb_en,
    input               apb_write,
    output reg          apb_ready = 1,
    input       [31:0]  apb_addr,
    input       [31:0]  apb_wdata,
    output reg  [31:0]  apb_rdata = 0,

    output reg          irq,
    input       [7:0]   rxr,
    output              core_en,
    output reg  [15:0]  prer,
    output              sta,
    output              sto,
    output              rd ,
    output              wr ,
    output              ack,
    output reg   [ 7:0] txr,

    input  wire         i2c_al, // i2c bus arbitration lost
    input  wire         irxack, 
    input               i2c_busy,
    input               done    // done signal: command completed, clear command register
);


//
// variable declarations
//

// registers
 // clock prescale register
reg  [ 7:0] ctr;  // control register
  // transmit register

reg  [ 7:0] cr;   // command register
wire [ 7:0] sr;   // status register



// core enable signal

wire ien;

// status register signals

reg  rxack;       // received aknowledge from slave
reg  tip;         // transfer in progress
reg  irq_flag;    // interrupt pending flag
reg  al;          // status register arbitration lost bit


// apb signals
wire write_en;
wire read_en;


wire iack ;


//
// module body
//

// generate internal reset
wire rst_i = rst;

assign write_en =  apb_write & apb_en & apb_sel;
assign read_en  = ~apb_write & apb_en & apb_sel;

always @(posedge clk)
begin
  case (apb_addr[4:2]) // synopsys parallel_case
    3'b000: apb_rdata <= #1 {16'b0, prer};
    3'b010: apb_rdata <= #1 {24'b0, ctr };
    3'b011: apb_rdata <= #1 {24'b0, rxr }; // write is transmit register (txr)
    3'b100: apb_rdata <= #1 {24'b0, sr  };  // write is command register (cr)
    3'b101: apb_rdata <= #1 {24'b0, txr };
    3'b110: apb_rdata <= #1 {24'b0, cr  };
    3'b111: apb_rdata <= #1 0;   // reserved
  endcase
end


always @(posedge clk or posedge rst_i)
  if (rst_i)
    begin
        prer <= #1 16'hffff;
        ctr  <= #1  8'h0;
        txr  <= #1  8'h0;
    end
  else
    if (write_en)
      case (apb_addr[4:2]) // synopsys parallel_case
         3'b000 : prer  <= #1 apb_wdata;
         3'b010 : ctr   <= #1 apb_wdata;
         3'b011 : txr   <= #1 apb_wdata;
         default: ;
      endcase

// status register block + interrupt request signal
always @(posedge clk or posedge rst_i)
  if (rst_i)
    begin
        al       <= #1 1'b0;
        rxack    <= #1 1'b0;
        tip      <= #1 1'b0;
        irq_flag <= #1 1'b0;
    end
  else
    begin
        al       <= #1 i2c_al | (al & ~sta);
        rxack    <= #1 irxack;
        tip      <= #1 (rd | wr);
        irq_flag <= #1 (done | i2c_al | irq_flag) & ~iack; // interrupt request flag is always generated
    end

// generate interrupt request signals
always @(posedge clk or posedge rst_i)
  if (rst_i)
    irq <= #1 1'b0;
  else
    irq <= #1 irq_flag && ien; // interrupt signal is only generated when IEN (interrupt enable bit is set)

// assign status register bits
assign sr[7]   = rxack;
assign sr[6]   = i2c_busy;
assign sr[5]   = al;
assign sr[4:2] = 3'h0; // reserved
assign sr[1]   = tip;
assign sr[0]   = irq_flag;

// generate command register (special case)
always @(posedge clk or posedge rst_i)
    if (rst_i)
        cr <= #1 8'h0;
    else if (write_en) begin
        if (core_en & (apb_addr[4:2] == 3'b100) )
            cr <= #1 apb_wdata;
    end
    else begin
        if (done | i2c_al)
            cr[7:4] <= #1 4'h0;           // clear command bits when done
                                          // or when aribitration lost
        cr[2:1] <= #1 2'b0;             // reserved bits
        cr[0]   <= #1 1'b0;             // clear IRQ_ACK bit
    end


// decode command register
assign sta  = cr[7];
assign sto  = cr[6];
assign rd   = cr[5];
assign wr   = cr[4];
assign ack  = cr[3];
assign iack = cr[0];

// decode control register
assign core_en = ctr[7];
assign ien = ctr[6];

endmodule
