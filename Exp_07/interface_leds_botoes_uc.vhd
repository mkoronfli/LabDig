library ieee;
use ieee.std_logic_1164.all;

entity interface_leds_botoes_uc is
    port (
        clock     : in  std_logic;
        reset     : in  std_logic;
        iniciar   : in  std_logic;
        resposta  : in  std_logic;
        rco       : in  std_logic; 
        zeraCont  : out std_logic;
        contaCont : out std_logic;
        ligado    : out std_logic;
        estimulo  : out std_logic;
        erro      : out std_logic;
        pronto    : out std_logic;
        estado    : out std_logic_vector(3 downto 0)
    );
end entity interface_leds_botoes_uc;

architecture fsm of interface_leds_botoes_uc is
    type tipo_estado is (INICIAL, ESPERA, MEDE, FINAL, INVALIDA);
    signal estado_atual, proximo_estado : tipo_estado;
begin

    -- Memória de estado
    process(clock, reset)
    begin
        if reset = '1' then
            estado_atual <= INICIAL;
        elsif rising_edge(clock) then
            estado_atual <= proximo_estado;
        end if;
    end process;

    -- Lógica de próximo estado
    process(estado_atual, iniciar, resposta, rco)
    begin
        proximo_estado <= estado_atual; 
        
        case estado_atual is
            when INICIAL =>
                if iniciar = '1' then proximo_estado <= ESPERA; end if;
            
            when ESPERA =>
                if resposta = '1' then proximo_estado <= INVALIDA;
                elsif rco = '1' then proximo_estado <= MEDE;       
                end if;
                
            when MEDE =>
                if resposta = '1' then proximo_estado <= FINAL; end if;
                
            when FINAL =>
                if reset = '1' then proximo_estado <= INICIAL; end if;
                
            when INVALIDA =>
                if resposta = '0' then proximo_estado <= INICIAL; end if;
                
            when others =>
                proximo_estado <= INICIAL;
        end case;
    end process;

    -- Lógica de saída
    with estado_atual select
        zeraCont <= '1' when INICIAL,
                    '0' when others;

    with estado_atual select
        contaCont <= '1' when ESPERA,
                     '0' when others;

    with estado_atual select
        ligado <= '1' when ESPERA | MEDE | FINAL,
                  '0' when others;

    with estado_atual select
        estimulo <= '1' when MEDE | FINAL,
                    '0' when others;

    with estado_atual select
        erro <= '1' when INVALIDA,
                '0' when others;

    with estado_atual select
        pronto <= '1' when FINAL,
                  '0' when others;

    with estado_atual select
        estado <= "0001" when INICIAL,
                  "0010" when ESPERA,
                  "0100" when MEDE,
                  "1000" when FINAL,
                  "1111" when INVALIDA,
                  "0000" when others;

end architecture fsm;
