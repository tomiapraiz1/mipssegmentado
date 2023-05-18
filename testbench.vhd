-- Title       : Test Bench for procesador
-- Design      : practica_1
-- Author      : alumnoeps
-- Company     : eps
--
---------------------------------------------------------------------------------------------------
--
-- File        : $DSN\src\TestBench\procesador_TB.vhd
-- Generated   : 15/03/2006, 15:43
-- From        : $DSN\src\procesador.vhd
-- By          : Active-HDL Built-in Test Bench Generator ver. 1.2s
--
---------------------------------------------------------------------------------------------------
--
-- Description : Automatically generated Test Bench for procesador_tb
--
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; 
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

	-- Add your library and packages declaration here ...

entity processor_tb is
end processor_tb;

architecture processor_tb_arq  of processor_tb is
	-- Component declaration of the tested unit
	component processor
   port(
   	  Clk         : in  std_logic;
	   Reset       : in  std_logic;
      -- Instruction memory
	   I_Addr      : out std_logic_vector(31 downto 0);
	   I_RdStb     : out std_logic;
	   I_WrStb     : out std_logic;
	   I_DataOut   : out std_logic_vector(31 downto 0);
	   I_DataIn    : in  std_logic_vector(31 downto 0);
	   -- Data memory
	   D_Addr      : out std_logic_vector(31 downto 0);
	   D_RdStb     : out std_logic;
	   D_WrStb   : out std_logic;
	   D_DataOut   : out std_logic_vector(31 downto 0);
	   D_DataIn    : in  std_logic_vector(31 downto 0)
   );
	end component;

	component Memory
	generic (
	   C_ELF_FILENAME     : string; --iria program1
      C_MEM_SIZE         : integer
   );
	port (
		Clk                : in std_logic;			 
		Addr               : in std_logic_vector(31 downto 0);
		RdStb              : in std_logic;
		WrStb              : in std_logic;
		DataIn             : in std_logic_vector(31 downto 0);
		DataOut            : out std_logic_vector(31 downto 0)
	);
   end component;

	signal Clk         : std_logic;
	signal Reset       : std_logic;
   -- Instruction memory
	signal I_Addr      : std_logic_vector(31 downto 0);
	signal I_RdStb     : std_logic;
	signal I_WrStb     : std_logic;
	signal I_DataOut   : std_logic_vector(31 downto 0);
	signal I_DataIn    : std_logic_vector(31 downto 0);
	-- Data memory
	signal D_Addr      : std_logic_vector(31 downto 0);
	signal D_RdStb     : std_logic;
	signal D_WrStb     : std_logic;
	signal D_DataOut   : std_logic_vector(31 downto 0);
	signal D_DataIn    : std_logic_vector(31 downto 0);		  
	
	constant tper_clk  : time := 50 ns;
	constant tdelay    : time := 120 ns; -- antes 150, sino no enta direccion 0

begin
	  
	-- Unit Under Test port map
	UUT : processor
		port map (
			Clk             => Clk,
			Reset           => Reset,
			-- Instruction memory
	      I_Addr          => I_Addr,
  	      I_RdStb         => I_RdStb,
	      I_WrStb         => I_WrStb,
	      I_DataOut       => I_DataOut,
	      I_DataIn        => I_DataIn,
	      -- Data memory
	      D_Addr          => D_Addr,
  	      D_RdStb         => D_RdStb,
	      D_WrStb         => D_WrStb,
	      D_DataOut       => D_DataOut,
	      D_DataIn        => D_DataIn
		);

	Instruction_Mem_inst : memory
	generic map (
	   C_ELF_FILENAME     => "program1",
      C_MEM_SIZE         => 1024
   )
	port map (
		Clk                => Clk,			 
		Addr               => I_Addr,
		RdStb              => I_RdStb,
		WrStb              => I_WrStb,
		DataIn             => I_DataOut,
		DataOut            => I_DataIn
	);
	
	Data_Mem_inst : memory
	generic map (
	   C_ELF_FILENAME     => "data",
     C_MEM_SIZE         => 1024
   )	
	port map(
		Clk                => Clk,			 
		Addr               => D_Addr,
		RdStb              => D_RdStb,
		WrStb              => D_WrStb,
		DataIn             => D_DataOut,
		DataOut            => D_DataIn
	);

	process	
	begin		
	   Clk <= '0';
		wait for tper_clk/2;
		Clk <= '1';
		wait for tper_clk/2; 		
	end process;
	
	process
	begin
		Reset <= '1';
		wait for tdelay;
		Reset <= '0';
		wait;
	end process;  	 

end processor_tb_arq;


configuration testbench_for_procesador of processor_tb is
	for processor_tb_arq
		for UUT : processor
			use entity work.processor(processor);
		end for;
	end for;
end testbench_for_procesador;

--181.29.118.137