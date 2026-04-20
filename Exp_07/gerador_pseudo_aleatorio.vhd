library ieee;
use ieee.std_logic_1164.all;

entity gerador_pseudo_aleatorio is
    port is (
        enable: in std_logic;
	    lfsr_state : in std_logic_vector(2 downto 0) := "011"; -- maximo 15 períodos de clock
	    lfsr_out : out std_logic_vector(2 downto 0)
    );
end entity;

architecture gerador of gerador_pseudo_aleatorio is
    signal xor_result;

    begin
        xor_result <= lfsr_state(0) XOR lfsr_state(2); -- state proibido = 000
        lfsr_out <= xor_result & lfsr_state(2 downto 1) when enable = '1';
end architecture;