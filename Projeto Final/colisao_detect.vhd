library ieee;
use ieee.std_logic_1164.all;

entity colisao_detect is
    port (
        posicao_x      : in std_logic_vector(6 downto 0);
        posicao_y      : in std_logic_vector(5 downto 0);
        fruta_x        : in std_logic_vector(6 downto 0);
        fruta_y        : in std_logic_vector(5 downto 0);
        colisao_fruta  : out std_logic;
        colisao_parede : out std_logic
    )
end entity;

architecture detect of colisao_detect is
    begin   
colisao_fruta <= '1' when (posicao_x = fruta_x and posicao_y = fruta_y)
                    else '0';
colisao_parede <= '1' when (posicao_x = -1 or posicao_x = 128) and (posicao_y = -1 or posicao_y = 64) -- não sei se a lógica está certa
                    else '0'; -- VERIFICAR LÓGICA DE COLISÃO COM PAREDE
end architecture;