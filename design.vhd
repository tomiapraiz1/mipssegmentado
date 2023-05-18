library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity processor is
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
	D_WrStb     : out std_logic;
	D_DataOut   : out std_logic_vector(31 downto 0);
	D_DataIn    : in  std_logic_vector(31 downto 0)
);
end processor;

architecture processor_arq of processor is 

--Señales del PC
signal  IF_pcIn:std_logic_vector(31 downto 0);
signal  IF_pcOut:std_logic_vector(31 downto 0);

--Señales del pipe IF/ID
signal  IFID_instr:std_logic_vector(31 downto 0);
signal  IFID_nextPC:std_logic_vector(31 downto 0);

--PC + 4
signal  IF_nextPC:std_logic_vector(31 downto 0);

--Mux IF
signal IF_pcSRC:std_logic;

--Banco de registros
component bank
port (clk, reset, wr : in std_logic;
reg1_rd, reg2_rd, reg_wr : in std_logic_vector(4 downto 0);
data_wr : in std_logic_vector(31 downto 0);
data1_rd, data2_rd : out std_logic_vector(31 downto 0));
end component;

--Señales del banco de registros
signal  ID_data1_rd:std_logic_vector(31 downto 0);
signal  ID_data2_rd:std_logic_vector(31 downto 0);

--Señales de la unidad de control
signal ID_control_RegWrite : std_logic; --escribo en el registro
signal ID_control_MemToReg : std_logic; --pasa de memoria al registro
signal ID_control_Branch : std_logic; --salta
signal ID_control_MemRead : std_logic; --lee la memoria
signal ID_control_MemWrite : std_logic; --escribe la memoria
signal ID_control_AluOP : std_logic_vector(1 downto 0); --que hace la alu
signal ID_control_RegDest : std_logic; --tiene como destino un registro
signal ID_control_AluSrc : std_logic; --

--Señal del signo extendido
signal ID_SignExt : std_logic_vector(31 downto 0);

--Señales de ID/EX
    signal IDEX_PcNext : std_logic_vector(31 downto 0);
    signal IDEX_SignExt : std_logic_vector(31 downto 0);
    signal IDEX_reg1_rd : std_logic_vector(31 downto 0);
    signal IDEX_reg2_rd : std_logic_vector(31 downto 0);
    signal IDEX_RegDst : std_logic;
    signal IDEX_Branch : std_logic;
    signal IDEX_MemRead : std_logic;
    signal IDEX_MemToReg : std_logic;
    signal IDEX_AluOp : std_logic_vector(1 downto 0);
    signal IDEX_RegWrite : std_logic;
    signal IDEX_AluSrc : std_logic;
    signal IDEX_MemWrite : std_logic;
    signal IDEX_rd : std_logic_vector(4 downto 0);
    signal IDEX_rt : std_logic_vector(4 downto 0);

--ALU
component alu 
  port (a: in std_logic_vector(31 downto 0);
  b: in std_logic_vector(31 downto 0);
  sel: in std_logic_vector(2 downto 0);
  o:  out std_logic_vector(31 downto 0);
  zero: out std_logic);
end component;

--Señales de la etapa EX
signal EX_AluControl : std_logic_vector(2 downto 0);
signal EX_AluMUX : std_logic_vector(31 downto 0);
signal EX_AluResult : std_logic_vector(31 downto 0);
signal EX_AluZero : std_logic;
signal EX_RegDstMux : std_logic_vector(4 downto 0);

--Señales del pipeline EX/MEM
signal EXMEM_Branch : std_logic;
signal EXMEM_MemRead : std_logic;
signal EXMEM_MemWrite : std_logic;
signal EXMEM_MemToReg : std_logic;
signal EXMEM_RegWrite : std_logic;
signal EXMEM_Condition : std_logic;
signal EXMEM_reg2_rd : std_logic_vector(31 downto 0);
signal EXMEM_AluResult : std_logic_vector(31 downto 0);
signal EXMEM_RegDst : std_logic_vector(4 downto 0);

--Señales del pipeline MEM/WB
signal MEMWB_RegWrite : std_logic;
signal MEMWB_MemToReg : std_logic;
signal MEMWB_MemData : std_logic_vector(31 downto 0);
signal MEMWB_Address : std_logic_vector(31 downto 0);
signal MEMWB_RegDst : std_logic_vector(4 downto 0);

--Señal de la etapa WB
signal WB_MuxWBResult : std_logic_vector(31 downto 0);

begin

--ETAPA ID

PC_REG:process(Clk,Reset)
begin
	if Reset = '1' then 
    	IF_pcOut <=(others =>'0');
        IF_pcSRC <= '0';
    	else if rising_edge(Clk) then
        	IF_pcOut<=IF_pcIn;
    	end if;
	end if;
end process;

