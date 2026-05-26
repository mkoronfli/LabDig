library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_controller is
    Port ( 
        clk_25MHz : in  STD_LOGIC; -- Clock gerado pelo divisor de clock
        reset     : in  STD_LOGIC;
        hsync     : out STD_LOGIC;
        vsync     : out STD_LOGIC;
        video_on  : out STD_LOGIC;
        pixel_x   : out STD_LOGIC_VECTOR (9 downto 0);
        pixel_y   : out STD_LOGIC_VECTOR (9 downto 0)
    );
end vga_controller;

architecture Behavioral of vga_controller is

    -- Constantes para a resolução 640x480 @ 60Hz
    constant HD : integer := 640;  -- Área horizontal visível
    constant HF : integer := 16;   -- Horizontal Front Porch
    constant HB : integer := 48;   -- Horizontal Back Porch
    constant HR : integer := 96;   -- Horizontal Retrace/Sync pulse
    constant HMAX : integer := HD + HF + HB + HR; -- Total = 800

    constant VD : integer := 480;  -- Área vertical visível
    constant VF : integer := 10;   -- Vertical Front Porch
    constant VB : integer := 33;   -- Vertical Back Porch
    constant VR : integer := 2;    -- Vertical Retrace/Sync pulse
    constant VMAX : integer := VD + VF + VB + VR; -- Total = 525

    -- Contadores de posição
    signal h_cnt_reg, h_cnt_next : unsigned(9 downto 0) := (others => '0');
    signal v_cnt_reg, v_cnt_next : unsigned(9 downto 0) := (others => '0');

    -- Sinais de sincronismo internos
    signal h_sync_reg, v_sync_reg : std_logic := '0';

begin

    -- Registradores do Clock
    process(clk_25MHz, reset)
    begin
        if reset = '1' then
            h_cnt_reg  <= (others => '0');
            v_cnt_reg  <= (others => '0');
            h_sync_reg <= '0';
            v_sync_reg <= '0';
        elsif rising_edge(clk_25MHz) then
            h_cnt_reg  <= h_cnt_next;
            v_cnt_reg  <= v_cnt_next;
            h_sync_reg <= h_sync_reg; 
            v_sync_reg <= v_sync_reg;
        end if;
    end process;

    -- Lógica do Contador Horizontal
    process(h_cnt_reg)
    begin
        if h_cnt_reg = (HMAX - 1) then
            h_cnt_next <= (others => '0');
        else
            h_cnt_next <= h_cnt_reg + 1;
        end if;
    end process;

    -- Lógica do Contador Vertical
    process(v_cnt_reg, h_cnt_reg)
    begin
        if h_cnt_reg = (HMAX - 1) then
            if v_cnt_reg = (VMAX - 1) then
                v_cnt_next <= (others => '0');
            else
                v_cnt_next <= v_cnt_reg + 1;
            end if;
        else
            v_cnt_next <= v_cnt_reg;
        end if;
    end process;

    -- Geração dos Sinais de Sincronismo (Ativos em nível baixo)
    hsync <= '0' when (h_cnt_reg >= (HD + HF)) and (h_cnt_reg < (HD + HF + HR)) else '1';
    vsync <= '0' when (v_cnt_reg >= (VD + VF)) and (v_cnt_reg < (VD + VF + VR)) else '1';

    -- Sinal de Controle de Vídeo Ativo
    video_on <= '1' when (h_cnt_reg < HD) and (v_cnt_reg < VD) else '0';

    -- Saída das Coordenadas Atuais do Pixel
    pixel_x <= std_logic_vector(h_cnt_reg);
    pixel_y <= std_logic_vector(v_cnt_reg);

end Behavioral;