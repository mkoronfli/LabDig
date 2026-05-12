library ieee;
use ieee.std_logic_1164.all;

entity posicao is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;
        botao_up   : in  std_logic;
        botao_down : in  std_logic;
        botao_left : in  std_logic;
        botao_right : in  std_logic;
        posicao_x  : out  std_logic_vector(6 downto 0);
        posicao_y  : out  std_logic_vector(5 downto 0);
    )
end entity posicao;

architecture behavioral of posicao is
    signal x : std_logic_vector(6 downto 0) := (others => '0');
    signal y : std_logic_vector(5 downto 0) := (others => '0');
    signal direcao : std_logic_vector(1 downto 0) := (others => '0'); -- 00: cima, 01: direita, 10: esquerda, 11: baixo

begin
    process(clock, reset)
    begin
        if reset = '1' then
            x <= "1000000"; -- Começa no meio da tela
            y <= "100000"; -- Começa no meio da tela
        end if;
        if rising_edge(clock) then
            if botao_up = '1' then
                direcao <= "00";
            elsif botao_right = '1' then
                direcao <= "01";
            elsif botao_left = '1' then
                direcao <= "10";
            elsif botao_down = '1' then
                direcao <= "11";
            else -- Se nenhum botão for pressionado, mantém a direção atual
                direcao <= direcao;
            end if;
    end process;

    process(clock)
    begin
        case direcao is
        when "00" => -- cima
            y <= std_logic_vector(unsigned(y) - 1);
        when "01" => -- direita
            x <= std_logic_vector(unsigned(x) + 1);
        when "10" => -- esquerda
            x <= std_logic_vector(unsigned(x) - 1);
        when "11" => -- baixo
            y <= std_logic_vector(unsigned(y) + 1);
        when others =>
            null;
    end case;
end process;

    posicao_x <= x;
    posicao_y <= y;

end architecture behavioral;