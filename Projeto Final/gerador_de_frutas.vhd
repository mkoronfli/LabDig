library ieee;
use ieee.std_logic_1164.all;

entity gerador_de_frutas is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;
        posicao_x  : in  std_logic_vector(6 downto 0);
        posicao_y  : in  std_logic_vector(5 downto 0);
        fruta_x    : out std_logic_vector(6 downto 0);
        fruta_y    : out std_logic_vector(5 downto 0);
        db_estado  : out std_logic_vector(1 downto 0)
    );
end entity;

architecture gerador of gerador_de_frutas is

component lfsr_parametrizado is
    generic (
        N : integer
    );
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        enable   : in  std_logic;
        lfsr_out : out std_logic_vector(N-1 downto 0)
    );
end component;

component frutas_UC is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;
        iniciar    : in  std_logic;
        pos_valida : in  std_logic;
        erro       : in  std_logic; 
        mostra_fruta : out std_logic;
        gera_fruta : out std_logic;
        db_estado  : out std_logic_vector(1 downto 0)
    );
end component;

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

-- sinais internos de ligacao
    signal sig_lfsr_out_x : std_logic_vector(6 downto 0);
    signal sig_lfsr_out_y : std_logic_vector(5 downto 0);
    signal sig_fruit_eaten  : std_logic;
    signal sig_pos_valida : std_logic;
    signal sig_erro : std_logic;
    signal sig_gera_fruta : std_logic;
    signal sig_mostra_fruta : std_logic;

begin

sig_pos_valida <= '1' when (sig_fruit_eaten = '0' and sig_erro = '0') else '0';

ALEATORIO_X: lfsr_parametrizado
    generic map (N => 7)
    port map (
        clock => clock,
        reset => reset,
        enable => sig_gera_fruta,
        lfsr_out => sig_lfsr_out_x
    );

ALEATORIO_Y: lfsr_parametrizado
    generic map (N => 6)
    port map (
        clock => clock,
        reset => reset,
        enable => sig_gera_fruta,
        lfsr_out => sig_lfsr_out_y
    );

UC: frutas_UC
    port map (
        clock => clock,
        reset => reset,
        iniciar => sig_fruit_eaten,
        pos_valida => sig_pos_valida,
        erro => sig_erro,
        gera_fruta => sig_gera_fruta,
        mostra_fruta => sig_mostra_fruta,
        db_estado => db_estado
    );

COLISAO: colisao_detect
    port map (
        posicao_x => posicao_x,
        posicao_y => posicao_y,
        fruta_x => sig_lfsr_out_x,
        fruta_y => sig_lfsr_out_y,
        colisao_fruta => sig_fruit_eaten,
        colisao_parede => sig_erro
    );

-- logica de saidas
    fruta_x <= sig_lfsr_out_x when sig_mostra_fruta = '1' else (others => '0');
    fruta_y <= sig_lfsr_out_y when sig_mostra_fruta = '1' else (others => '0');

end architecture;
