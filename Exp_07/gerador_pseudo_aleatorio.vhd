library ieee;
use ieee.std_logic_1164.all;

entity gerador_pseudo_aleatorio is
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        lfsr_out : out std_logic_vector(2 downto 0)
    );
end entity;

architecture gerador of gerador_pseudo_aleatorio is
    signal s_lfsr : std_logic_vector(2 downto 0) := "011"; -- maximo 15 períodos de clock
begin
    process(clock, reset)
    begin
        if reset = '1' then
            s_lfsr <= "011";
        elsif rising_edge(clock) then
            s_lfsr <= (s_lfsr(0) xor s_lfsr(2)) & s_lfsr(2 downto 1);
        end if;
    end process;

-- state proibido = "000"
    lfsr_out <= s_lfsr;
end architecture;
