library ieee;
use ieee.std_logic_1164.all;

entity score is
    port (
        clock : in std_logic;
        reset : in std_logic;
        incrementa : in std_logic;
        score_out : out std_logic_vector(7 downto 0);
        max_score : out std_logic_vector(7 downto 0)
    )
end entity score;

architecture arch of score is
    signal score : std_logic_vector(7 downto 0) := (others => '0');

begin
    process(clock, reset)
    begin
        if reset = '1' then
            score <= (others => '0');
        elsif rising_edge(clock) then
            if incrementa = '1' then
                score <= std_logic_vector(unsigned(score) + 1);
            end if;
        end if;
    end process;

    score_out <= score;
    max_score <= score when score > max_score 
                else max_score;
end arch ; -- arch