IF_nextPC <= IF_pcOut + 4;
IF_pcIn <= IF_nextPC when IF_pcSRC = '0'
	else IFID_nextPC + (ID_SignExt(29 downto 0) & "00"); 
I_Addr <= IF_pcOut;
I_DataOut <= x"00000000";
I_WrStb <= '0'; --siempre en 0 para no escribir
I_RdStb <= '1'; --siempre en 1 para leer

--Pipeline IF/ID

PipeIFID:process(Clk,Reset)
begin
	if Reset ='1' then
    	IFID_instr<=(others =>'0');
        IFID_nextPC<=(others =>'0');
     	else if rising_edge(Clk) then
            IFID_instr<=I_DataIn when IF_pcSRC = '0'
            	else x"00000000"; --flush del pipe IF/ID
            IFID_nextPC<=IF_nextPC;
     	end if;
	end if;
end process;

--ETAPA ID

reg_bank:bank port map(clk => Clk, reset => Reset, wr => MEMWB_RegWrite,
			reg1_rd => IFID_instr(25 downto 21), --rs
            reg2_rd => IFID_instr(20 downto 16), --rt
            reg_wr => MEMWB_RegDst, 
            data_wr => WB_MuxWBResult, --resultado del mux del WB lo ponemos en el banco
            data1_rd => ID_data1_rd, --salidas del banco de registros
            data2_rd => ID_data2_rd
            );
            
--Unidad de control

control:process(IFID_instr(31 downto 26))
begin
    case (IFID_instr(31 downto 26)) is
        when "000000" => --tipo R
            ID_control_RegDest <= '1';
            ID_control_AluSrc <= '0';
            ID_control_MemToReg <= '0';
            ID_control_RegWrite <= '1';
            ID_control_MemRead <= '0';
            ID_control_MemWrite <= '0';
            ID_control_Branch <= '0';
            ID_control_AluOP <= "10";
        when "100011" => --LW
            ID_control_RegDest <= '0';
            ID_control_AluSrc <= '1';
            ID_control_MemToReg <= '1';
            ID_control_RegWrite <= '1';
            ID_control_MemRead <= '1';
            ID_control_MemWrite <= '0';
            ID_control_Branch <= '0';
            ID_control_AluOP <= "00";
        when "101011" => --SW
            ID_control_RegDest <= 'X';
            ID_control_AluSrc <= '1';
            ID_control_MemToReg <= 'X';
            ID_control_RegWrite <= '0';
            ID_control_MemRead <= '0';
            ID_control_MemWrite <= '1';
            ID_control_Branch <= '0';
            ID_control_AluOP <= "00";
        when "000100" => --BEQ
            ID_control_RegDest <= 'X';
            ID_control_AluSrc <= '0';
            ID_control_MemToReg <= 'X';
            ID_control_RegWrite <= '0';
            ID_control_MemRead <= '0';
            ID_control_MemWrite <= '0';
            ID_control_Branch <= '1';
            ID_control_AluOP <= "01";
        when "001111" => -- LUI
            ID_control_RegDest   <= '1';
            ID_control_AluSrc   <= '1';
            ID_control_MemToReg <= '1';
            ID_control_RegWrite <= '1';
            ID_control_MemRead  <= '1';
            ID_control_MemWrite <= '0';
            ID_control_Branch   <= '0';
            ID_control_AluOp    <= "11";
        when others =>
            ID_control_RegDest <= '0';
            ID_control_AluSrc <= '0';
            ID_control_MemToReg <= '0';
            ID_control_RegWrite <= '0';
            ID_control_MemRead <= '0';
            ID_control_MemWrite <= '0';
            ID_control_Branch <= '0';
            ID_control_AluOP <= "00";
        end case;
end process;

selMuxID:process(ID_control_Branch)
begin
	if (ID_control_Branch = '1') then
    	if (ID_data1_rd = ID_data2_rd) then
        	IF_pcSRC <= '1';
        end if;
    else
    	IF_pcSRC <= '0';
    end if;
end process;

--Extension de signo

ID_SignExt <= x"0000" & IFID_instr(15 downto 0) when (IFID_instr(15) = '0') 
            else  (x"FFFF" & IFID_instr(15 downto 0));

--Pipe ID/EX

