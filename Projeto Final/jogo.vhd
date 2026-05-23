library ieee;
use ieee.std_logic_1164.all;

entity jogo is
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        botoes   : in  std_logic_vector(4 downto 0);
        oled_scl : out std_logic;
        oled_sda : out std_logic
    );
end entity jogo;

architecture estrutural of jogo is
    
    component clock_divider is
        port (
            clock      : in  std_logic;
            clear      : in  std_logic;
            enable     : in  std_logic;
            clock_slow : out std_logic
        );
    end component;

    component input_filter is
        port (
            clock    : in  std_logic;
            btn_in   : in  std_logic;
            btn_out  : out std_logic
        );
    end component;

    component jogo_UC is
        port (
            clock     : in  std_logic;
            reset     : in  std_logic;
            iniciar   : in  std_logic;
            colisao   : in  std_logic;
            cmd_telas : out std_logic_vector(1 downto 0)
        );
    end component;

    component jogo_FD is
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
    end component;

    component display_control is
        port (
            clock      : in  std_logic;
            reset      : in  std_logic;
            cmd_telas  : in  std_logic_vector(1 downto 0);
            pos_x      : in  std_logic_vector(6 downto 0);
            pos_y      : in  std_logic_vector(5 downto 0);
            fruta_x    : in  std_logic_vector(6 downto 0);
            fruta_y    : in  std_logic_vector(5 downto 0);
            score      : in  std_logic_vector(7 downto 0);
            max_score  : in  std_logic_vector(7 downto 0);
            oled_scl   : out std_logic;
            oled_sda   : out std_logic
        );
    end component;

    signal clk_slow        : std_logic;
    signal s_botoes_filt   : std_logic_vector(4 downto 0);
    signal s_colidiu       : std_logic;
    signal s_cmd_telas     : std_logic_vector(1 downto 0);
    signal s_x_display     : std_logic_vector(6 downto 0);
    signal s_y_display     : std_logic_vector(5 downto 0);
    signal s_fx_display    : std_logic_vector(6 downto 0);
    signal s_fy_display    : std_logic_vector(5 downto 0);
    signal s_score_display : std_logic_vector(7 downto 0);
    signal s_max_score_display : std_logic_vector(7 downto 0);

begin

    CLK_DIV: clock_divider
        port map (
            clock      => clock,
            clear      => reset,
            enable     => '1',
            clock_slow => clk_slow
        );

    FILT_UP: input_filter port map(clock => clock, btn_in => botoes(0), btn_out => s_botoes_filt(0));
    FILT_DOWN: input_filter port map(clock => clock, btn_in => botoes(1), btn_out => s_botoes_filt(1));
    FILT_LEFT: input_filter port map(clock => clock, btn_in => botoes(2), btn_out => s_botoes_filt(2));
    FILT_RIGHT: input_filter port map(clock => clock, btn_in => botoes(3), btn_out => s_botoes_filt(3));
    FILT_INIT: input_filter port map(clock => clock, btn_in => botoes(4), btn_out => s_botoes_filt(4));

    -- Unidade de Controle
    UC: jogo_UC
        port map (
            clock     => clock,
            reset     => reset,
            colisao   => s_colidiu,
            iniciar   => s_botoes_filt(4),
            cmd_telas => s_cmd_telas
        );

    -- Fluxo de Dados
    FD: jogo_FD
        port map (
            clock         => clock,
            clock_slow    => clk_slow,
            reset         => reset,
            comandos_uc   => s_cmd_telas,
            btn_up        => s_botoes_filt(0),
            btn_down      => s_botoes_filt(1),
            btn_left      => s_botoes_filt(2),
            btn_right     => s_botoes_filt(3),
            perdeu_jogo   => s_colidiu,
            out_pos_x     => s_x_display,
            out_pos_y     => s_y_display,
            out_fruta_x   => s_fx_display,
            out_fruta_y   => s_fy_display,
            out_score     => s_score_display,
            out_max_score => s_max_score_display
        );

    -- Controlador do Display
    DISPLAY: display_control
        port map (
            clock     => clock,
            reset     => reset,
            cmd_telas => s_cmd_telas,
            pos_x     => s_x_display,
            pos_y     => s_y_display,
            fruta_x   => s_fx_display,
            fruta_y   => s_fy_display,
            score     => s_score_display,
            max_score => s_max_score_display,
            oled_scl  => oled_scl,
            oled_sda  => oled_sda
        );

end architecture estrutural;
