library ieee;
use ieee.std_logic_1164.all;

entity input_filter is
    port (
        clock    : in  std_logic;
        btn_in   : in  std_logic;
        btn_out  : out std_logic
    );
end entity input_filter;

architecture debounce of input_filter is
    signal shift_reg : std_logic_vector(3 downto 0) := "0000";
begin
    process(clock)
    begin
        if rising_edge(clock) then
            shift_reg <= shift_reg(2 downto 0) & btn_in;
        end if;
    end process;
    btn_out <= '1' when shift_reg = "1111" else '0';
end architecture;
