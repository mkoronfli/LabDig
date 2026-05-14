library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_frutas_UC is
end entity tb_frutas_UC;

architecture sim of tb_frutas_UC is

    component frutas_UC is
        port (
            clock        : in  std_logic;
            reset        : in  std_logic;
            iniciar      : in  std_logic;
            pos_valida   : in  std_logic;
            erro         : in  std_logic; 
            mostra_fruta : out std_logic;
            gera_fruta   : out std_logic;
            db_estado    : out std_logic_vector(1 downto 0)
        );
    end component;

    signal clock        : std_logic := '0';
    signal reset        : std_logic := '0';
    signal iniciar      : std_logic := '0';
    signal pos_valida   : std_logic := '0';
    signal erro         : std_logic := '0';
    
    signal mostra_fruta : std_logic;
    signal gera_fruta   : std_logic;
    signal db_estado    : std_logic_vector(1 downto 0);

    signal keep_simulating : std_logic := '0';
    constant clockPeriod   : time := 20 ns;

begin

    clock <= (not clock) and keep_simulating after clockPeriod/2;

    DUT: frutas_UC
        port map (
            clock        => clock,
            reset        => reset,
            iniciar      => iniciar,
            pos_valida   => pos_valida,
            erro         => erro,
            mostra_fruta => mostra_fruta,
            gera_fruta   => gera_fruta,
            db_estado    => db_estado
        );

    stim_process : process
    begin
        keep_simulating <= '1';

        -- CASO 0: INICIALIZACAO E RESET
        reset <= '1';
        wait for clockPeriod*2;
        reset <= '0';
        wait for clockPeriod;

        -- CASO 1: COMANDO PARA INICIAR
        iniciar <= '1';
        wait for clockPeriod;
        iniciar <= '0';
        wait for clockPeriod*4;

        -- CASO 2: POSICAO GERADA COM SUCESSO
        pos_valida <= '1';
        wait for clockPeriod;
        pos_valida <= '0';
        wait for clockPeriod*4;

        -- CASO 3: COBRA COMEU A FRUTA, REINICIA A GERACAO
        iniciar <= '1';
        wait for clockPeriod;
        iniciar <= '0';
        wait for clockPeriod*4;

        -- CASO 4: POSICAO INVALIDA / ERRO NA GERACAO
        erro <= '1';
        wait for clockPeriod;
        erro <= '0';
        wait for clockPeriod*4;

        -- Fim da simulacao
        keep_simulating <= '0';
        wait;
    end process;

end architecture sim;