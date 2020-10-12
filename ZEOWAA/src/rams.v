module ram8_8(
    input [7:0] dia,
    output [7:0] doa,
	 
    input wea,
    input ena,
    input clka,
    input [10:0] addra,

    input [7:0] dib,
    output [7:0] dob,
	 
    input web,
    input enb,
    input clkb,
    input [10:0] addrb
    );
	 
  
//  ram8_8 picture(
//    .dia(0), .doa(glyph), .wea(0), 
//    .ena(1), .clka(vga_clk), .addra(picaddr),
//    .dib(j1_io_dout), .web(pic_w),
//    .enb(1), .clkb(sys_clk), .addrb(j1_io_addr)
//  );
  
  // 2048 * 8 bit  
  ram_8_8_pic	picture (	
	.rdaddress ( addra ),
	.rdclock ( clka ),
	.q ( doa ),
		
	.wraddress ( addrb ),
	.wrclock ( clkb ),
	.data ( dib ),
	.wren ( web )
  );

	 
//genvar i;
//generate 
//  for (i = 0; i < 4; i=i+1) begin : ramx
//    // 8192 x 2 
//    RAMB16_S2_S2 ramx(
//      .DIA(dia[2 * i + 1: 2 * i]),
//      .WEA(wea),
//      .ENA(ena),
//      .CLKA(clka),
//      .ADDRA(addra),
//      .DOA(doa[2 * i + 1: 2 * i]),
//
//      .DIB(dib[2 * i + 1: 2 * i]),
//      .WEB(web),
//      .ENB(enb),
//      .CLKB(clkb),
//      .ADDRB(addrb),
//      .DOB(dob[2 * i + 1: 2 * i])
//      );
//  end
//endgenerate

endmodule
