library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga is
    port(
        clk_25MHz : in  std_logic;
        reset     : in  std_logic;
        cmd_telas : in  std_logic_vector(1 downto 0);
        pos_x     : in  std_logic_vector(6 downto 0);
        pos_y     : in  std_logic_vector(5 downto 0);
        fruta_x   : in  std_logic_vector(6 downto 0);
        fruta_y   : in  std_logic_vector(5 downto 0);
        score     : in  integer range 0 to 99;
        max_score : in  integer range 0 to 99;
        hsync     : out std_logic;
        vsync     : out std_logic;
        red       : out std_logic_vector(3 downto 0);
        green     : out std_logic_vector(3 downto 0);
        blue      : out std_logic_vector(3 downto 0)
    );
end vga;

architecture Behavioral of vga is

    -- Offsets para centralizar 512x256 em 640x480
    constant OFFSET_X : integer := (640 - 512) / 2;  -- 64
    constant OFFSET_Y : integer := (480 - 256) / 2;  -- 112

    signal sig_pixel_x  : std_logic_vector(9 downto 0);
    signal sig_pixel_y  : std_logic_vector(9 downto 0);
    signal sig_video_on : std_logic;

    signal px           : integer range 0 to 1023;
    signal py           : integer range 0 to 1023;

    -- Coordenadas relativas à área do jogo
    signal rel_x        : integer range 0 to 1023;
    signal rel_y        : integer range 0 to 1023;

    -- Sinais para o buffer
    signal fb_col       : integer range 0 to 127;
    signal fb_page      : integer range 0 to 7;
    signal fb_bit       : integer range 0 to 7;
    signal fb_byte      : std_logic_vector(7 downto 0);

    -- Pixel ativo na área de jogo
    signal in_game_area : std_logic;
    signal pixel_on     : std_logic;

    signal s_clock_25MHz : std_logic;

    component buffer_telas_jogo is
        port(
            clock     : in  std_logic;
            reset     : in  std_logic;
            cmd_telas : in  std_logic_vector(1 downto 0);
            pos_x     : in  std_logic_vector(6 downto 0);
            pos_y     : in  std_logic_vector(5 downto 0);
            fruta_x   : in  std_logic_vector(6 downto 0);
            fruta_y   : in  std_logic_vector(5 downto 0);
            score     : in  integer range 0 to 99;
            max_score : in  integer range 0 to 99;
            fb_page   : in  integer range 0 to 7;
            fb_col    : in  integer range 0 to 127;
            fb_byte   : out std_logic_vector(7 downto 0)
        );
    end component;

    component vga_controller is
        port(
            clk_25MHz : in  std_logic;
            reset     : in  std_logic;
            hsync     : out std_logic;
            vsync     : out std_logic;
            video_on  : out std_logic;
            pixel_x   : out std_logic_vector(9 downto 0);
            pixel_y   : out std_logic_vector(9 downto 0)
        );
    end component;

    component clock_divider is
        generic (
            MODULO : integer := 2
        );
        port (
            clock      : in  std_logic;
            clear      : in  std_logic;
            enable     : in  std_logic;
            clock_slow : out std_logic
        );
    end component;

begin

    u_clk_div: clock_divider
        port map(
            clock      => clk_25MHz,  -- corrigido: fonte externa, não feedback
            clear      => reset,
            enable     => '1',
            clock_slow => s_clock_25MHz
        );

    u_vga_ctrl: vga_controller
        port map(
            clk_25MHz => s_clock_25MHz,
            reset     => reset,
            hsync     => hsync,
            vsync     => vsync,
            video_on  => sig_video_on,
            pixel_x   => sig_pixel_x,
            pixel_y   => sig_pixel_y
        );

    px <= to_integer(unsigned(sig_pixel_x));
    py <= to_integer(unsigned(sig_pixel_y));

    rel_x <= px - OFFSET_X when px >= OFFSET_X else 0;
    rel_y <= py - OFFSET_Y when py >= OFFSET_Y else 0;

    -- Cada pixel lógico ocupa 4x4 pixels VGA
    
    fb_col  <= rel_x / 4       when in_game_area = '1' else 0;
    fb_page <= rel_y / 32      when in_game_area = '1' else 0;
    fb_bit  <= (rel_y / 4) mod 8 when in_game_area = '1' else 0;

    u_buffer: buffer_telas_jogo
        port map(
            clock     => s_clock_25MHz,
            reset     => reset,
            cmd_telas => cmd_telas,
            pos_x     => pos_x,
            pos_y     => pos_y,
            fruta_x   => fruta_x,
            fruta_y   => fruta_y,
            score     => score,
            max_score => max_score,
            fb_page   => fb_page,
            fb_col    => fb_col,
            fb_byte   => fb_byte
        );

    -- Seleciona o bit do byte retornado que corresponde à linha atual
    pixel_on <= fb_byte(fb_bit);

    in_game_area <= '1' when (px >= OFFSET_X and px < OFFSET_X + 512
                           and py >= OFFSET_Y and py < OFFSET_Y + 256) else '0';

    -- Saída de cor: branco quando pixel ativo, preto caso contrário
    red   <= "1111" when sig_video_on and in_game_area and pixel_on else "0000";
    green <= "1111" when sig_video_on and in_game_area and pixel_on else "0000";
    blue  <= "1111" when sig_video_on and in_game_area and pixel_on else "0000";

end architecture Behavioral;