library ieee;
use ieee.std_logic_1164.all;

entity medidor_largura_tb is
end entity medidor_largura_tb;

architecture tb of medidor_largura_tb is

    -- Declaracao do componente principal
    component medidor_largura is
        port (
            clock        : in  std_logic;
            reset        : in  std_logic;
            liga         : in  std_logic;
            sinal        : in  std_logic;
            display0     : out std_logic_vector(6 downto 0);
            display1     : out std_logic_vector(6 downto 0);
            display2     : out std_logic_vector(6 downto 0);
            display3     : out std_logic_vector(6 downto 0);
            db_estado    : out std_logic_vector(6 downto 0);
            pronto       : out std_logic;
            fim          : out std_logic;
            db_clock     : out std_logic;
            db_sinal     : out std_logic;
            db_zeraCont  : out std_logic;
            db_contaCont : out std_logic
        );
    end component;

    -- Sinais internos
    signal clock_in       : std_logic := '0';
    signal reset_in       : std_logic := '0';
    signal liga_in        : std_logic := '0';
    signal sinal_in       : std_logic := '0';
    
    signal disp0_out      : std_logic_vector(6 downto 0);
    signal disp1_out      : std_logic_vector(6 downto 0);
    signal disp2_out      : std_logic_vector(6 downto 0);
    signal disp3_out      : std_logic_vector(6 downto 0);
    signal db_estado_out  : std_logic_vector(6 downto 0);
    
    signal pronto_out     : std_logic;
    signal fim_out        : std_logic;
    signal db_clock_out   : std_logic;
    signal db_sinal_out   : std_logic;
    signal db_zera_out    : std_logic;
    signal db_conta_out   : std_logic;

    signal keep_simulating : std_logic := '0';
    constant clockPeriod : time := 1 ms;

begin

    clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;

    -- Instanciacao do componente
    DUT: medidor_largura port map (
        clock        => clock_in,
        reset        => reset_in,
        liga         => liga_in,
        sinal        => sinal_in,
        display0     => disp0_out,
        display1     => disp1_out,
        display2     => disp2_out,
        display3     => disp3_out,
        db_estado    => db_estado_out,
        pronto       => pronto_out,
        fim          => fim_out,
        db_clock     => db_clock_out,
        db_sinal     => db_sinal_out,
        db_zeraCont  => db_zera_out,
        db_contaCont => db_conta_out
    );

    stim_process: process
    begin
        keep_simulating <= '1';

        -- Caso 0
        reset_in <= '1';
        wait for 2 ms;
        reset_in <= '0';
        wait for 2 ms;

        -- Caso 1
        liga_in <= '1';
        wait for 2 ms;
        sinal_in <= '1';
        wait for 7 ms;
        sinal_in <= '0';
        wait for 4 ms;  
        liga_in <= '0'; 
        wait for 2 ms;

        -- Caso 2
        liga_in <= '1';
        wait for 2 ms;
        sinal_in <= '1';
        wait for 31 ms;
        sinal_in <= '0';
        wait for 4 ms;
        liga_in <= '0';
        wait for 2 ms;

        -- Caso 3
        liga_in <= '1';
        wait for 2 ms;
        sinal_in <= '1';
        wait for 999 ms;
        sinal_in <= '0';
        wait for 4 ms;
        liga_in <= '0';
        wait for 2 ms;

        -- Caso 4
        liga_in <= '1';
        wait for 2 ms;
        sinal_in <= '1';
        wait for 4299 ms;
        sinal_in <= '0';
        wait for 4 ms;
        liga_in <= '0';
        wait for 2 ms;

        -- Caso 5
        liga_in <= '1';
        wait for 2 ms;
        sinal_in <= '1';
        wait for 9999 ms;
        sinal_in <= '0';
        wait for 4 ms;
        liga_in <= '0';
        wait for 2 ms;

        -- Caso 6
        liga_in <= '1';
        wait for 2 ms;
        sinal_in <= '1';
        wait for 10005 ms;
        sinal_in <= '0';
        wait for 4 ms;
        liga_in <= '0';
        wait for 2 ms;

        keep_simulating <= '0';
        
        wait;
    end process;

end architecture tb;