library ieee;
use ieee.std_logic_1164.all;

entity jogo_UC is
    port (
        clock     : in  std_logic;
        reset     : in  std_logic;
        iniciar   : in  std_logic; 
        colisao   : in  std_logic; 
        cmd_telas : out std_logic_vector(1 downto 0)
    );
end entity jogo_UC;

architecture fsm of jogo_UC is
    type tipo_estado is (INICIO, JOGANDO, FIM);
    signal estado_atual, proximo_estado : tipo_estado;
begin
    process(clock, reset)
    begin
        if reset = '1' then
            estado_atual <= INICIO;
        elsif rising_edge(clock) then
            estado_atual <= proximo_estado;
        end if;
    end process;

    -- Lógica de próximo estado
    process(estado_atual, iniciar, colisao)
    begin
        case estado_atual is
            when INICIO =>
                if iniciar = '1' then proximo_estado <= JOGANDO;
                else proximo_estado <= INICIO;
                end if;
            
            when JOGANDO =>
                if colisao = '1' then proximo_estado <= FIM;
                else proximo_estado <= JOGANDO;
                end if;
            
            when FIM =>
                if iniciar = '1' then proximo_estado <= INICIO;
                else proximo_estado <= FIM;
                end if;
            
            when others =>
                proximo_estado <= INICIO;
        end case;
    end process;

    -- Lógica de saída
    cmd_telas <= "00" when estado_atual = INICIO else
                 "01" when estado_atual = JOGANDO else
                 "10";
end architecture;
