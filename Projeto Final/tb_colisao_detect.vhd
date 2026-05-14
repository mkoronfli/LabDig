library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_colisao_detect is
end entity tb_colisao_detect;

architecture sim of tb_colisao_detect is

    component colisao_detect is
        port (
            posicao_x      : in std_logic_vector(6 downto 0);
            posicao_y      : in std_logic_vector(5 downto 0);
            fruta_x        : in std_logic_vector(6 downto 0);
            fruta_y        : in std_logic_vector(5 downto 0);
            colisao_fruta  : out std_logic;
            colisao_parede : out std_logic
        );
    end component;

    signal posicao_x : std_logic_vector(6 downto 0) := (others => '0');
    signal posicao_y : std_logic_vector(5 downto 0) := (others => '0');
    signal fruta_x   : std_logic_vector(6 downto 0) := (others => '0');
    signal fruta_y   : std_logic_vector(5 downto 0) := (others => '0');
    
    signal colisao_fruta  : std_logic;
    signal colisao_parede : std_logic;

    signal keep_simulating : std_logic := '0';
    constant clockPeriod   : time := 20 ns;

begin

    process
    begin
        if keep_simulating = '1' then
            wait for clockPeriod/2;
        else
            wait;
        end if;
    end process;

    DUT: colisao_detect
        port map (
            posicao_x      => posicao_x,
            posicao_y      => posicao_y,
            fruta_x        => fruta_x,
            fruta_y        => fruta_y,
            colisao_fruta  => colisao_fruta,
            colisao_parede => colisao_parede
        );

    stim_process : process
    begin
        keep_simulating <= '1';

        -- CASO 0: POSICAO SEGURA E SEM FRUTA
        posicao_x <= "0001010"; -- X = 10
        posicao_y <= "001010";  -- Y = 10
        fruta_x   <= "0010100"; -- X = 20
        fruta_y   <= "010100";  -- Y = 20
        wait for clockPeriod*5;

        -- CASO 1: COLISAO COM A FRUTA
        posicao_x <= "0010100"; -- X = 20
        posicao_y <= "010100";  -- Y = 20
        wait for clockPeriod*5;

        fruta_x <= "0000101";
        wait for clockPeriod*2;

        -- CASO 2: COLISAO COM PAREDE DIREITA
        posicao_x <= "1111111";
        posicao_y <= "001010";
        wait for clockPeriod*5;

        -- CASO 3: COLISAO COM PAREDE SUPERIOR
        posicao_x <= "0111111";
        posicao_y <= "000000";
        wait for clockPeriod*5;

        -- Fim da simulacao
        keep_simulating <= '0';
        wait;
    end process;

end architecture sim;
