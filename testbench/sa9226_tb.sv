module sa9226_tb;

logic clk = 0;
logic rst = 1;

wire i2c_scl;
wire i2c_sda;


logic valid = 0;
wire  ready;
logic direct = 0;
logic [7:0] addr = 0;
logic [7:0] din = 0;
wire  [7:0] dout ;


initial begin
    #100 rst <= 0;
end

always #5 clk = ~clk;


parameter SADR    = 7'b0010_000;

sa9226_wrapper#(.SLAVE_ADDR(SADR)) sa9226_wrapper_u0(
    .clk     (clk),
    .rst     (rst),
    .valid   (valid),
    .ready   (ready),
    .direct  (direct),
    .addr    (addr),
    .din     (din),
    .dout    (dout),
    .i2c_scl (i2c_scl),
    .i2c_sda (i2c_sda)
);

i2c_slave_model i2c_slave_model_u0 (.scl(i2c_scl), .sda(i2c_sda));

pullup p1(i2c_scl);
pullup p2(i2c_sda);

initial begin
    wait(!rst);

    @(posedge clk)
    valid <= 1'b1;
    addr <= 8'h01;
    din  <= 8'h0b;

    wait(ready);
    @(posedge clk)
    valid <= 1'b0;

    repeat(10) @(posedge clk);
    valid <= 1'b1;
    direct <= 1;

    wait(ready);
    @(posedge clk)
    valid <= 1'b0;

end 

endmodule
