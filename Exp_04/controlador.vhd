library ieee;
use ieee.std_logic_1164.all;


entity controlador is
    port (
        clock : in std_logic;
        reset : in std_logic;
        liga : in std_logic;
        sinal : in std_logic;
        zeraCont : out std_logic;
        contaCont : out std_logic;
        pronto : out std_logic;
        db_estado : out std_logic_vector(3 downto 0) -- sinal de depuracao
    );
end entity controlador;

architecture controle of controlador is
    type tipo_Estado is (INICIAL, LIGADO, PREPARA, CONTA, FIM, ESPERA);
    signal E_ant, E_prox: tipo_Estado;
begin
    -- Mudanca de estado
    process (clock, reset)
    begin  
        if reset = '1' then
            E_ant <= INICIAL;
        elsif clock'event and clock = '1' then 
            E_ant <= E_prox;
        end if;
    end process;

    -- Logica de proximo estado
    process (E_ant, liga, sinal)
    begin
        case E_ant is 
            when INICIAL => if liga = '1' then E_prox <= LIGADO;
                            else                        E_prox <= INICIAL;
                            end if;
            when LIGADO => if sinal = '1' then E_prox <= PREPARA;
                            else                        E_prox <= LIGADO;
                            end if;
            when PREPARA => E_prox <= CONTA;
            when CONTA => if sinal = '0' then E_prox <= FIM;
                            else                        E_prox <= CONTA;
                            end if;
            when FIM => E_prox <= ESPERA;
            when ESPERA => if (sinal = '0') AND (liga = '1') then E_prox <= ESPERA;
                            elsif (sinal = '1') AND (liga = '1') then E_prox <= PREPARA;
                            else                        E_prox <= INICIAL;
                            end if;
        end case;
    end process;

    -- Logica de saida
    
    with E_ant select zeraCont<=
        '1' when PREPARA,
        '0' when others;
    
    with E_ant select contaCont<=
        '1' when CONTA,
        '0' when others;

    with E_ant select pronto<=
        '1' when FIM,
        '0' when others;

    with E_ant select db_estado<=
        "0001" when INICIAL,
        "0010" when LIGADO,
        "0011" when PREPARA,
        "0100" when CONTA,
        "0101" when FIM,
        "0110" when ESPERA,
        "0000" when others; -- caso haja algum problema e nao caia em nenhum estado


end architecture;
