`default_nettype none
// Global time parameters.
`timescale 1ns / 1ps

module bidir_io(
  input dir,
  input d,
  inout port);
    assign port = (dir) ? 1'bz : d; // если dir=1 , то вход
endmodule

module saturating_adder(
    input [7:0] a,
    input [7:0] b,
    input [7:0] c,
    input [7:0] d,
    input [7:0] e,
    input [7:0] f,
    input [7:0] g,
    input [7:0] h,
    input [7:0] i,
    output [7:0] sum);
  wire [10:0] fullsum = a + b + c + d + e + f + g + h + i;
  assign sum = |fullsum[10:8] ? 255 : fullsum[7:0];
endmodule

module partial(
  input [7:0] 	original,
  input 			alpha,
  input [2:0] 	scale,  // by quarters
  output [7:0] result);
  assign result = alpha ? (
                        (scale[0] ? original[7:2] : 0) 
                      + (scale[1] ? original[7:1] : 0) 
                      + (scale[2] ? original : 0)) : 0;
endmodule

module lfsre(
    input clk,
    output reg [16:0] lfsr);
  wire d0;
  xnor(d0, lfsr[16], lfsr[13]);
  always @(posedge clk) begin
    lfsr <= {lfsr[15:0], d0};
  end
endmodule

module sprite(
  input pixel_clk,
  input picsel,
  input [9:0] pixel_x,
  input [9:0] pixel_y,
  input [9:0] sx,
  input [9:0] sy,
  input [8:0] write_data,
  input [10:0] write_address,
  input  write_en,
  input  write_clk,

  output alpha,
  output [7:0] brightness);

  wire [9:0] local_x = pixel_x - sx;
  wire [9:0] local_y = pixel_y - sy;
  wire [7:0] sprite_pixel;

// data 2048 x 8  pdata 2048 x 1
//  RAMB16_S9_S9 spriteram(
//    .DIA(0),
//    // .DIPA(0),
//    .DOA(sprite_pixel),
//    .WEA(0),
//    .ENA(1),
//    .CLKA(pixel_clk),
//    .ADDRA({picsel, local_y[4:0], local_x[4:0]}),
//
//    .ADDRB(write_address),
//    .DIPB(write_data[8]),
//    .DIB(write_data),
//    .WEB(write_en),
//    .ENB(1),
//    .CLKB(write_clk),
//    .DOB());

  ram_sprite	ram_sprite_inst (	
	.rdaddress ( {picsel, local_y[4:0], local_x[4:0]} ),
	.rdclock ( pixel_clk ),
	.q ( sprite_pixel ),
	
	.wraddress ( write_address ),
	.wrclock ( write_clk ),
	.wren ( write_en ),
	.data ( write_data[7:0] )	
	);

  wire sprite_outside = |(local_y[9:5]) | |(local_x[9:5]);
  assign alpha = ~sprite_outside;
  assign brightness = sprite_pixel; // sprite_outside ? 0 : sprite_pixel;
endmodule


//module seg73 (
//   input clk,
//   input rst, 	
//	  input [15:0] CPU_adr, // cpu address
//	
//   output [7:0] dataout, // led 7 SEGMENT'S + DOT
//   output U2_138_select, // Digital tube enable control    
//   output U3_138_select,
//   output [2:0] U2_138_A); // Digital tube enable address control   
//endmodule

