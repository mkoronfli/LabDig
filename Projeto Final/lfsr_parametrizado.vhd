library ieee;
use ieee.std_logic_1164.all;

entity lfsr_parametrizado is 
    generic (
        N : integer := 7
    );
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        enable   : in  std_logic;
        lfsr_out : out std_logic_vector(N-1 downto 0)
    );
end entity;

architecture gerador of lfsr_parametrizado is
    signal s_lfsr : std_logic_vector(N-1 downto 0) := (others => '1');
begin
    process(clock, reset)
    begin
        if reset = '1' then
            s_lfsr <= (others => '1');
        elsif rising_edge(clock) then
            if enable = '1' then
                s_lfsr <= (s_lfsr(N-2 downto 0) & (s_lfsr(N-1) xor s_lfsr(N-2)));
            end if;
        end if;
    end process;
    
    lfsr_out <= s_lfsr;
end architecture;
