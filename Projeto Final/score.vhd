library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity score is
    port (
        clock     : in  std_logic;
        reset     : in  std_logic;
        increment : in  std_logic; 
        pontuacao : out std_logic_vector(7 downto 0)
    );
end entity score;

architecture contagem of score is
    signal s_pontos : unsigned(7 downto 0);
begin
    process(clock, reset)
    begin
        if reset = '1' then
            s_pontos <= (others => '0');
        elsif rising_edge(clock) then
            if increment = '1' then
                s_pontos <= s_pontos + 1;
            end if;
        end if;
    end process;
    pontuacao <= std_logic_vector(s_pontos);
end architecture;
