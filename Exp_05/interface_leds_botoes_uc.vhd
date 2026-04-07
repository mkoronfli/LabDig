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
    type state_type is (INICIAL, ESPERA, MEDE, FINAL, INVALIDA);
    signal state, next_state : state_type;
begin

    -- Memoria de estado
    process(clock, reset)
    begin
        if reset = '1' then
            state <= INICIAL;
        elsif rising_edge(clock) then
            state <= next_state;
        end if;
    end process;

    -- Logica de proximo estado
    process(state, iniciar, resposta, rco)
    begin
        next_state <= state; 
        
        case state is
            when INICIAL =>
                if iniciar = '1' then next_state <= ESPERA; end if;
            
            when ESPERA =>
                if resposta = '1' then next_state <= INVALIDA;
                elsif rco = '1' then next_state <= MEDE;       
                end if;
                
            when MEDE =>
                if resposta = '1' then next_state <= FINAL; end if;
                
            when FINAL =>
                next_state <= INICIAL; 
                
            when INVALIDA =>
                if resposta = '0' then next_state <= INICIAL; end if;
                
            when others =>
                next_state <= INICIAL;
        end case;
    end process;

    -- Logica de saoda
    process(state)
    begin
        zeraCont  <= '0';
        contaCont <= '0';
        ligado    <= '0';
        estimulo  <= '0';
        erro      <= '0';
        pronto    <= '0';
        estado    <= "0000"; 

        case state is
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
                estado   <= "0011";
                
            when FINAL =>
                ligado   <= '1';
                estimulo <= '1';
                pronto   <= '1';
                estado   <= "0100";
                
            when INVALIDA =>
                erro   <= '1';
                estado <= "0101";
                
        end case;
    end process;

end architecture fsm;
