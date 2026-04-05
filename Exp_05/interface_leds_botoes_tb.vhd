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
            estado_out : out std_logic_vector(3 downto 0) -- Sinal de depuração
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

    constant CLK_PERIOD : time := 1 sec;

begin

    -- Instanciação do componente
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

    -- Geração do sinal de Clock (1 Hz)
    clk_process : process
    begin
        clock <= '0';
        wait for CLK_PERIOD / 2;
        clock <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Processo de estímulos
    stim_process : process
    begin
        -- INICIALIZAÇÃO E RESET
        reset <= '1';
        iniciar <= '0';
        resposta <= '0';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD;

        -- CASO 1: JOGADA CORRETA 
        iniciar <= '1';
        wait for CLK_PERIOD;
        iniciar <= '0';

        wait for CLK_PERIOD * 11; 
        
        
        wait for CLK_PERIOD * 3;
        resposta <= '1';
        wait for CLK_PERIOD;
        
        resposta <= '0';
        
        wait for CLK_PERIOD * 3;

        -- CASO 2: JOGADA INVÁLIDA (ERRO) 
        iniciar <= '1';
        wait for CLK_PERIOD;
        iniciar <= '0';
        
        wait for CLK_PERIOD * 4;
        
        resposta <= '1';
        
        wait for CLK_PERIOD * 4;
        
        resposta <= '0';
        
        wait for CLK_PERIOD * 3;

        -- Fim da simulação
        wait;
    end process;

end architecture sim;