library ieee;
use ieee.std_logic_1164.all;

entity tb_interface_leds_botoes is
end entity tb_interface_leds_botoes;

architecture sim of tb_interface_leds_botoes is

    component interface_leds_botoes is
        port (
            clock      : in  std_logic;
            reset      : in  std_logic;
            iniciar    : in  std_logic;
            resposta   : in  std_logic;
            ligado     : out std_logic;
            estimulo   : out std_logic;
            pulso      : out std_logic;
            erro       : out std_logic;
            pronto     : out std_logic;
            estado_out : out std_logic_vector(3 downto 0) -- Sinal de depuracao
        );
    end component;

    -- Sinais internos do testbench
    signal clock      : std_logic := '0';
    signal reset      : std_logic := '0';
    signal iniciar    : std_logic := '0';
    signal resposta   : std_logic := '0';
    
    signal ligado     : std_logic;
    signal estimulo   : std_logic;
    signal pulso      : std_logic;
    signal erro       : std_logic;
    signal pronto     : std_logic;
    signal estado_out : std_logic_vector(3 downto 0);

    signal keep_simulating : std_logic := '0';
    constant clockPeriod : time := 1 ms;

begin

    clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;


    -- Instanciacao do componente
    DUT: interface_leds_botoes
        port map (
            clock      => clock,
            reset      => reset,
            iniciar    => iniciar,
            resposta   => resposta,
            ligado     => ligado,
            estimulo   => estimulo,
            pulso      => pulso,
            erro       => erro,
            pronto     => pronto,
            estado_out => estado_out
        );

    -- Processo de estimulos
    stim_process : process
    begin
        keep_simulating <= '1';

        -- CASO 0: INICIALIZACAO E RESET
        reset <= '1';
        iniciar <= '0';
        resposta <= '0';
        wait for clockPeriod*2;
        reset <= '0';
        wait for clockPeriod;

        -- CASO 1: JOGADA CORRETA 
        iniciar <= '1';
        wait for clockPeriod;
        iniciar <= '0';

        wait for clockPeriod*11; 
        -- espera-se que o sinal de estímulo ligue (apos 10 periodos de clock)

        wait for clockPeriod*3; -- tempo de reacao
        resposta <= '1';
        wait for clockPeriod*5;
        resposta <= '0';

        wait for clockPeriod*3;
        -- saidas esperadas: erro = '0' e pronto = '1'

        -- CASO 2: JOGADA INVALIDA (ERRO) 
        iniciar <= '1';
        wait for clockPeriod;
        iniciar <= '0';

        wait for clockPeriod*5; 
        -- contagem do tempo de espera nao termina
        
        resposta <= '1';
        wait for clockPeriod*5;
        resposta <= '0';
        
        wait for clockPeriod*3;
        -- saidas esperadas: erro = '1', pronto = '0', pulso sempre em '0'

        -- CASO 3: RESET APOS ERRO
        reset <= '1';
        iniciar <= '0';
        resposta <= '0';
        wait for clockPeriod*2;
        reset <= '0';
        wait for clockPeriod;

        -- Fim da simulacao

        keep_simulating <= '0';

        wait;
    end process;

end architecture sim;