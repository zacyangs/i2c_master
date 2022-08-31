/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE revB.2 compliant I2C Master controller Top-level  ////
////                                                             ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/projects/i2c/    ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001 Richard Herveille                        ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: i2c_master_top.v,v 1.12 2009-01-19 20:29:26 rherveille Exp $
//
//  $Date: 2009-01-19 20:29:26 $
//  $Revision: 1.12 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               Revision 1.11  2005/02/27 09:26:24  rherveille
//               Fixed register overwrite issue.
//               Removed full_case pragma, replaced it by a default statement.
//
//               Revision 1.10  2003/09/01 10:34:38  rherveille
//               Fix a blocking vs. non-blocking error in the wb_dat output mux.
//
//               Revision 1.9  2003/01/09 16:44:45  rherveille
//               Fixed a bug in the Command Register declaration.
//
//               Revision 1.8  2002/12/26 16:05:12  rherveille
//               Small code simplifications
//
//               Revision 1.7  2002/12/26 15:02:32  rherveille
//               Core is now a Multimaster I2C controller
//
//               Revision 1.6  2002/11/30 22:24:40  rherveille
//               Cleaned up code
//
//               Revision 1.5  2001/11/10 10:52:55  rherveille
//               Changed PRER reset value from 0x0000 to 0xffff, conform specs.
//



`include "i2c_master_defines.v"

module i2c_master_top(
	input        			clk,     // master clock input
	input        			rst,     // synchronous active high reset

    input               apb_sel,
    input               apb_en,
    input               apb_write,
    output              apb_ready,
    input       [31:0]  apb_addr,
    input       [31:0]  apb_wdata,
    output      [31:0]  apb_rdata,

	// I2C signals
	inout 					i2c_scl,
	inout 					i2c_sda,
	output 					irq
);


	// done signal: command completed, clear command register
	wire done;
	wire core_en;
	// status register signals
	wire irxack;
	wire i2c_busy;    // bus busy (start signal detected)
	wire i2c_al;      // i2c bus arbitration lost
	wire [ 7:0] rxr;  // receive register read only
	wire [7:0]  txr;
	wire [15:0] prer;
wire sta  ;
wire sto  ;
wire rd   ;
wire wr   ;
wire ack  ;

	i2c_master_reg i2c_master_reg_u0(
	    .clk			(clk),
	    .rst			(rst),

	    .apb_sel	(apb_sel),
	    .apb_en		(apb_en),
	    .apb_write	(apb_write),
	    .apb_ready (apb_ready),
	    .apb_addr	(apb_addr),
	    .apb_wdata	(apb_wdata),
	    .apb_rdata (apb_rdata),

    	.sta 		(sta),
        .sto        (sto),
	    .irq 		(irq),
    	.rd  		(rd),
    	.wr  		(wr),
    	.ack 		(ack),
	    .core_en   (core_en),
	    .rxr       (rxr),
	    .txr       (txr),
	    .prer      (prer),
	    .i2c_al 	(i2c_al), // i2c bus arbitration lost
	    .irxack 	(irxack), 
	    .i2c_busy 	(i2c_busy),
	    .done     	(done)// done signal: command completed, clear command register
	);

	// hookup byte controller block
	i2c_master_byte_ctrl byte_controller (
        /*autoinst*/
		.clk      ( clk          ),
		.rst      ( rst          ),
		.nReset   ( !rst         ),
		.ena      ( core_en      ),
		.clk_cnt  ( prer         ),
		.start    ( sta          ),
		.stop     ( sto          ),
		.read     ( rd           ),
		.write    ( wr           ),
		.ack_in   ( ack          ),
		.din      ( txr          ),
		.cmd_ack  ( done         ),
		.ack_out  ( irxack       ),
		.dout     ( rxr          ),
		.i2c_busy ( i2c_busy     ),
		.i2c_al   ( i2c_al       ),
		.scl_i    ( scl_pad_i    ),
		.scl_o    ( scl_pad_o    ),
		.scl_oen  ( scl_padoen_o ),
		.sda_i    ( sda_pad_i    ),
		.sda_o    ( sda_pad_o    ),
		.sda_oen  ( sda_padoen_o )
	);



   IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_u0 (
      .O (scl_pad_i),     // Buffer output
      .IO(i2c_scl),   // Buffer inout port (connect directly to top-level port)
      .I (scl_pad_o),     // Buffer input
      .T (scl_padoen_o)      // 3-state enable input, high=input, low=output
   );


   IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_u1 (
      .O (sda_pad_i),     // Buffer output
      .IO(i2c_sda),   // Buffer inout port (connect directly to top-level port)
      .I (sda_pad_o),     // Buffer input
      .T (sda_padoen_o)      // 3-state enable input, high=input, low=output
   );

wire i2c_scl_i;
wire i2c_sda_i;

assign i2c_scl_i = scl_padoen_o ? scl_pad_i : scl_pad_o;
assign i2c_sda_i = sda_padoen_o ? sda_pad_i : sda_pad_o;

`ifndef FOR_SIM
ila_32 ila_32_u0(
	.clk(clk),
	.probe0({
		i2c_scl_i,
		i2c_sda_i,
    	apb_sel,
    	apb_en,
    	apb_write,
    	apb_addr[4:0],
    	apb_wdata[7:0],
    	apb_rdata[7:0]
		})
	);
`endif

endmodule
