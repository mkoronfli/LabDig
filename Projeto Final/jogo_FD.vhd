library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity jogo_FD is
    port (
        clock       : in  std_logic;
        clock_slow  : in  std_logic;
        reset       : in  std_logic;
        comandos_uc : in  std_logic_vector(1 downto 0); 
        btn_up      : in  std_logic;
        btn_down    : in  std_logic;
        btn_left    : in  std_logic;
        btn_right   : in  std_logic;
        perdeu_jogo : out std_logic;
        out_pos_x   : out std_logic_vector(6 downto 0);
        out_pos_y   : out std_logic_vector(5 downto 0);
        out_fruta_x : out std_logic_vector(6 downto 0);
        out_fruta_y : out std_logic_vector(5 downto 0);
        out_score   : out std_logic_vector(7 downto 0);
        out_max_score : out std_logic_vector(7 downto 0)
    );
end entity jogo_FD;

architecture estrutural of jogo_FD is
    signal s_pos_x, s_fruta_x : std_logic_vector(6 downto 0);
    signal s_pos_y, s_fruta_y : std_logic_vector(5 downto 0);
    signal s_score            : std_logic_vector(7 downto 0);
    signal s_max_score        : std_logic_vector(7 downto 0);
    signal s_colisao_fruta    : std_logic;
    signal s_colisao_parede   : std_logic;
    signal s_reset_logic      : std_logic;
    signal s_iniciar_jogo     : std_logic; 

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

    component colisao_detect is
        port (
            posicao_x      : in  std_logic_vector(6 downto 0);
            posicao_y      : in  std_logic_vector(5 downto 0);
            fruta_x        : in  std_logic_vector(6 downto 0);
            fruta_y        : in  std_logic_vector(5 downto 0);
            colisao_fruta  : out std_logic;
            colisao_parede : out std_logic
        );
    end component;

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

    component score is
        port (
            clock     : in  std_logic;
            reset     : in  std_logic;
            increment : in  std_logic;
            pontuacao : out std_logic_vector(7 downto 0)
        );
    end component;

    component max_score is
        port (
            clock         : in  std_logic;
            reset         : in  std_logic;
            score_atual   : in  std_logic_vector(7 downto 0);
            max_score_out : out std_logic_vector(7 downto 0)
        );
    end component;

begin

    s_reset_logic <= '1' when comandos_uc = "00" else reset;
    s_iniciar_jogo <= '1' when comandos_uc = "01" else '0';
    
    perdeu_jogo   <= s_colisao_parede;

    out_pos_x     <= s_pos_x;
    out_pos_y     <= s_pos_y;
    out_fruta_x   <= s_fruta_x;
    out_fruta_y   <= s_fruta_y;
    out_score     <= s_score;
    out_max_score <= s_max_score;

    POS: posicao
        port map (
            clock_slow => clock_slow,
            reset      => s_reset_logic,
            btn_up     => btn_up,
            btn_down   => btn_down,
            btn_left   => btn_left,
            btn_right  => btn_right,
            pos_x      => s_pos_x,
            pos_y      => s_pos_y
        );

    -- Deteção de Colisões
    COL: colisao_detect
        port map (
            posicao_x      => s_pos_x,
            posicao_y      => s_pos_y,
            fruta_x        => s_fruta_x,
            fruta_y        => s_fruta_y,
            colisao_fruta  => s_colisao_fruta,
            colisao_parede => s_colisao_parede
        );

    -- Gerador Pseudo-aleatório
    GEN_FRUTA: gerador_de_frutas
        port map (
            clock        => clock,
            reset        => s_reset_logic,
            iniciar_jogo => s_iniciar_jogo,
            posicao_x    => s_pos_x,
            posicao_y    => s_pos_y,
            fruta_x      => s_fruta_x,
            fruta_y      => s_fruta_y,
            db_estado    => open
        );

    -- Registo de Pontuação Atual
    SC: score
        port map (
            clock     => clock,
            reset     => s_reset_logic,
            increment => s_colisao_fruta,
            pontuacao => s_score
        );

    MSC: max_score
        port map (
            clock         => clock,
            reset         => reset,
            score_atual   => s_score,
            max_score_out => s_max_score
        );

end architecture estrutural;
