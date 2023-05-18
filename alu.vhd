library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std_unsigned.all;


Entity alu is 
  port (a:in std_logic_vector(31 downto 0);
  b:in std_logic_vector(31 downto 0);
  sel:in std_logic_vector(2 downto 0);
  o:out std_logic_vector(31 downto 0);
  zero:out std_logic);
end alu;

architecture Aalu of alu is

signal result:std_logic_vector(31 downto 0);

begin
	process(sel,a,b)
	begin 
		case(sel) is
			when  "000"=> result <= a and b;
      		when "001"=> result <= a or b;
      		when "010"=> result <=a + b;
      		when "110"=>result <=a - b;
      		when "111"=>
              if(a<b) then
                  result <= x"00000001";
              else
                  result <=x"00000000";
              end if;
       		when "100"=> result <= b(15 downto 0) & x"0000";
       		when others=> result <=x"00000000";
		end case;
    end process;
    
    o<=result;
    
    process(result)
    begin
    	if( result = x"00000000") then
        	zero<='1';
         else
         	zero<='0';
         end if;
     end process;
end Aalu;