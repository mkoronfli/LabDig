library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_gerador_de_frutas is
end entity tb_gerador_de_frutas;

architecture sim of tb_gerador_de_frutas is

    component gerador_de_frutas is
        port (
            clock        : in  std_logic;
            reset        : in  std_logic;
            iniciar_jogo : in  std_logic; 
            posicao_x    : in  std_logic_vector(6 downto 0);
            posicao_y    : in  std_logic_vector(5 downto 0);
            fruta_x      : out std_logic_vector(6 downto 0);
            fruta_y      : out std_logic_vector(5 downto 0);
            db_estado    : out std_logic_vector(1 downto 0)
        );
    end component;

    signal clock        : std_logic := '0';
    signal reset        : std_logic := '0';
    signal iniciar_jogo : std_logic := '0'; 
    signal posicao_x    : std_logic_vector(6 downto 0) := (others => '0');
    signal posicao_y    : std_logic_vector(5 downto 0) := (others => '0');
    
    signal fruta_x      : std_logic_vector(6 downto 0);
    signal fruta_y      : std_logic_vector(5 downto 0);
    signal db_estado    : std_logic_vector(1 downto 0);

    signal keep_simulating : std_logic := '0';
    constant clockPeriod   : time := 20 ns;

begin

    clock <= (not clock) and keep_simulating after clockPeriod/2;

    DUT: gerador_de_frutas
        port map (
            clock        => clock,
            reset        => reset,
            iniciar_jogo => iniciar_jogo, 
            posicao_x    => posicao_x,
            posicao_y    => posicao_y,
            fruta_x      => fruta_x,
            fruta_y      => fruta_y,
            db_estado    => db_estado
        );

    stim_process : process
    begin
        keep_simulating <= '1';

        -- CASO 0: INICIALIZACAO E RESET
        reset <= '1';
        iniciar_jogo <= '0';
        posicao_x <= "0100000"; 
        posicao_y <= "010000";  
        wait for clockPeriod*2;
        reset <= '0';
        wait for clockPeriod;

        -- NOVO: PONTAPÉ INICIAL PARA A PRIMEIRA FRUTA
        iniciar_jogo <= '1';
        wait for clockPeriod;
        iniciar_jogo <= '0';
        wait for clockPeriod*5;

        -- CASO 1: OBSERVAR A GERAÇÃO DE COORDENADAS
        wait for clockPeriod*20;

        -- CASO 2: SIMULAR MOVIMENTO DA COBRA
        posicao_x <= "0100001"; wait for clockPeriod*2;
        posicao_x <= "0100010"; wait for clockPeriod*2;
        posicao_y <= "010001";  wait for clockPeriod*10;

        -- CASO 3: SIMULAR COLISÃO COM A FRUTA (COBRA COME A FRUTA)
        posicao_x <= fruta_x;
        posicao_y <= fruta_y;
        wait for clockPeriod*5;
        
        posicao_x <= "0000000";
        posicao_y <= "000000";
        wait for clockPeriod*20;

        -- Fim da simulacao
        keep_simulating <= '0';
        wait;
    end process;

end architecture sim;