pipeIDEX:process (clk,reset)
begin
	if (reset = '1') then 
    	IDEX_PcNext <= (others => '0');
        IDEX_reg1_rd <=(others => '0');
        IDEX_reg2_rd <=(others => '0');
        IDEX_rt <= (others => '0');
        IDEX_SignExt <=(others => '0');
        IDEX_rd <= (others => '0');
        IDEX_RegDst <= '0';
        IDEX_AluSrc <= '0';
        IDEX_AluOp <= "00";
        IDEX_Branch <= '0';
        IDEX_MemWrite <='0';
        IDEX_MemRead <= '0';
        IDEX_MemToReg <= '0';
        IDEX_RegWrite <='0';
	elsif (rising_edge(clk)) then
        IDEX_RegDst <= ID_control_RegDest;
        IDEX_AluSrc <= ID_control_AluSrc;
        IDEX_AluOp <= ID_control_AluOp;
        IDEX_Branch <= ID_control_Branch; --no se si hay que seguir pasandolo
        IDEX_MemWrite <= ID_control_MemWrite;
        IDEX_MemRead <= ID_control_MemRead;
        IDEX_MemToReg <= ID_control_MemToReg;
        IDEX_RegWrite <= ID_control_RegWrite;
        IDEX_PcNext <= IFID_NextPC;
        IDEX_rt <= IFID_instr(20 downto 16);
        IDEX_rd <= IFID_instr(15 downto 11);
        IDEX_SignExt <= ID_SignExt;
		IDEX_reg1_rd <= ID_data1_rd; 
        IDEX_reg2_rd <= ID_data2_rd;
	end if;
end process;

--ETAPA EX

EX_AluMux <= IDEX_reg2_rd when (IDEX_AluSrc = '0') else IDEX_SignExt;

--ALU control

alucontrol:process (IDEX_SignExt(5 downto 0), IDEX_AluOp)
        begin
             case(IDEX_AluOp) is
                when "10" =>
                    case (IDEX_SignExt(5 downto 0)) is 
                        when "100000"=>  --ADD                  
                            EX_AluControl <= "010";   
                        when"100010" => --SUB
                            EX_AluControl <= "110";
                        when "100100" => -- AND
                            EX_AluControl <= "000";
                        when "100101" => -- OR
                            EX_AluControl <= "001";
                        when "101010" => -- SLT
                            EX_AluControl <= "111";
                        when others => 
                            EX_AluControl <= "000";
                    end case;
                when "11" =>  --LUI
                    EX_AluControl <= "100";
                when "01" =>  --BEQ
                    EX_AluControl <= "110";
                when "00" =>  -- LW/SW
                    EX_AluControl <= "010";
                when others =>  
                    EX_AluControl <= "000"; 
            end case;   
        end process;

--Instanciacion de la ALU

ALU_EX : alu port map(
        a => IDEX_reg1_rd,
        b => EX_AluMux,
        sel =>  EX_AluControl,
        o => EX_AluResult,
        zero => EX_AluZero
        );
        
--MUX que decide que registro escribir

EX_RegDstMux <= IDEX_rt when (IDEX_RegDst = '0') else IDEX_rd;

--Pipe EX/MEM

pipeEXMEM:process (clk,reset)
    begin
        if (reset = '1') then
            EXMEM_Branch <= '0';
            EXMEM_MemRead <= '0';
            EXMEM_MemWrite <= '0';
            EXMEM_MemToReg <= '0'; 
            EXMEM_RegWrite <= '0';
            EXMEM_Condition <= '0';
            EXMEM_AluResult <= (others => '0');
            EXMEM_reg2_rd <= (others => '0');
            EXMEM_RegDst <= (others => '0');
        elsif (rising_edge(clk)) then
            EXMEM_Branch <= IDEX_Branch ;
            EXMEM_MemRead <=IDEX_MemRead;
            EXMEM_MemWrite <= IDEX_MemWrite; 
            EXMEM_MemToReg <= IDEX_MemToReg; 
            EXMEM_RegWrite <= IDEX_RegWrite ;
            EXMEM_Condition <= EX_AluZero;
            EXMEM_AluResult <= EX_AluResult;
            EXMEM_reg2_rd <= IDEX_reg2_rd; 
            EXMEM_RegDst <= EX_RegDstMux;
        end if;
    end process;

--Etapa MEM

D_Addr <= EXMEM_AluResult;
D_DataOut <= EXMEM_reg2_rd;
D_RdStb <= EXMEM_MemRead;
D_WrStb <= EXMEM_MemWrite;

--Pipeline MEM/WB

pipeMEWWB:process(clk,reset)
    begin
        if (reset = '1') then
            MEMWB_MemToReg <= '0';
            MEMWB_RegWrite <= '0';
            MEMWB_MemData <= (others => '0');
            MEMWB_Address <= (others => '0');
            MEMWB_RegDst <= (others => '0');
        elsif (rising_edge(clk)) then
            MEMWB_MemToReg <= EXMEM_MemToReg;
            MEMWB_RegWrite <= EXMEM_RegWrite; 
            MEMWB_MemData <= D_DataIn ;
            MEMWB_Address <= EXMEM_AluResult;
            MEMWB_RegDst <= EXMEM_RegDst;
        end if;
    end process;
    
--Etapa WB

WB_MuxWbResult <= MEMWB_MemData when (MEMWB_MemToReg = '1') else MEMWB_Address;

end processor_arq;