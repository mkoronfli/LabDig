library ieee;
use ieee.std_logic_1164.all;

entity gerador_de_frutas is
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        posicao_x  : in  std_logic_vector(1 downto 0);
        posicao_y  : in  std_logic_vector(1 downto 0);
        fruta_x    : out std_logic_vector(1 downto 0);
        fruta_y    : out std_logic_vector(1 downto 0);
    );
end entity;

component lfsr_parametrizado is
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        lfsr_out : out std_logic_vector(2 downto 0)
    );
end component;

component frutas_UC is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;
        iniciar    : in  std_logic;
        pos_valida : in  std_logic;
        erro       : in  std_logic; 
        gera_fruta : out std_logic;
        db_estado  : out std_logic_vector(1 downto 0)
    );
end component;

component colisao_detect is
    port (
        posicao_x      : in std_logic_vector(1 downto 0);
        posicao_y      : in std_logic_vector(1 downto 0);
        fruta_x        : in std_logic_vector(1 downto 0);
        fruta_y        : in std_logic_vector(1 downto 0);
        colisao_fruta  : out std_logic;
        colisao_parede : out std_logic
    );
end component;

architecture gerador of gerador_de_frutas is
end architecture;
