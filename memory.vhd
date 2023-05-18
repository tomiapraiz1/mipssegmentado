library STD;
use STD.textio.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_textio.all;

USE ieee.numeric_std.ALL;
--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity memory is
    generic(
        C_ELF_FILENAME    : string := "programa";
        C_MEM_SIZE        : integer := 1024
	 );
    Port ( Addr : in std_logic_vector(31 downto 0);
           DataIn : in std_logic_vector(31 downto 0);
           RdStb : in std_logic ;
           WrStb : in std_logic ;
           Clk : in std_logic ;						  
           DataOut : out std_logic_vector(31 downto 0));
end memory;

architecture mem_arq of memory is 
	
type matriz is array(0 to C_MEM_SIZE-1) of STD_LOGIC_VECTOR(7 downto 0);
signal memo: matriz;
signal aux : STD_LOGIC_VECTOR (31 downto 0):= (others=>'0'); 


begin

process (clk)
		variable cargar : boolean := true;
		variable address : STD_LOGIC_VECTOR(31 downto 0);
		variable datum : STD_LOGIC_VECTOR(31 downto 0);
		file bin_file : text is in C_ELF_FILENAME;
		variable  current_line : line;

begin
	
	if cargar then 
		-- primero iniciamos la memoria con ceros
			for i in 0 to C_MEM_SIZE-1 loop
				memo(i) <= (others => '0');
			end loop; 
			address:= (others => '0');
		-- luego cargamos el archivo en la misma
			while (not endfile (bin_file)) loop
				
				readline (bin_file, current_line);					
				--hread(current_line, address);
				hread(current_line, datum);
				assert CONV_INTEGER(address(30 downto 0))<C_MEM_SIZE 
					report "Direccion fuera de rango en el fichero de la memoria"
					severity failure;
				memo(to_integer(signed(address(30 downto 0)))) <= datum(31 downto 24);
				memo(to_integer(signed(address(30 downto 0)+'1'))) <= datum(23 downto 16);
				memo(to_integer(signed(address(30 downto 0)+"10"))) <= datum(15 downto 8);
				memo(to_integer(signed(address(30 downto 0)+"11"))) <= datum(7 downto 0);
				address := address + 4;
   		end loop;
		
			-- por ultimo cerramos el archivo y actualizamos el flag de memoria cargada
			file_close (bin_file);


			cargar := false;
	
	elsif (Clk'event and Clk = '0') then
         if (WrStb = '1') then
			memo(to_integer(signed(Addr(31 downto 0)))) <= DataIn(31 downto 24);
			memo(to_integer(signed(Addr(31 downto 0)))+1) <= DataIn(23 downto 16);
			memo(to_integer(signed(Addr(31 downto 0)))+2) <= DataIn(15 downto 8);
			memo(to_integer(signed(Addr(31 downto 0)))+3) <= DataIn(7 downto 0);
			
         elsif (RdStb = '1')then
			aux(31 downto 24) <= memo(to_integer(signed(Addr(31 downto 0))));   
			aux(23 downto 16) <= memo(to_integer(signed(Addr(31 downto 0)))+1);
			aux(15 downto 8) <= memo(to_integer(signed(Addr(31 downto 0)))+2);
			aux(7 downto 0) <= memo(to_integer(signed(Addr(31 downto 0)))+3);
         end if;
   end if;
	
  
end process;

DataOut <= aux;	 


end mem_arq;