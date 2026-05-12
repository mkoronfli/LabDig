library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_divider is
 generic (
 MODULO : integer := 10000000 -- modulo do contador f_FPGA/f_alvo = 50M/5
 );
 port (
 clock      : in std_logic;
 clear      : in std_logic;
 clock_slow : out std_logic;
 );
end entity clock_divider;

architecture clk_div_arch of clock_divider is
    signal IQ: integer range 0 to (MODULO - 1);
    signal clock_sig: std_logic;
    begin
        process (clock, clear, enable)
    begin
        if clear = '1' then         -- clear assincrono
            clock_sig <= 0;
            
        elsif clock'event and clock='1' then
            if enable = '1' then
                if IQ = (MODULO - 1) then
                    IQ <= 0;
                    clock_sig <= NOT clock_sig; -- inverte o clock de saida
                else
                    IQ <= IQ + 1;
                end if;
            end if;
        end if;    
    end process;	
  
    clock_slow <= clock_sig;  -- saida do clock dividido
end architecture;
