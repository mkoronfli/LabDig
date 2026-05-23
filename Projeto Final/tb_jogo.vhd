library ieee;
use ieee.std_logic_1164.all;

entity tb_jogo is
end entity tb_jogo;

architecture sim of tb_jogo is

    component jogo is
        port (
            clock    : in  std_logic;
            reset    : in  std_logic;
            botoes   : in  std_logic_vector(4 downto 0);
            oled_scl : out std_logic;
            oled_sda : out std_logic
        );
    end component;

    signal clock    : std_logic := '0';
    signal reset    : std_logic := '0';
    signal botoes   : std_logic_vector(4 downto 0) := (others => '0'); 
    
    signal oled_scl : std_logic;
    signal oled_sda : std_logic;
    
    constant clockPeriod   : time := 20 ns; -- 50 MHz
    signal keep_simulating : std_logic := '1';

begin

    clock <= (not clock) and keep_simulating after clockPeriod / 2;

    DUT: jogo
        port map (
            clock    => clock,
            reset    => reset,
            botoes   => botoes,
            oled_scl => oled_scl,
            oled_sda => oled_sda
        );

    stim_process: process
    begin
        keep_simulating <= '1';

        -- CASO 0: Reset e Inicializacao
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        
        -- Aguarda o tempo inicial do display e da logica
        wait for 2 ms; 

        -- CASO 1: Iniciar o jogo
        botoes(4) <= '1';
        wait for 500 ns;
        botoes(4) <= '0';
        
        wait for 15 ms;

        -- CASO 2: Virar para baixo
        botoes(1) <= '1';
        wait for 500 ns;
        botoes(1) <= '0';
        
        wait for 15 ms;
        
        -- CASO 3: Virar para a direita
        botoes(3) <= '1';
        wait for 500 ns;
        botoes(3) <= '0';
        
        wait for 15 ms;

        keep_simulating <= '0';
        wait;
    end process;

end architecture sim;
