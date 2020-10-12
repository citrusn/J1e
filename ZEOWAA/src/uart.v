module uart(
   // RS-232 debug port at 115200 bps, 1 start bit 1 stop bits
   // Outputs
   output 	  uart_busy,   // High means UART is transmitting
   output reg uart_tx,     // UART transmit wire
   output  valid_o,       	// has data 
   output [7:0] uart_dat_o, // data receive
	
	// Inputs   
	input uart_wr_i,    // Raise to transmit byte
   input [7:0] uart_dat_i,  // 8-bit data
   input sys_clk_i,    	// System clock, 33.333 MHz
   input sys_rst_i,    	// System reset
	
   input wire uart_rx, 	// UART recv wire
   input wire uart_rd_i // read strobe
   
);

  reg [3:0] bitcount;
  reg [8:0] shifter;

  assign uart_busy = |bitcount[3:1];
  wire sending = |bitcount;

  // sys_clk_i is 33.333MHz.  We want a 115200Hz clock

  reg  [28:0] d_tx;
  wire [28:0] dInc_tx = d_tx[28] ? (115200) : (115200 - 33333333);
  wire [28:0] dNxt_tx = d_tx + dInc_tx;
  
  always @(posedge sys_clk_i)
  begin
	if (sys_rst_i) 
		d_tx = 0;
	else
      d_tx = dNxt_tx;
  end
  
  wire ser_clk_tx  = ~d_tx[28]; // this is the 115200 Hz clock
  

  always @(posedge sys_clk_i)
  begin
    if (sys_rst_i) begin
      uart_tx <= 1;
      bitcount <= 0;
      shifter <= 0;
    end else begin
      // just got a new byte
      if (uart_wr_i & ~uart_busy) begin
        shifter <= { uart_dat_i[7:0], 1'h0 };
        bitcount <= (1 + 8 + 1);
      end

      if (sending & ser_clk_tx) begin
        { shifter, uart_tx } <= { 1'h1, shifter };
        bitcount <= bitcount - 1;
      end
    end
  end
  
/*
-----+     +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+----
     |     |     |     |     |     |     |     |     |     |     |     |
     |start|  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |stop1|stop2|
     |     |     |     |     |     |     |     |     |     |     |  ?  |
     +-----+-----+-----+-----+-----+-----+-----+-----+-----+           +
*/

// sys_clk_i is 33.333MHz.  We want a 115200Hz clock

  reg  [28:0] d_rx;
  wire [28:0] dInc_rx = d_rx[28] ? (115200*2) : (115200*2 - 33333333);
  //wire [28:0] dNxt_rx = d_rx + dInc_rx;
  wire [28:0] dNxt_rx = startbit ? 0: (d_rx + dInc_rx);
  
  always @(posedge sys_clk_i)
  begin
	if (sys_rst_i) 
		d_rx = 0;
	else
      d_rx = dNxt_rx;
  end
  
  wire ser_clk_rx  = ~d_rx[28]; // this is the 230400 Hz clock
  
  
  
  // UART Receive
  reg [4:0] bitcount_rx;
  reg [7:0] shifter_rx;

  // On starting edge, wait 3 half-bits then sample, and sample every 2 bits thereafter

  wire idle = &bitcount_rx;
  wire sample;
  reg [2:0] hh = 3'b111;
  wire [2:0] hhN = {hh[1:0], uart_rx};
  wire startbit = idle & (hhN[2:1] == 2'b10); // start bit 
  wire [7:0] shifterN = sample ? {hh[1], shifter_rx[7:1]}
										: shifter_rx;

  reg [4:0] bitcountN;
  always @*
    if (startbit)
      bitcountN = 0;
    else if (!idle & !valid & ser_clk_rx)
      bitcountN = bitcount_rx + 5'd1;
    else if (valid & uart_rd_i)
      bitcountN = 5'b11111;
    else
      bitcountN = bitcount_rx;

  wire valid = (bitcount_rx == 18) ;
//  reg valid;
//  always @(negedge sys_clk_i)
//  //always @(posedge _valid or posedge uart_rd_i) 
//   if (uart_rd_i)
//		valid <= 1'b0;	
//	else if (_valid) 
//		valid <= 1'b1;
//	else valid <= valid;
  
  assign valid_o = valid;
  //assign valid = (bitcount == 18);
  
  // 3,5,7,9,11,13,15,17
  assign sample = (bitcount_rx > 2) & bitcount_rx[0] & !valid & ser_clk_rx;
  assign uart_dat_o = shifter_rx;

  always @(posedge sys_rst_i or posedge sys_clk_i)
  begin
    if (sys_rst_i) begin
      hh <= 3'b111;
      bitcount_rx <= 5'b11111;
      shifter_rx <= 0;
    end else begin
      hh <= hhN;
      bitcount_rx <= bitcountN;
      shifter_rx <= shifterN;
    end
  end


endmodule