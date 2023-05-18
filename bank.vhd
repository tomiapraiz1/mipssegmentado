library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std_unsigned.all;

entity bank is
port (clk, reset, wr : in std_logic;
reg1_rd, reg2_rd, reg_wr : in std_logic_vector(4 downto 0);
data_wr : in std_logic_vector(31 downto 0);
data1_rd, data2_rd : out std_logic_vector(31 downto 0));
end bank;

architecture bregistros of bank is
--definicion de un array de 32 registros de 32 bits
type regs_type is array (31 downto 0) of std_logic_vector(31 downto 0);

signal regs : regs_type;

begin
	escritura: process (clk, reset)
    begin
        if (reset='1') then
            regs <= (others => x"00000000");
        else if (falling_edge(clk) and wr='1' and (reg_wr /= "00000")) then
            regs(to_integer(unsigned(reg_wr))) <= data_wr;
            end if;
        end if;
    end process;

    lectura: process (reg1_rd, reg2_rd)
    begin
        data1_rd <= regs(to_integer(unsigned(reg1_rd)));
        data2_rd <= regs(to_integer(unsigned(reg2_rd)));       
    end process;
end bregistros;