library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_posicao is
end entity tb_posicao;

architecture sim of tb_posicao is

    component posicao is
        port (
            clock_slow : in  std_logic;
            reset      : in  std_logic;
            btn_up     : in  std_logic;
            btn_down   : in  std_logic;
            btn_left   : in  std_logic;
            btn_right  : in  std_logic;
            pos_x      : out std_logic_vector(6 downto 0);
            pos_y      : out std_logic_vector(5 downto 0)
        );
    end component;

    -- Sinais internos do testbench
    signal clock_slow : std_logic := '0';
    signal reset      : std_logic := '0';
    signal btn_up     : std_logic := '0';
    signal btn_down   : std_logic := '0';
    signal btn_left   : std_logic := '0';
    signal btn_right  : std_logic := '0';
    
    signal pos_x      : std_logic_vector(6 downto 0);
    signal pos_y      : std_logic_vector(5 downto 0);

    signal keep_simulating : std_logic := '0';
    constant clockPeriod   : time := 1 ms;
begin

    clock_slow <= (not clock_slow) and keep_simulating after clockPeriod/2;

    DUT: posicao
        port map (
            clock_slow => clock_slow,
            reset      => reset,
            btn_up     => btn_up,
            btn_down   => btn_down,
            btn_left   => btn_left,
            btn_right  => btn_right,
            pos_x      => pos_x,
            pos_y      => pos_y
        );

    stim_process : process
    begin
        keep_simulating <= '1';

        -- CASO 0: INICIALIZACAO E RESET
        reset <= '1';
        wait for clockPeriod*2;
        reset <= '0';
        wait for clockPeriod;

        -- CASO 1: MOVIMENTO PADRAO PARA DIREITA
        wait for clockPeriod*3;

        -- CASO 2: MUDAR DIRECAO PARA BAIXO
        btn_down <= '1';
        wait for clockPeriod;
        btn_down <= '0';
        wait for clockPeriod*3;

        -- CASO 3: TENTATIVA DE MOVIMENTO INVALIDO (CIMA ENQUANTO VAI PARA BAIXO)
        btn_up <= '1';
        wait for clockPeriod;
        btn_up <= '0';
        -- Direção não deve mudar, continua indo para baixo
        wait for clockPeriod*3;

        -- CASO 4: MUDAR DIRECAO PARA ESQUERDA
        btn_left <= '1';
        wait for clockPeriod;
        btn_left <= '0';
        -- X deve começar a decrementar
        wait for clockPeriod*3;

        -- Fim da simulacao
        keep_simulating <= '0';
        wait;
    end process;

end architecture sim;
