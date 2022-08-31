module i2c_master_tb;

parameter PRER    = 5'b00000;
parameter CTR     = 5'b01000;
parameter RXR     = 5'b01100;
parameter TXR     = 5'b01100;
parameter CR      = 5'b10000;
parameter SR      = 5'b10000;

parameter TXR_R   = 3'b101; // undocumented / reserved output
parameter CR_R    = 3'b110; // undocumented / reserved output

parameter RD      = 1'b1;
parameter WR      = 1'b0;
parameter SADR    = 7'b0010_000;


logic clk = 0;
logic rst = 1;
reg [7:0] q, qq;
/*autodef*/
    //Start of automatic define
    //Start of automatic reg
    //Define flip-flop registers here
    //Define combination registers here
    //End of automatic reg
    //Start of automatic wire
    //Define assign wires here
    //Define instance wires here
    wire                        i2c_scl                         ;
    wire                        i2c_sda                         ;
    wire                        irq                             ;
    //End of automatic wire
    //End of automatic define

apb apb(clk);

initial begin
    #100 rst <= 0;
end

always #5 clk = ~clk;

i2c_master_top i2c_master_top_u0 (
    /*autoinst*/
    .clk                    (clk                            ), //input
    .rst                    (rst                            ), //input
    .apb_sel                (apb.psel                        ), //input
    .apb_en                 (apb.pen                         ), //input
    .apb_write              (apb.pwrite                      ), //input
    .apb_ready              (apb.pready                      ), //output
    .apb_addr               (apb.paddr[31:0]                 ), //input
    .apb_wdata              (apb.pwdata[31:0]                ), //input
    .apb_rdata              (apb.prdata[31:0]                ), //output
    // I2C signals
    .i2c_scl                (i2c_scl                        ), //inout
    .i2c_sda                (i2c_sda                        ), //inout
    .irq                    (irq                            )  //output
);

i2c_slave_model i2c_slave_model_u0 (.scl(i2c_scl), .sda(i2c_sda));

pullup p1(i2c_scl);
pullup p2(i2c_sda);

initial begin
    wait(!rst);

    apb.write(0, 200, 1);
    apb.read(0, q, 1);

    apb.write(CTR, 8'hc0); // enable core
    $display("status: %t core enabled", $time);

    //
    // access slave (write)
    //

    // drive slave address
    apb.write(TXR, {SADR,WR} ); // present slave address, set write-bit
    apb.write(CR,      8'h90 ); // set command (start, write)
    $display("status: %t generate 'start', write cmd %0h (slave address+write)", $time, {SADR,WR} );

    // check tip bit
    wait(irq) apb.write(CR,      8'h1 ); // clear intrupt
    $display("status: %t tip==0", $time);

    // send memory address
    apb.write(TXR,     8'h01); // present slave's memory address
    apb.write(CR,      8'h10); // set command (write)
    $display("status: %t write slave memory address 01", $time);

    // check tip bit
    apb.read(SR, q);
    while(q[1])
         apb.read(SR, q); // poll it until it is zero
    $display("status: %t tip==0", $time);

    // send memory contents
    apb.write(TXR,     8'ha5); // present data
    apb.write(CR,      8'h10); // set command (write)
    $display("status: %t write data a5", $time);

//while (i2c_scl) #1;
//force i2c_scl= 1'b0;
//#100000;
//release i2c_scl;

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          // send memory contents for next memory address (auto_inc)
          apb.write( TXR,     8'h5a); // present data
          apb.write( CR,      8'h50); // set command (stop, write)
          $display("status: %t write next data 5a, generate 'stop'", $time);

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          //
          // delay
          //
//        #100000; // wait for 100us.
//        $display("status: %t wait 100us", $time);

          //
          // access slave (read)
          //

          // drive slave address
          apb.write( TXR,{SADR,WR} ); // present slave address, set write-bit
          apb.write( CR,     8'h90 ); // set command (start, write)
          $display("status: %t generate 'start', write cmd %0h (slave address+write)", $time, {SADR,WR} );

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          // send memory address
          apb.write( TXR,     8'h01); // present slave's memory address
          apb.write( CR,      8'h10); // set command (write)
          $display("status: %t write slave address 01", $time);

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          // drive slave address
          apb.write( TXR, {SADR,RD} ); // present slave's address, set read-bit
          apb.write( CR,      8'h90 ); // set command (start, write)
          $display("status: %t generate 'repeated start', write cmd %0h (slave address+read)", $time, {SADR,RD} );

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          // read data from slave
          apb.write( CR,      8'h20); // set command (read, ack_read)
          $display("status: %t read + ack", $time);

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          // check data just received
          apb.read( RXR, qq);
          if(qq !== 8'ha5)
            $display("\nERROR: Expected a5, received %x at time %t", qq, $time);
          else
            $display("status: %t received %x", $time, qq);

          // read data from slave
          apb.write( CR,      8'h20); // set command (read, ack_read)
          $display("status: %t read + ack", $time);

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          // check data just received
          apb.read( RXR, qq);
          if(qq !== 8'h5a)
            $display("\nERROR: Expected 5a, received %x at time %t", qq, $time);
          else
            $display("status: %t received %x", $time, qq);

          // read data from slave
          apb.write( CR,      8'h20); // set command (read, ack_read)
          $display("status: %t read + ack", $time);

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          // check data just received
          apb.read( RXR, qq);
          $display("status: %t received %x from 3rd read address", $time, qq);

          // read data from slave
          apb.write( CR,      8'h28); // set command (read, nack_read)
          $display("status: %t read + nack", $time);

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          // check data just received
          apb.read( RXR, qq);
          $display("status: %t received %x from 4th read address", $time, qq);

          //
          // check invalid slave memory address
          //

          // drive slave address
          apb.write( TXR, {SADR,WR} ); // present slave address, set write-bit
          apb.write( CR,      8'h90 ); // set command (start, write)
          $display("status: %t generate 'start', write cmd %0h (slave address+write). Check invalid address", $time, {SADR,WR} );

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          // send memory address
          apb.write( TXR,     8'h10); // present slave's memory address
          apb.write( CR,      8'h10); // set command (write)
          $display("status: %t write slave memory address 10", $time);

          // check tip bit
          apb.read( SR, q);
          while(q[1])
               apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          // slave should have send NACK
          $display("status: %t Check for nack", $time);
          if(!q[7])
            $display("\nERROR: Expected NACK, received ACK\n");

          // read data from slave
          apb.write( CR,      8'h40); // set command (stop)
          $display("status: %t generate 'stop'", $time);

          // check tip bit
          apb.read( SR, q);
          while(q[1])
          apb.read( SR, q); // poll it until it is zero
          $display("status: %t tip==0", $time);

          #250000; // wait 250us
          $display("\n\nstatus: %t Testbench done", $time);
          $finish;


end

endmodule
