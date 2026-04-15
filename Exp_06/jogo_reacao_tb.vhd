library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jogo_reacao_tb is
end entity jogo_reacao_tb;

architecture sim of jogo_reacao_tb is

    component jogo_reacao is
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        jogar    : in  std_logic;
        resposta : in  std_logic;
        display0 : out std_logic_vector(6 downto 0);
        display1 : out std_logic_vector(6 downto 0);
        display2 : out std_logic_vector(6 downto 0);
        display3 : out std_logic_vector(6 downto 0);
        ligado   : out std_logic;
        pulso    : out std_logic;
        estimulo : out std_logic;
        erro     : out std_logic;
        pronto   : out std_logic;
		db_estado: out std_logic_vector(3 downto 0)
    );
    end component;

    -- Sinais internos do testbench
    signal clock      : std_logic := '0';
    signal reset      : std_logic := '0';
    signal jogar    : std_logic := '0';
    signal resposta   : std_logic := '0';
    
    signal ligado     : std_logic;
    signal pulso      : std_logic;
    signal estimulo   : std_logic;
    signal erro       : std_logic;
    signal pronto     : std_logic;
    signal db_estado : std_logic_vector(3 downto 0);

    signal display0 : std_logic_vector(6 downto 0);
    signal display1 : std_logic_vector(6 downto 0);
    signal display2 : std_logic_vector(6 downto 0);
    signal display3 : std_logic_vector(6 downto 0);

    signal keep_simulating : std_logic := '0';
    constant clockPeriod : time := 1 ms;

begin

    clock <= (not clock) and keep_simulating after clockPeriod/2;


    -- Instanciacao do componente
    DUT: jogo_reacao
        port map (
            clock      => clock,
            reset      => reset,
            jogar      => jogar,
            resposta   => resposta,
            display0   => display0,
            display1   => display1,
            display2   => display2,
            display3   => display3,
            ligado     => ligado,
            estimulo   => estimulo,
            pulso      => pulso,
            erro       => erro,
            pronto     => pronto,
            db_estado  => db_estado 
        );

    -- Processo de estimulos
    stim_process : process
    begin
        keep_simulating <= '1';

        -- CASO 0: INICIALIZACAO E RESET
        reset <= '1';
        jogar <= '0';
        resposta <= '0';
        wait for clockPeriod*2;
        reset <= '0';
        wait for clockPeriod;

        -- CASO 1: JOGADA CORRETA 
        jogar <= '1';
        wait for clockPeriod;
        jogar <= '0';

        wait for clockPeriod*5000; 
        -- espera-se que o sinal de estímulo ligue (apos 5 segundos)

        wait for clockPeriod*800; -- tempo de reacao
        resposta <= '1';
        wait for clockPeriod*100;
        resposta <= '0';

        wait for clockPeriod*3;
        -- saidas esperadas: erro = '0' e pronto = '1' o tamanho do pulso deve ser de 800

        -- CASO 2: JOGADA INVALIDA (ERRO) 
        jogar <= '1';
        wait for clockPeriod;
        jogar <= '0';
        

        wait for clockPeriod*3000; 
        -- contagem do tempo de espera nao termina
        
        resposta <= '1';
        wait for clockPeriod*100;
        resposta <= '0';
        
        wait for clockPeriod*3;
        -- saidas esperadas: erro = '1', pronto = '0', pulso sempre em '0'

        -- Fim da simulacao

        keep_simulating <= '0';

        wait;
    end process;

end architecture sim;