library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_display_control is
end entity tb_display_control;

architecture sim of tb_display_control is

    component display_control is
        port (
            clock         : in  std_logic;
            reset         : in  std_logic;
            cmd_telas     : in  std_logic_vector(1 downto 0);
            pos_x         : in  std_logic_vector(6 downto 0);
            pos_y         : in  std_logic_vector(5 downto 0);
            fruta_x       : in  std_logic_vector(6 downto 0);
            fruta_y       : in  std_logic_vector(5 downto 0);
            score         : in  std_logic_vector(7 downto 0);
            oled_scl      : out std_logic;
            oled_sda      : out std_logic
        );
    end component;

    signal clock         : std_logic := '0';
    signal reset         : std_logic := '0';
    signal cmd_telas     : std_logic_vector(1 downto 0) := "00";
    signal pos_x         : std_logic_vector(6 downto 0) := (others => '0');
    signal pos_y         : std_logic_vector(5 downto 0) := (others => '0');
    signal fruta_x       : std_logic_vector(6 downto 0) := (others => '0');
    signal fruta_y       : std_logic_vector(5 downto 0) := (others => '0');
    signal score         : std_logic_vector(7 downto 0) := (others => '0');
    
    signal oled_scl      : std_logic;
    signal oled_sda      : std_logic;

    signal keep_simulating : std_logic := '0';
    constant clockPeriod   : time := 20 ns; -- 50 MHz

begin

    clock <= (not clock) and keep_simulating after clockPeriod/2;

    DUT: display_control
        port map (
            clock         => clock,
            reset         => reset,
            cmd_telas     => cmd_telas,
            pos_x         => pos_x,
            pos_y         => pos_y,
            fruta_x       => fruta_x,
            fruta_y       => fruta_y,
            score         => score,
            oled_scl      => oled_scl,
            oled_sda      => oled_sda
        );

    stim_process : process
    begin
        keep_simulating <= '1';

        -- CASO 0: RESET E INICIALIZAÇÃO DO OLED
        reset <= '1';
        cmd_telas <= "00"; -- Tela de Menu/Espera
        wait for clockPeriod*5;
        reset <= '0';
        
        wait for 2 ms;

        -- CASO 1: MUDANÇA PARA A TELA DE JOGO E DESENHO
        pos_x   <= "0100000";
        pos_y   <= "010000"; 
        fruta_x <= "0110010"; 
        fruta_y <= "011000"; 
        score   <= "00000101";
        
        cmd_telas <= "01";
        
        wait for 3 ms;

        -- CASO 2: GAME OVER
        cmd_telas <= "10";
        wait for 1 ms;

        -- Fim da simulacao
        keep_simulating <= '0';
        wait;
    end process;

end architecture sim;
