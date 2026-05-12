library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity max_score is
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
        score_atual   : in  std_logic_vector(7 downto 0);
        max_score_out : out std_logic_vector(7 downto 0)
    );
end entity max_score;

architecture comportamento of max_score is
    signal s_max_score : unsigned(7 downto 0);
begin
    process(clock, reset)
    begin
        if reset = '1' then
            s_max_score <= (others => '0');
        elsif rising_edge(clock) then
            if unsigned(score_atual) > s_max_score then
                s_max_score <= unsigned(score_atual);
            end if;
        end if;
    end process;
    
    max_score_out <= std_logic_vector(s_max_score);
end architecture;
