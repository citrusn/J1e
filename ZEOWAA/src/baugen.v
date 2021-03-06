module baudgen 
 #( parameter CLKFREQ = 1000000,
	            baud = 115200 ) 
  (   
  input wire clk_i,
  input wire resetq,
  
  input wire restart,
  output wire clk_o);
  

  

  //wire [38:0] aclkfreq = CLKFREQ;
  reg [28:0] d;
  wire [28:0] dInc = d[28] ? baud: baud - CLKFREQ;
  wire [28:0] dN = restart ? 0 : (d + dInc);
  wire fastclk = ~d[28];
  assign clk_o = fastclk;

  always @(negedge resetq or posedge clk_i)
  begin
    if (!resetq) begin
      d <= 0;
    end else begin
      d <= dN;
    end
  end
endmodule