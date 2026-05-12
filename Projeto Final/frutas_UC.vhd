library ieee;
use ieee.std_logic_1164.all;

entity frutas_uc is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;
        iniciar    : in  std_logic;
        pos_valida : in  std_logic;
        erro       : in  std_logic; 
        mostra_fruta : out std_logic;
        gera_fruta : out std_logic;
        db_estado  : out std_logic_vector(1 downto 0)
    );
end entity frutas_uc;

architecture fsm of frutas_uc is
    type tipo_estado is (ESPERA, GERA, MOSTRA);
    signal estado_atual, proximo_estado : tipo_estado;
begin

    -- Memória de estado
    process(clock, reset)
    begin
        if reset = '1' then
            estado_atual <= ESPERA;
        elsif rising_edge(clock) then
            estado_atual <= proximo_estado;
        end if;
    end process;

    -- Lógica de próximo estado
    process(estado_atual, iniciar, pos_valida, erro)
    begin
        proximo_estado <= estado_atual; 
        
        case estado_atual is
            when ESPERA =>
                if iniciar = '1' then proximo_estado <= GERA; 
                end if;
            
            when GERA =>
                if pos_valida = '1' then proximo_estado <= MOSTRA;
                elsif erro = '1' then proximo_estado <= ESPERA;
                end if;
                
            when MOSTRA =>
                if iniciar = '1' then proximo_estado <= GERA; 
                end if;
                
            when others =>
                proximo_estado <= ESPERA;
        end case;
    end process;

    -- Lógica de saída
    with estado_atual select
        gera_fruta <= '1' when GERA,
                      '0' when others;

    with estado_atual select
        mostra_fruta <= '1' when MOSTRA,
                      '0' when others;

    with estado_atual select
        db_estado <= "00" when ESPERA,  
                     "01" when GERA,
                     "10" when MOSTRA,
                     "11" when others;

end architecture;
