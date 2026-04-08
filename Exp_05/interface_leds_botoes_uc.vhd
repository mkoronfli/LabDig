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
                proximo_estado <= INICIAL; 
                
            when INVALIDA =>
                if resposta = '0' then proximo_estado <= INICIAL; end if;
                
            when others =>
                proximo_estado <= INICIAL;
        end case;
    end process;

    -- Lógica de saída
    process(estado_atual)
    begin
        zeraCont  <= '0';
        contaCont <= '0';
        ligado    <= '0';
        estimulo  <= '0';
        erro      <= '0';
        pronto    <= '0';
        estado    <= "0000"; 

        case estado_atual is
            when INICIAL =>
                zeraCont <= '1';
                estado   <= "0001";
                
            when ESPERA =>
                ligado    <= '1';
                contaCont <= '1';
                estado    <= "0010";
                
            when MEDE =>
                ligado   <= '1';
                estimulo <= '1';
                estado   <= "0100";
                
            when FINAL =>
                ligado   <= '1';
                estimulo <= '1';
                pronto   <= '1';
                estado   <= "1000";
                
            when INVALIDA =>
                erro   <= '1';
                estado <= "1111";
                
        end case;
    end process;

end architecture fsm;