module top(
  // Outputs
  // s,           // Onboard LED
  RS232_TXD,      // RS232 transmit
  RS232_RX,       // RS232 transmit
  // RESET_TRIGGER,  // RESET-TRIGGER#
  rs_test,

  // Inputs
  clka,

  pb_a, pb_d, pb_rd_n, pb_wr_n,

  ether_cs_n, ether_aen, ether_bhe_n, ether_clk, ether_irq, ether_rdy,

  // Flash
  flash_a, flash_d, 
  flash_ce_n, flash_oe_n, flash_we_n, flash_byte_n, flash_rdy, flash_rst_n,

  // PS/2 Keyboard
  ps2_clk, ps2_dat,
  
  // sd_card	
  sd_clk, sd_mosi, sd_miso, sd_csn,
  tst_clk, tst_mosi, tst_miso, tst_csn,

  // Pushbuttons
  sw2_n, sw3_n,

  // VGA
  vga_red, vga_green, vga_blue, vga_hsync_n, vga_vsync_n,
  
  // led 7 SEGMENT'S
  led_segs, U2_138_select, U3_138_select, U2_138_A,
  
  // audio out
  audio_out
  );
  
  // output [7:0] s;
  output RS232_TXD;
  input RS232_RX;
  output rs_test;
  // output RESET_TRIGGER;
  
  inout [4:0] pb_a;
  output ether_cs_n;
  output ether_aen;
  output ether_bhe_n;
  output pb_rd_n;
  output pb_wr_n;

  input clka;
  input ether_clk;
  input ether_irq;
  input ether_rdy;

  inout [15:0] pb_d;

  output [19:0] flash_a;

  inout [15:0] flash_d;

  output flash_ce_n;
  output flash_oe_n;
  output flash_we_n;
  output flash_byte_n;
  output flash_rdy;
  output flash_rst_n;

  reg ps2_clk_dir;
  reg ps2_dat_dir;
  reg ps2_clk_d;
  reg ps2_dat_d;
  
  inout ps2_clk;
  inout ps2_dat;
  //assign ps2_clk = ps2_clk_d;
  bidir_io ps2_clkb(.dir(ps2_clk_dir), .d(ps2_clk_d), .port(ps2_clk));  // если dir=1 , то вход
  bidir_io ps2_datb(.dir(ps2_dat_dir), .d(ps2_dat_d), .port(ps2_dat));  // 

  output sd_clk;
  output sd_mosi;
  input  sd_miso;
  output sd_csn;
  
  output tst_clk;
  output tst_mosi;
  output tst_miso;
  output tst_csn;
  
  reg sd_clk;
  reg sd_mosi;
  reg sd_csn;
  
  input sw2_n;
  input sw3_n;

  output [2:0] vga_red;
  output [2:0] vga_green;
  output [2:0] vga_blue;
  output vga_hsync_n;
  output vga_vsync_n;
  
  output [7:0] led_segs; 	// led 7 SEGMENT'S + DOT
  output U2_138_select;    // Digital tube enable control    
  output U3_138_select;
  output [2:0] U2_138_A;
  
  output audio_out; 

  wire j1_io_rd;
  wire j1_io_wr;
  wire [15:0] j1_io_addr;
  reg  [15:0] j1_io_din;
  wire [15:0] j1_io_dout;

  wire sys_clk;
  wire vga_clk;
  wire trap_clk;
  // ck_div #(.DIV_BY(12), .MULT_BY(4)) sys_ck_gen(.ck_in(clka), .ck_out(sys_clk)); // sds
  
  pll	pll_inst (
	//.areset ( areset_sig ),
	.inclk0 ( clka ), // 50 MHz
	.c0 ( sys_clk ),	//	33 MHz
	.c1 ( vga_clk ),	// 50 MHz
	.c2 ( trap_clk )	// 200 MHz
	//.locked ( locked_sig )
	);


  // ================================================
  // Hardware multiplier

  reg [15:0] mult_a;
  reg [15:0] mult_b;
  wire [31:0] mult_p;
  // signed 18-bit by 18-bit multiplier. A, B, and P are two’s complement.
  // MULT18X18 mulinsn(.A(mult_a), .B(mult_b), .P(mult_p)); // sds
  mult18	mult18_inst (
	.dataa ( mult_a ),
	.datab ( mult_b ),
	.result ( mult_p )
	);  
  //   MULT18X18SIO #(
  //     .AREG(0),
  //     .BREG(0),
  //     .PREG(0))
  //   MULT18X18SIO(
  //     .A(mult_a),
  //     .B(mult_b),
  //     .P(mult_p));

  
  // ================================================
  // ps2 keyboard 
  reg ps2_code_new;
  wire ps2_new_flag;
  wire [7:0] ps2_code;
  
  wire read_ps2_code = j1_io_rd & (j1_io_addr == 16'h4210) ; 
  ps2_keyboard ps2_keyboard_inst (
    .clk(vga_clk),   				// IN  system clock 50 Mhz
    .ps2_clk(ps2_clk),  			// IN  clock signal from PS/2 keyboard
    .ps2_data(ps2_dat), 			// IN  data signal from PS/2 keyboard
    .ps2_code_new(ps2_new_flag), // OUT flag that new PS/2 code is available on ps2_code bus
    .ps2_code(ps2_code)				// OUT (7 DOWNTO 0)
  );
  
  
  always @(posedge ps2_new_flag or posedge read_ps2_code) 
  begin
		if ( read_ps2_code )
			ps2_code_new <= 1'b0;
		else
			ps2_code_new <= 1'b1;
  end
  
    
  assign tst_clk = sd_clk;
  assign tst_mosi = sd_mosi;
  assign tst_miso = sd_miso;
  assign tst_csn = sd_csn;
  
  // ================================================
  // 32-bit 1-MHz system clock

  reg  [5:0]   clockus;
  wire [5:0]  _clockus = (clockus == 33) ? 0 : (clockus + 1);
  reg  [31:0]  clock;
  wire [31:0] _clock = (clockus == 33) ? (clock + 1) : (clock);

  always @(posedge sys_clk)
  begin
    clockus <= _clockus;
    clock   <= _clock;
  end

  // reg RESET_TRIGGER;

  reg ether_cs_n;
  reg ether_aen;
  reg ether_bhe_n;
  reg ddir;

  reg [15:0] pb_dout;
  assign pb_d = (ddir) ? 16'bz : pb_dout;
  reg pb_rd_n;
  reg pb_wr_n;

  reg pb_a_dir;
  reg [4:0] pb_aout;
  assign pb_a = pb_a_dir ? 5'bz : pb_aout;

  reg flash_ddir;
  reg [19:0] flash_a;
  reg [15:0] flash_dout;
  assign flash_d[14:0] = (flash_ddir) ? 15'bz : flash_dout[14:0];
  assign flash_d[15] = (flash_ddir & flash_byte_n) ? 1'bz : flash_dout[15];
  reg flash_ce_n;
  reg flash_oe_n;
  reg flash_we_n;
  reg flash_byte_n;
  reg flash_rdy;
  reg flash_rst_n;

  reg [12:0] vga_scroll;
  reg [13:0] vga_spritea;
  reg [9:0]  vga_spritex[7:0];
  reg [9:0]  vga_spritey[7:0];
  //reg 		 vga_addsprites;
  reg [10:0] vga_spritec0;
  reg [10:0] vga_spritec1;
  reg [10:0] vga_spritec2;
  reg [10:0] vga_spritec3;
  reg [10:0] vga_spritec4;
  reg [10:0] vga_spritec5;
  reg [10:0] vga_spritec6;
  reg [10:0] vga_spritec7;
  wire [9:0] vga_line;
  reg  [7:0] vga_spritesel;
  
  wire [7:0] uart_data;
  wire 		 uart_valid;

  // ================================================
  // output data from CPU to port IO
  always @(negedge sys_clk)
  begin
    if (j1_io_wr) begin
      case (j1_io_addr)
      // 16'h4000: s <= j1_io_dout;

      16'h4100: flash_ddir <= j1_io_dout;
      16'h4102: flash_ce_n <= j1_io_dout;
      16'h4104: flash_oe_n <= j1_io_dout;
      16'h4106: flash_we_n <= j1_io_dout;
      16'h4108: flash_byte_n <= j1_io_dout;
      16'h410a: flash_rdy <= j1_io_dout;
      16'h410c: flash_rst_n <= j1_io_dout;
      16'h410e: flash_a[15:0] <= j1_io_dout;
      16'h4110: flash_a[19:16] <= j1_io_dout;
      16'h4112: flash_dout <= j1_io_dout;

      16'h4200: ps2_clk_d	 <= j1_io_dout; // ps2_clk_d 
      16'h4202: ps2_dat_d	 <= j1_io_dout;
      16'h4204: ps2_clk_dir <= j1_io_dout; // sds
      16'h4206: ps2_dat_dir <= j1_io_dout;	
		
		16'h4220: sd_clk  <= j1_io_dout;
		16'h4222: sd_mosi <= j1_io_dout;
		16'h4226: sd_csn  <= j1_io_dout;

      16'h4300: vga_scroll  <= j1_io_dout;
      16'h4302: vga_spritea <= j1_io_dout;
      // 16'h4304: vga_spriteport
      // 16'h4308: vga_addsprites <= j1_io_dout; //sds

      16'h4400: vga_spritex[0] <= j1_io_dout;
      16'h4402: vga_spritey[0] <= j1_io_dout;
      16'h4404: vga_spritex[1] <= j1_io_dout;
      16'h4406: vga_spritey[1] <= j1_io_dout;
      16'h4408: vga_spritex[2] <= j1_io_dout;
      16'h440a: vga_spritey[2] <= j1_io_dout;
      16'h440c: vga_spritex[3] <= j1_io_dout;
      16'h440e: vga_spritey[3] <= j1_io_dout;
      16'h4410: vga_spritex[4] <= j1_io_dout;
      16'h4412: vga_spritey[4] <= j1_io_dout;
      16'h4414: vga_spritex[5] <= j1_io_dout;
      16'h4416: vga_spritey[5] <= j1_io_dout;
      16'h4418: vga_spritex[6] <= j1_io_dout;
      16'h441a: vga_spritey[6] <= j1_io_dout;
      16'h441c: vga_spritex[7] <= j1_io_dout;
      16'h441e: vga_spritey[7] <= j1_io_dout;

      16'h4420: vga_spritec0 <= j1_io_dout;
      16'h4422: vga_spritec1 <= j1_io_dout;
      16'h4424: vga_spritec2 <= j1_io_dout;
      16'h4426: vga_spritec3 <= j1_io_dout;
      16'h4428: vga_spritec4 <= j1_io_dout;
      16'h442a: vga_spritec5 <= j1_io_dout;
      16'h442c: vga_spritec6 <= j1_io_dout;
      16'h442e: vga_spritec7 <= j1_io_dout;

      16'h4430: vga_spritesel[0] <= j1_io_dout;
      16'h4432: vga_spritesel[1] <= j1_io_dout;
      16'h4434: vga_spritesel[2] <= j1_io_dout;
      16'h4436: vga_spritesel[3] <= j1_io_dout;
      16'h4438: vga_spritesel[4] <= j1_io_dout;
      16'h443a: vga_spritesel[5] <= j1_io_dout;
      16'h443c: vga_spritesel[6] <= j1_io_dout;
      16'h443e: vga_spritesel[7] <= j1_io_dout;

      // 16'h5000: j1_uart_we <= j1_io_dout;
      // 16'h5001: RESET_TRIGGER <= j1_io_dout;
		16'h5010: ay_data_in <= j1_io_dout;
		
      16'h5100: ether_cs_n <= j1_io_dout;
      16'h5101: ether_aen <= j1_io_dout;
      16'h5102: ether_bhe_n <= j1_io_dout;
      16'h5103: pb_aout <= j1_io_dout;
      16'h5104: ddir <= j1_io_dout;
      16'h5105: pb_dout <= j1_io_dout;
      16'h5106: pb_rd_n <= j1_io_dout;
      16'h5107: pb_wr_n <= j1_io_dout;
      // 5108
      // 5109
      16'h510a: pb_a_dir <= j1_io_dout;

      16'h6100: mult_a <= j1_io_dout;
      16'h6102: mult_b <= j1_io_dout;

      endcase
    end
  end

  // ================================================
  // чтение из портов ВВ
  always @* // 
  begin
    case (j1_io_addr)
    16'h4112: j1_io_din = flash_d;

    16'h4200: j1_io_din = ps2_clk;
    16'h4202: j1_io_din = ps2_dat;

    16'h4208: j1_io_din = ps2_code_new;	// kbfifocount
	 16'h4210: j1_io_din = ps2_code; 		// kbfifo
	 
	 16'h4224: j1_io_din = sd_miso;
	 
	 16'h4300: j1_io_din = vga_scroll;
    16'h4306: j1_io_din = vga_line;

    16'h4500: j1_io_din = sw2_n;
    16'h4502: j1_io_din = sw3_n;
	 
	 16'h5002: j1_io_din = uart_data;
	 16'h5004: j1_io_din = uart_valid;
	 
	 16'h5012: j1_io_din = ay_data_out;
	 
    16'h5103: j1_io_din = pb_a;
    16'h5105: j1_io_din = pb_d;
    16'h5108: j1_io_din = ether_rdy;
    16'h5109: j1_io_din = ether_irq;

    16'h6000: j1_io_din = clock[15:0];
    16'h6002: j1_io_din = clock[31:16];

    16'h6104: j1_io_din = mult_p[15:0];
    16'h6106: j1_io_din = mult_p[31:16];

    default:  j1_io_din = 16'h0946;
    endcase
  end

  reg [10:0] reset_count = 10;
  wire sys_rst_i = |reset_count || !sw2_n;
   
  always @(posedge sys_clk) begin
    if (sys_rst_i)
      reset_count <= reset_count - 1; 
	else 
	   if ( !sw2_n )  begin
		   reset_count <= 10;
		end
  end 

  wire [15:0] j1_cpu_addr;  
  j1 j1(
       // Inputs
       .sys_clk_i( sys_clk ),
       .sys_rst_i( sys_rst_i ),

       .io_rd( 	j1_io_rd ),
       .io_wr( 	j1_io_wr ),
       .io_addr( 	j1_io_addr ),
       .io_din( 	j1_io_din ),
       .io_dout( 	j1_io_dout ),
		 .cpu_addr(	j1_cpu_addr )
	); 
  
	seg73 seg73 (
		.clk( vga_clk ),
		.rst( sys_rst_i ), 	
		.img( j1_io_addr[15:8] ),	 // image position
		.track( j1_io_addr[7:0] ),  // track position
		.CPU_addr( j1_cpu_addr ), 	 // cpu address
	
		.dataout(led_segs), 					// led 7 SEGMENT'S + DOT
		.U2_138_select( U2_138_select ), // Digital tube enable control    
		.U3_138_select( U3_138_select ),
		.U2_138_A( U2_138_A ) 				// Digital tube enable address control   
	);
	
  // ================================================
  // AUDIO from AY-3-8910
  
   baudgen 
	#(	.CLKFREQ (33333333 ),
		.baud 	( 1750000 )
	) baudgen 	
	(  .clk_i(sys_clk),
		.resetq(!sys_rst_i),
		.restart(1'b0),
		.clk_o(ay_clk)		
	);
	
   reg  [8:0] ay_data_in;
	reg  [7:0] ay_data_out;
	wire ay_clk;
	wire [7:0] AUDIO_L;
	wire [7:0] AUDIO_R;
	wire OUT_L, OUT_R;
	wire j1_ay_cs = !((j1_io_addr == 16'h5010) | (j1_io_addr == 16'h5012));
	
	ay8910 ay8910 (
		.CLK( sys_clk ),  	// System Clock
      .CLC( ay_clk ), 	// PSG Clock
      .RESET( !sys_rst_i ),// Chip Reset (set all Registers to '0', active low)
      .BDIR( j1_io_wr ), 	// Bus Direction (0 - read , 1 - write)
      .CS( j1_ay_cs ), 		// Chip Select (active low)
      .BC( ay_data_in[8] ),// Bus control
      .DI( ay_data_in[7:0] ), 	// Data In
      .DO( ay_data_out ), 	// Data Out      
		.AUDIO_L( AUDIO_L[7:0] ),	// PSG Output mixed channel A and  channel B
		.AUDIO_R( AUDIO_R[7:0] )	// PSG Output mixed channel C and  channel B
	);
 
  dac dac_r (
		.DACout(OUT_R),
		.DACin(AUDIO_R[7:0]), 
		.Clk(vga_clk)
	);
  
  dac dac_l (
		.DACout(OUT_L),
		.DACin(AUDIO_L[7:0]), 
		.Clk(vga_clk)
	);
	
  assign audio_out = OUT_R; // clock[9];

  // ================================================
  // UART	
   wire j1_uart_wr = j1_io_wr & (j1_io_addr == 16'h5000) ;  
	wire j1_uart_rd = j1_io_rd & (j1_io_addr == 16'h5002) ; 
	assign rs_test = RS232_TXD; // для вывода в анализатор
	uart uart(
            // Outputs
            //.uart_busy   (uart_busy),
            .uart_tx       (RS232_TXD),
				.uart_dat_o		(uart_data),	// 8-bit from uart
				.valid_o			(uart_valid),	// has data 	
            // Inputs
				.sys_clk_i     (sys_clk),
            .sys_rst_i     (sys_rst_i),
            .uart_wr_i     (j1_uart_wr),  // write strobe
            .uart_dat_i    (j1_io_dout),  // 8-bit to uart
				.uart_rx			(RS232_RX), 	// UART recv wire
				.uart_rd_i 		(j1_uart_rd)	// read strobe				
	);

  // ================================================
  // VGA

  // wire vga_clk;
  //ck_div #(.DIV_BY(4), .MULT_BY(2)) vga_ck_gen(.ck_in(clka), .ck_out(vga_clk)); // sds

  reg [10:0] CounterX;
  reg [9:0] CounterY;
  wire CounterXmaxed = (CounterX==1040);

  always @(posedge vga_clk)
  if(CounterXmaxed)
    CounterX <= 0;
  else
    CounterX <= CounterX + 1;

  wire [9:0] _CounterY = (CounterY == 666) ? 0 : (CounterY + 1);
  always @(posedge vga_clk)
  if(CounterXmaxed)
      CounterY <= _CounterY;

  reg vga_HS, vga_VS;
  always @(posedge vga_clk)
  begin
    vga_HS <= (56 <= CounterX) & (CounterX < (56 + 120));
    vga_VS <= (37 <= CounterY) & (CounterY < (37 + 6));
  end

  // Character RAM is 2K
  wire [10:0] xx = (CounterX - (56 + 120 + 64));
  wire [10:0] xx_1 = (CounterX - (56 + 120 + 64) + 2);
  // standard timing, except (600-512)/2=44 at top and bottom
  wire [10:0] yy = (CounterY - (37 + 6 + 23 + 44));
  wire [10:0] column = xx[10:1];
  wire [10:0] column_1 = xx_1[10:1];
  wire [10:0] row    = yy[10:1];
  wire [7:0] glyph;

  wire [10:0] picaddr = {(row[7:3] + vga_scroll[4:0]), column_1[8:3]}; // column_1

  wire pic_w = j1_io_wr & (j1_io_addr[15:13] == 3'b100); // 8XXX 
  ram8_8 picture(
    .dia(0), .doa(glyph), 
	 .wea(0), 
    .ena(1), .clka(vga_clk), .addra(picaddr),
	 
    .dib(j1_io_dout), 
	 .web(pic_w),
    .enb(1), .clkb(sys_clk), .addrb(j1_io_addr));
  
//   genvar i;
//   generate 
//     for (i = 0; i < 4; i=i+1) begin : picture
//       RAMB16_S2_S2 picture(
//         .DIA(0),
//         // .DIPA(0),
//         .DOA(glyph[2 * i + 1: 2 * i]),
//         .WEA(0),
//         .ENA(1),
//         .CLKA(vga_clk),
//         .ADDRA(spicaddr),
// 
//         // .DIPB(0),
//         .DIB(j1_io_dout[2 * i + 1: 2 * i]),
//         .WEB(j1_io_wr & (j1_io_addr[15:13] == 3'b100)),
//         .ENB(1),
//         .CLKB(sys_clk),
//         .ADDRB(j1_io_addr),
//         .DOB());
//     end
//   endgenerate

//   RAMB16_S9_S9 picture(
//     .DIA(0),
//     // .DIPA(0),
//     .DOA(glyph),
//     .WEA(0),
//     .ENA(1),
//     .CLKA(vga_clk),
//     .ADDRA(picaddr),
// 
//     .DIPB(0),
//     .DIB(j1_io_dout),
//     .WEB(j1_io_wr & (j1_io_addr[15:13] == 3'b100)),
//     .ENB(1),
//     .CLKB(sys_clk),
//     .ADDRB(j1_io_addr),
//     .DOB());

    
//  RAMB16_S1_S9 chars(
//    .DIA(0),
//    // .DIPA(0),
//    .DOA(charout),
//    .WEA(0),
//    .ENA(1),
//    .CLKA(vga_clk),
//    .ADDRA({glyph, row[2:0], ~column[2:0]}),
//
//    .DIPB(0),
//    .DIB(j1_io_dout),
//    // .DIPB(2'b0),
//    .WEB(j1_io_wr & (j1_io_addr[15:12] == 4'hf)),
//    .ENB(1),
//    .CLKB(sys_clk),
//    .ADDRB(j1_io_addr),
//    .DOB());


  wire charout;	 
  ram_2k_18_chars	chars(	
	.rdaddress( {glyph, row[2:0], ~(column[2:0])} ),
	.rdclock( vga_clk ),
	.q( charout ),
		
	.wraddress( j1_io_addr ),
	.wrclock( sys_clk ),
	.data( j1_io_dout ),
	.wren( j1_io_wr & (j1_io_addr[15:12] == 4'hf) )	// fxxx
  );


  reg [10:0] regxx;
  always @(posedge vga_clk)
  begin
    regxx <= xx;
  end

  wire [63:0] sprite_pixels; // sds sprite
  wire [7:0] alpha; // sds один бит на спрайт
  
  genvar i;
  generate
    for (i = 0; i < 8; i=i+1) begin : sprite_n
      sprite sprite_n(
        .pixel_clk( vga_clk ),
        .picsel( vga_spritesel[i] ),
        .pixel_x( regxx ),
        .pixel_y( yy ),
        .sx( vga_spritex[i] ),
        .sy( vga_spritey[i] ),
        .write_data( j1_io_dout ),
        .write_address( vga_spritea[10:0] ),
        .write_en( j1_io_wr 
                & (j1_io_addr == 16'h4304)
                & (vga_spritea[13:11] == i) ),
        .write_clk( sys_clk ),
        .alpha( alpha[i] ),
        .brightness( sprite_pixels[8*i+7:8*i]) );
    end
  endgenerate

  // wire [10:0] brightsum = bright[0] + bright[1] + bright[2] + bright[3] 
  //								+ bright[4] + bright[5] + bright[6] + bright[7];
  // wire [7:0] brightness = |brightsum[10:8] ? 255 : brightsum[7:0];
  // wire [7:0] final_bright = |alpha ? 255 : 0;
  // wire [7:0] final_bright = sprite_pixels[39:32];

  wire [7:0] sprite0 = sprite_pixels[7:0];
  wire [7:0] sprite1 = sprite_pixels[15:8];
  wire [7:0] sprite2 = sprite_pixels[23:16];
  wire [7:0] sprite3 = sprite_pixels[31:24];
  wire [7:0] sprite4 = sprite_pixels[39:32];
  wire [7:0] sprite5 = sprite_pixels[47:40];
  wire [7:0] sprite6 = sprite_pixels[55:48];
  wire [7:0] sprite7 = sprite_pixels[63:56];

  reg [10:0] fullsum;
  //reg [7:0] final_bright; // sds

  wire [16:0] lfsr;
  lfsre lfsr0(
					.clk(vga_clk),
					.lfsr(lfsr)
  );
  wire [7:0] charout8 = {8{charout}};
  wire [7:0] dither = {lfsr[0], lfsr[4], lfsr[8], lfsr[12], lfsr[16]}
                       | charout8;
  wire [7:0] r0;
  wire [7:0] r1;
  wire [7:0] r2;
  wire [7:0] r3;
  wire [7:0] r4;
  wire [7:0] r5;
  wire [7:0] r6;
  wire [7:0] r7;
  
  wire [7:0] g0;
  wire [7:0] g1;
  wire [7:0] g2;
  wire [7:0] g3;
  wire [7:0] g4;
  wire [7:0] g5;
  wire [7:0] g6;
  wire [7:0] g7;
  
  wire [7:0] b0;
  wire [7:0] b1;
  wire [7:0] b2;
  wire [7:0] b3;
  wire [7:0] b4;
  wire [7:0] b5;
  wire [7:0] b6;
  wire [7:0] b7;

  wire [2:0] spr0r = vga_spritec0[10:8];
  wire [2:0] spr1r = vga_spritec1[10:8];
  wire [2:0] spr2r = vga_spritec2[10:8];
  wire [2:0] spr3r = vga_spritec3[10:8];
  wire [2:0] spr4r = vga_spritec4[10:8];
  wire [2:0] spr5r = vga_spritec5[10:8];
  wire [2:0] spr6r = vga_spritec6[10:8];
  wire [2:0] spr7r = vga_spritec7[10:8];
  
  wire [2:0] spr0g = vga_spritec0[6:4];
  wire [2:0] spr1g = vga_spritec1[6:4];
  wire [2:0] spr2g = vga_spritec2[6:4];
  wire [2:0] spr3g = vga_spritec3[6:4];
  wire [2:0] spr4g = vga_spritec4[6:4];
  wire [2:0] spr5g = vga_spritec5[6:4];
  wire [2:0] spr6g = vga_spritec6[6:4];
  wire [2:0] spr7g = vga_spritec7[6:4];
  
  wire [2:0] spr0b = vga_spritec0[2:0];
  wire [2:0] spr1b = vga_spritec1[2:0];
  wire [2:0] spr2b = vga_spritec2[2:0];
  wire [2:0] spr3b = vga_spritec3[2:0];
  wire [2:0] spr4b = vga_spritec4[2:0];
  wire [2:0] spr5b = vga_spritec5[2:0];
  wire [2:0] spr6b = vga_spritec6[2:0];
  wire [2:0] spr7b = vga_spritec7[2:0];

  partial pr0(sprite0, alpha[0], spr0r, r0);
  partial pr1(sprite1, alpha[1], spr1r, r1);
  partial pr2(sprite2, alpha[2], spr2r, r2);
  partial pr3(sprite3, alpha[3], spr3r, r3);
  partial pr4(sprite4, alpha[4], spr4r, r4);
  partial pr5(sprite5, alpha[5], spr5r, r5);
  partial pr6(sprite6, alpha[6], spr6r, r6);
  partial pr7(sprite7, alpha[7], spr7r, r7);

  partial pg0(sprite0, alpha[0], spr0g, g0);
  partial pg1(sprite1, alpha[1], spr1g, g1);
  partial pg2(sprite2, alpha[2], spr2g, g2);
  partial pg3(sprite3, alpha[3], spr3g, g3);
  partial pg4(sprite4, alpha[4], spr4g, g4);
  partial pg5(sprite5, alpha[5], spr5g, g5);
  partial pg6(sprite6, alpha[6], spr6g, g6);
  partial pg7(sprite7, alpha[7], spr7g, g7);

  partial pb0(sprite0, alpha[0], spr0b, b0);
  partial pb1(sprite1, alpha[1], spr1b, b1);
  partial pb2(sprite2, alpha[2], spr2b, b2);
  partial pb3(sprite3, alpha[3], spr3b, b3);
  partial pb4(sprite4, alpha[4], spr4b, b4);
  partial pb5(sprite5, alpha[5], spr5b, b5);
  partial pb6(sprite6, alpha[6], spr6b, b6);
  partial pb7(sprite7, alpha[7], spr7b, b7);

  wire [7:0] sat_r;
  saturating_adder add_r(r0, r1, r2, r3, r4, r5, r6, r7, dither, sat_r);
  wire [7:0] sat_g;
  saturating_adder add_g(g0, g1, g2, g3, g4, g5, g6, g7, dither, sat_g);
  wire [7:0] sat_b;
  saturating_adder add_b(b0, b1, b2, b3, b4, b5, b6, b7, dither, sat_b);

//  always @* // sds
//  begin
//    if(vga_addsprites) begin
//      final_bright = sat_r;
//    end else begin
//      if(alpha[0])      final_bright = sprite0;
//      else if(alpha[1]) final_bright = sprite1;
//      else if(alpha[2]) final_bright = sprite2;
//      else if(alpha[3]) final_bright = sprite3;
//      else if(alpha[4]) final_bright = sprite4;
//      else if(alpha[5]) final_bright = sprite5;
//      else if(alpha[6]) final_bright = sprite6;
//      else if(alpha[7]) final_bright = sprite7;
//      else
//        final_bright = 0;
//    end
//  end

  wire active = ((56 + 120 + 64) 	<= CounterX) 
              & (CounterX 				< (56 + 120 + 64 + 800))
              & ((37 + 6 + 23 + 44) < CounterY)
              & (CounterY 				< (37 + 6 + 23 + 44 + 512));
  assign vga_line = yy;
  
  // wire [2:0] vga_red = active ? (charout ? 7 : 0) : 0;
  // wire [2:0] vga_red = active ? final_bright[7:5] : 0;
  // wire [2:0] vga_green = active ? final_bright[7:5] : 0;
  // wire [2:0] vga_blue = active ? final_bright[7:5] : 0;
  
  wire [2:0] vga_red 	= active ? sat_r[7:5] : 0;
  wire [2:0] vga_green	= active ? sat_g[7:5] : 0;
  wire [2:0] vga_blue 	= active ? sat_b[7:5] : 0;
  wire vga_hsync_n = ~vga_HS;
  wire vga_vsync_n = ~vga_VS;

endmodule // top

