library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jogo_reacao_tb is
end entity jogo_reacao_tb;

architecture sim of jogo_reacao_tb is

    component jogo_reacao is
        port (
            clock      : in  std_logic;
            reset      : in  std_logic;
            jogar      : in  std_logic;
            resposta_1 : in  std_logic; -- Adaptado para 2 jogadores
            resposta_2 : in  std_logic; -- Adaptado para 2 jogadores
            display0   : out std_logic_vector(6 downto 0);
            display1   : out std_logic_vector(6 downto 0);
            display2   : out std_logic_vector(6 downto 0);
            display3   : out std_logic_vector(6 downto 0);
            display5   : out std_logic_vector(6 downto 0); -- Novo display do vencedor
            ligado     : out std_logic;
            pulso      : out std_logic;
            estimulo   : out std_logic;
            erro       : out std_logic;
            pronto     : out std_logic;
            db_estado  : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Sinais internos do testbench
    signal clock      : std_logic := '0';
    signal reset      : std_logic := '0';
    signal jogar      : std_logic := '0';
    signal resposta_1 : std_logic := '0';
    signal resposta_2 : std_logic := '0';
    
    signal ligado     : std_logic;
    signal pulso      : std_logic;
    signal estimulo   : std_logic;
    signal erro       : std_logic;
    signal pronto     : std_logic;
    signal db_estado  : std_logic_vector(3 downto 0);

    signal display0 : std_logic_vector(6 downto 0);
    signal display1 : std_logic_vector(6 downto 0);
    signal display2 : std_logic_vector(6 downto 0);
    signal display3 : std_logic_vector(6 downto 0);
    signal display5 : std_logic_vector(6 downto 0);

    signal keep_simulating : std_logic := '0';
    constant clockPeriod : time := 1 ms;

begin

    clock <= (not clock) and keep_simulating after clockPeriod/2;

    DUT: jogo_reacao
        port map (
            clock      => clock,
            reset      => reset,
            jogar      => jogar,
            resposta_1 => resposta_1,
            resposta_2 => resposta_2,
            display0   => display0,
            display1   => display1,
            display2   => display2,
            display3   => display3,
            display5   => display5,
            ligado     => ligado,
            estimulo   => estimulo,
            pulso      => pulso,
            erro       => erro,
            pronto     => pronto,
            db_estado  => db_estado 
        );

    stim_process : process
    begin
        keep_simulating <= '1';

        -- CASO 0: INICIALIZACAO E RESET
        reset <= '1';
        jogar <= '0';
        resposta_1 <= '0';
        resposta_2 <= '0';
        wait for clockPeriod*2;
        reset <= '0';
        wait for clockPeriod;

        -- CASO 1: JOGADA CORRETA (J1 ganha de J2)
        jogar <= '1';
        wait for clockPeriod;
        jogar <= '0';

        wait until estimulo = '1';

        -- Tempo de reacao do J1: 400 ms
        wait for clockPeriod*400; 
        resposta_1 <= '1';
        wait for clockPeriod*10;
        resposta_1 <= '0';

        -- Tempo de reacao do J2: 600 ms
        wait for clockPeriod*190;
        resposta_2 <= '1';
        wait for clockPeriod*10;
        resposta_2 <= '0';
        
        wait for clockPeriod*10;
        -- Saidas esperadas: erro = '0', pronto = '1', display5 deve mostrar '1' e display0-3 mostram "0400"

        reset <= '1';
        wait for clockPeriod*2;
        reset <= '0';
        wait for clockPeriod;

        -- CASO 2: JOGADA INVALIDA (ERRO DO JOGADOR 2) 
        jogar <= '1';
        wait for clockPeriod;
        jogar <= '0';
        
        wait for clockPeriod*500; 
        
        resposta_2 <= '1'; 
        wait for clockPeriod*10;
        resposta_2 <= '0';
        
        wait for clockPeriod*10;
        -- Saidas esperadas: erro = '1', pronto = '0', pulso sempre em '0', displays mostram 9999 e display5 apaga

        -- Fim da simulacao
        keep_simulating <= '0';
        wait;
    end process;

end architecture sim;
