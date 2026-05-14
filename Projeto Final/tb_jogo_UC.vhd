library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_jogo_UC is
end entity tb_jogo_UC;

architecture sim of tb_jogo_UC is

    component jogo_UC is
        port (
            clock     : in  std_logic;
            reset     : in  std_logic;
            iniciar   : in  std_logic;
            colisao   : in  std_logic;
            cmd_telas : out std_logic_vector(1 downto 0)
        );
    end component;

    -- Sinais internos do testbench
    signal clock     : std_logic := '0';
    signal reset     : std_logic := '0';
    signal iniciar   : std_logic := '0';
    signal colisao   : std_logic := '0';
    
    signal cmd_telas : std_logic_vector(1 downto 0);

    signal keep_simulating : std_logic := '0';
    constant clockPeriod   : time := 20 ns;

begin

    clock <= (not clock) and keep_simulating after clockPeriod/2;

    DUT: jogo_UC
        port map (
            clock     => clock,
            reset     => reset,
            iniciar   => iniciar,
            colisao   => colisao,
            cmd_telas => cmd_telas
        );

    stim_process : process
    begin
        keep_simulating <= '1';

        -- CASO 0: INICIALIZACAO E RESET (ESTADO: INICIO)
        reset   <= '1';
        iniciar <= '0';
        colisao <= '0';
        wait for clockPeriod*2;
        reset   <= '0';
        wait for clockPeriod;

        -- CASO 1: BOTAO INICIAR (ESTADO: JOGANDO)
        iniciar <= '1';
        wait for clockPeriod;
        iniciar <= '0';
        wait for clockPeriod*5;

        -- CASO 2: COLISAO DETECTADA (ESTADO: FIM)
        colisao <= '1';
        wait for clockPeriod;
        colisao <= '0';
        wait for clockPeriod*5;

        -- CASO 3: REINICIAR POS FIM DE JOGO (ESTADO: INICIO)
        iniciar <= '1';
        wait for clockPeriod;
        iniciar <= '0';
        wait for clockPeriod*5;

        -- Fim da simulacao
        keep_simulating <= '0';
        wait;
    end process;

end architecture sim;
