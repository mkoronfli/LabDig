library ieee;
use ieee.std_logic_1164.all;


entity semaforo_uc is
port (
    clock : in std_logic;
    reset : in std_logic;
    rco_vermelho : in std_logic; -- Final do tempo do estado vermelho (5 sec)
    rco_amarelo : in std_logic; -- Final do tempo do estado amarelo (2 sec)
    rco_verde : in std_logic; -- Final do tempo do estado verde (4 sec)
    en_vermelho : out std_logic; -- Enable do Contador de tempo do estado vermelho
    en_amarelo : out std_logic; -- Enable do Contador de tempo do estado amarelo
    en_verde : out std_logic; -- Enable do Contador de tempo do estado verde
    clr_vermelho : out std_logic; -- Clear do contador de tempo do estado vermelho
    clr_amarelo : out std_logic; -- Clear do contador de tempo do estado amarelo
    clr_verde : out std_logic -- Clear do contador de tempo do estado verde
);
end entity semaforo_uc;

architecture arch of semaforo_uc is
    type tipo_Estado is (vermelho, amarelo, verde);
    signal E_ant, E_prox: tipo_Estado;
begin
    -- MudanÃ§a de estado
    process (clock, reset)
    begin  
        if reset = '1' then
            E_ant <= vermelho;
        elsif clock'event and clock = '1' then 
            E_ant <= E_prox;
        end if;
    end process;

    -- Logica de proximo estado
    process (E_ant, rco_vermelho, rco_verde, rco_amarelo)
    begin
        case E_ant is 
            when vermelho => if rco_vermelho = '1' then E_prox <= verde;
                            else                        E_prox <= vermelho;
                            end if;
            when amarelo => if rco_amarelo = '1' then E_prox <= vermelho;
                            else                        E_prox <= amarelo;
                            end if;
            when verde => if rco_verde = '1' then E_prox <= amarelo;
                            else                        E_prox <= verde;
                            end if;
        end case;
    end process;

    -- Logica de saida
    -- Liga o enable e desliga o clear quando chega no estado correspondente
    
    with E_ant select en_vermelho<=
        '1' when vermelho,
        '0' when others;
    with E_ant select clr_vermelho<=
        '0' when vermelho,
        '1' when others;

    with E_ant select en_amarelo<=
        '1' when amarelo,
        '0' when others;
    with E_ant select clr_amarelo<=
        '0' when amarelo,
        '1' when others;

    with E_ant select en_verde<=
        '1' when verde,
        '0' when others;
    with E_ant select clr_verde<=
        '0' when verde,
        '1' when others;

end architecture;
