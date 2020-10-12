library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY seg73 IS
   PORT (
      clk            : IN std_logic;   
      rst            : IN std_logic;  
	   img	 			: IN std_logic_vector(7 DOWNTO 0);  -- image position
		track				: IN std_logic_vector(7 DOWNTO 0);  -- track position
		CPU_addr			: In std_logic_vector(15 DOWNTO 0); -- cpu address
      dataout        : OUT std_logic_vector(7 DOWNTO 0); -- led 7 SEGMENT'S + DOT
      U2_138_select  : OUT std_logic  ;  -- Digital tube enable control    
      U3_138_select  : OUT std_logic ;   -- dot array  enable control
      U2_138_A       : OUT std_logic_vector(2 DOWNTO 0)); -- Digital tube enable address control   
END seg73;

ARCHITECTURE arch OF seg73 IS
	signal div_cnt 	: std_logic_vector(23 downto 0 );
	signal data4 		: std_logic_vector(3 downto 0);
	signal dataout_xhdl1 : std_logic_vector(7 downto 0);
	signal en_xhdl 	: std_logic_vector(2 downto 0);	

begin
  dataout <= dataout_xhdl1;
  U2_138_A <= en_xhdl;
  U2_138_select <= '1' ; -- Digital tube  work
  U3_138_select <= '0' ; -- dot array not work

 process(clk,rst)
 begin
   if(rst='1')then 
		div_cnt <= "000000000000000000000000"; 
   elsif(clk'event and clk='1')then      
		div_cnt <= div_cnt+1;                   
   end if;
 end process;

---****************��ʾ����***************--

 process(rst,clk,div_cnt(19 downto 18))
 begin
  if(rst='1')then
    en_xhdl<="111";
  elsif (clk'event and clk='1') then
		en_xhdl<= div_cnt(19 downto 17) ; 
  end if;

 end process;

process(en_xhdl,img,track,cpu_addr)
begin
 case en_xhdl is 
   when "000"  => data4 <= img(3 downto 0);
   when "001"  => data4 <= img(7 downto 4);
   when "010"  => data4 <= track(3 downto 0);
   when "011"  => data4 <= track(7 downto 4);   
	when "100"  => data4 <= cpu_addr(3 downto 0); 
	when "101"  => data4 <= cpu_addr(7 downto 4); 
	when "110"  => data4 <= cpu_addr(11 downto 8); 
	when "111"  => data4 <= cpu_addr(15 downto 12); 
	
   when others => data4 <= "1111";
  end case;
end process;

process(data4)
begin
  case data4 is
			WHEN "0000" =>        --  Dp G F E D C B A 
                  dataout_xhdl1 <= "11000000";    
         WHEN "0001" =>	
                  dataout_xhdl1 <= "11111001";    
         WHEN "0010" =>	-- 2		
                  dataout_xhdl1 <= "10100100";    
         WHEN "0011" =>   -- 3
                  dataout_xhdl1 <= "10110000";    
         WHEN "0100" => -- 4
                  dataout_xhdl1 <= "10011001";    
         WHEN "0101" =>
                  dataout_xhdl1 <= "10010010";    
         WHEN "0110" =>  -- 6
                  dataout_xhdl1 <= "10000010";    
         WHEN "0111" =>
                  dataout_xhdl1 <= "11111000";    
         WHEN "1000" =>  -- 8
                  dataout_xhdl1 <= "10000000";    
         WHEN "1001" =>   -- 9
                  dataout_xhdl1 <= "10010000";    
         WHEN "1010" =>  -- A 
                  dataout_xhdl1 <= "10001000";    
         WHEN "1011" =>  -- B
                  dataout_xhdl1 <= "10000011";    
         WHEN "1100" => -- C 
                  dataout_xhdl1 <= "11000110";    
         WHEN "1101" => -- D
                  dataout_xhdl1 <= "10100001";
         WHEN "1110" => -- E
                  dataout_xhdl1 <= "10000110";    
         WHEN "1111" => -- F
                  dataout_xhdl1 <= "10001110";    
         WHEN OTHERS =>
						dataout_xhdl1 <= "01000000"; -- " - "         
      END CASE;
   END PROCESS;
end arch;
