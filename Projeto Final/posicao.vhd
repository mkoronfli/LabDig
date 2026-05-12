library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity posicao is
    port (
        clock_slow : in  std_logic;
        reset      : in  std_logic;
        btn_up     : in  std_logic;
        btn_down   : in  std_logic;
        btn_left   : in  std_logic;
        btn_right  : in  std_logic;
        pos_x      : out std_logic_vector(6 downto 0);
        pos_y      : out std_logic_vector(5 downto 0)
    );
end entity posicao;

architecture mov of posicao is
    type direcao_t is (CIMA, BAIXO, ESQUERDA, DIREITA);
    signal dir_atual : direcao_t := DIREITA;
    signal s_pos_x   : unsigned(6 downto 0) := to_unsigned(64, 7); -- Centro
    signal s_pos_y   : unsigned(5 downto 0) := to_unsigned(32, 6); -- Centro
begin
    process(clock_slow, reset)
    begin
        if reset = '1' then
            dir_atual <= DIREITA;
            s_pos_x   <= to_unsigned(64, 7);
            s_pos_y   <= to_unsigned(32, 6);
        elsif rising_edge(clock_slow) then
            -- Tratamento de direção
            if btn_up = '1' and dir_atual /= BAIXO then dir_atual <= CIMA;
            elsif btn_down = '1' and dir_atual /= CIMA then dir_atual <= BAIXO;
            elsif btn_left = '1' and dir_atual /= DIREITA then dir_atual <= ESQUERDA;
            elsif btn_right = '1' and dir_atual /= ESQUERDA then dir_atual <= DIREITA;
            end if;

            -- Movimento da cabeça
            case dir_atual is
                when CIMA     => s_pos_y <= s_pos_y - 1;
                when BAIXO    => s_pos_y <= s_pos_y + 1;
                when ESQUERDA => s_pos_x <= s_pos_x - 1;
                when DIREITA  => s_pos_x <= s_pos_x + 1;
            end case;
        end if;
    end process;
    pos_x <= std_logic_vector(s_pos_x);
    pos_y <= std_logic_vector(s_pos_y);
end architecture;
