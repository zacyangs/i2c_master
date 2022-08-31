module apb_adapter (
    input               clk,
    input               rst,

    output  reg         ready,
    input               valid,
    input               write,
    input       [31:0]  addr,
    input       [31:0]  din,
    output              dout_vld,
    output      [31:0]  dout,


    // apb master
    output  reg         apb_sel,
    output  reg         apb_en,
    output  reg         apb_write,
    input               apb_ready,
    output  reg [31:0]  apb_addr,
    output  reg [31:0]  apb_wdata,
    input       [31:0]  apb_rdata
);

localparam IDLE = 2'b00;
localparam SEL  = 2'b01;
localparam EN   = 2'b10;
localparam WAIT = 2'b11;


reg [1:0] state = IDLE, nstate;
reg [31:0] apb_addr_nxt = 0;
reg [31:0] apb_wdata_nxt = 0;
reg        apb_write_nxt = 0;


always@(*)
begin
    nstate      = state;   
    apb_sel     = 0;
    apb_en      = 0;
    ready           = 1;
    apb_write_nxt   = apb_write;
    apb_wdata_nxt   = apb_wdata;
    apb_addr_nxt    = apb_addr;

    case(state)
        IDLE : begin
            if(valid) begin
                nstate = SEL;
                apb_write_nxt = write;
                apb_wdata_nxt = din;
                apb_addr_nxt = addr;
            end
        end
        SEL : begin
            nstate = EN;
            apb_sel = 1;
            ready   = 0;
        end
        EN : begin
            apb_sel = 1;
            apb_en  = 1;
            ready   = 0;
            if(apb_ready) nstate = IDLE;
        end
        default :;
    endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst) begin
        state <= IDLE;
    end else begin
        state <= nstate;
        apb_wdata <= apb_wdata_nxt;
        apb_addr  <= apb_addr_nxt;
        apb_write <= apb_write_nxt;
    end
end

assign dout_vld = apb_ready && apb_en && !apb_write;
assign dout     = apb_rdata;

endmodule
