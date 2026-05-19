library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- Fluxo de operação:
--   reset → ST_IDLE → ST_INIT (envia 23 cmds de init)
--         → ST_IDLE → ST_FRAME_START (a cada frame)
--                   → para cada página (0..7):
--                       envia SET_PAGE (0xB0+p)
--                       envia SET_COL_LOW  (0x00 + col_low)
--                       envia SET_COL_HIGH (0x10 + col_high)
--                       envia 0x40 (byte de controle "dados")
--                       envia os 128 bytes lidos do frame_buffer
--                   → ST_WAIT → ST_IDLE (próximo frame)
-- =============================================================================

entity display_control is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;
        cmd_telas  : in  std_logic_vector(1 downto 0);

        -- Sinais do jogo (repassados ao frame_buffer)
        pos_x      : in  std_logic_vector(6 downto 0);
        pos_y      : in  std_logic_vector(5 downto 0);
        fruta_x    : in  std_logic_vector(6 downto 0);
        fruta_y    : in  std_logic_vector(5 downto 0);
        score      : in  std_logic_vector(7 downto 0);
        max_score  : in  std_logic_vector(7 downto 0);

        -- Saídas I²C
        oled_scl   : out std_logic;
        oled_sda   : out std_logic
    );
end entity display_control;

architecture behavioral of display_control is

    -- -------------------------------------------------------------------------
    -- Componente frame_buffer
    -- -------------------------------------------------------------------------
    component buffer_telas_jogo is
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
            fb_page    : in  integer range 0 to 7;
            fb_col     : in  integer range 0 to 127;
            fb_byte    : out std_logic_vector(7 downto 0)
        );
    end component;

    -- -------------------------------------------------------------------------
    -- Estados da FSM
    -- -------------------------------------------------------------------------
    type tipo_estado is (
        ST_IDLE,
        ST_START,           -- gera START condition I²C
        ST_SEND_BYTE,       -- serializa data_to_send
        ST_ACK,             -- aguarda ACK do slave
        ST_STOP,            -- gera STOP condition I²C
        ST_WAIT,            -- intervalo entre frames
        ST_INIT_SEND,       -- envia os 23 bytes de init
        ST_PAGE_CMD,        -- envia SET_PAGE  (0xB0+page)
        ST_COL_LOW,         -- envia SET_COL_L (0x00 + low nibble)
        ST_COL_HIGH,        -- envia SET_COL_H (0x10 + high nibble)
        ST_DATA_CTRL,       -- envia 0x40 (controle de dados)
        ST_FRAME_SEND       -- envia os 128 bytes do frame_buffer para a página atual
    );
    signal estado_atual : tipo_estado := ST_IDLE;

    type tipo_tarefa is (INIT, FRAME);
    signal tarefa_atual : tipo_tarefa := INIT;

    -- -------------------------------------------------------------------------
    -- Sinais I2C
    -- -------------------------------------------------------------------------
    signal sda_reg      : std_logic := '1';
    signal scl_reg      : std_logic := '1';
    signal data_to_send : std_logic_vector(7 downto 0);
    signal bit_idx      : integer range 0 to 7 := 7;

    -- Próximo estado a ser carregado após ST_SEND_BYTE + ST_ACK
    signal estado_apos_ack : tipo_estado := ST_IDLE;

    -- -------------------------------------------------------------------------
    -- Contadores de init e de frame
    -- -------------------------------------------------------------------------
    signal cmd_idx      : integer range 0 to 23 := 0;  -- índice no array de init
    signal cur_page     : integer range 0 to 7  := 0;  -- página atual do frame
    signal cur_col      : integer range 0 to 127 := 0; -- coluna atual do frame

    -- -------------------------------------------------------------------------
    -- Interface com frame_buffer
    -- -------------------------------------------------------------------------
    signal s_fb_page    : integer range 0 to 7;
    signal s_fb_col     : integer range 0 to 127;
    signal s_fb_byte    : std_logic_vector(7 downto 0);

    -- -------------------------------------------------------------------------
    -- Sequência de inicialização (23 comandos)
    -- -------------------------------------------------------------------------
    constant NUM_INIT_CMDS : integer := 23;
    type cmd_array is array (0 to NUM_INIT_CMDS - 1) of std_logic_vector(7 downto 0);
    constant INIT_CMDS : cmd_array := (
        x"AE", x"D5", x"80", x"A8", x"3F", x"D3", x"00", x"40",
        x"8D", x"14", x"20", x"00", x"A1", x"C8", x"DA", x"12",
        x"81", x"CF", x"D9", x"F1", x"DB", x"40", x"AF"
    );

begin

    oled_scl <= scl_reg;
    oled_sda <= sda_reg;

    -- Conecta os sinais de leitura ao frame_buffer
    s_fb_page <= cur_page;
    s_fb_col  <= cur_col;

    -- Instância do frame_buffer
    FB: frame_buffer
        port map (
            clock     => clock,
            reset     => reset,
            cmd_telas => cmd_telas,
            pos_x     => pos_x,
            pos_y     => pos_y,
            fruta_x   => fruta_x,
            fruta_y   => fruta_y,
            score     => score,
            max_score => max_score,
            fb_page   => s_fb_page,
            fb_col    => s_fb_col,
            fb_byte   => s_fb_byte
        );

    -- =========================================================================
    -- FSM principal
    -- =========================================================================
    process(clock, reset)
        variable timer : integer := 0;
    begin
        if reset = '1' then
            estado_atual  <= ST_IDLE;
            tarefa_atual  <= INIT;
            sda_reg       <= '1';
            scl_reg       <= '1';
            timer         := 0;
            cmd_idx       <= 0;
            cur_page      <= 0;
            cur_col       <= 0;

        elsif rising_edge(clock) then
            case estado_atual is

                -- -------------------------------------------------------------
                -- IDLE: decide o que fazer a seguir
                -- -------------------------------------------------------------
                when ST_IDLE =>
                    if tarefa_atual = INIT then
                        -- Primeiro START envia o endereço do display
                        data_to_send  <= x"3C";
                        estado_apos_ack <= ST_INIT_SEND;
                        estado_atual  <= ST_START;
                    else
                        -- Inicia envio de um frame completo
                        cur_page     <= 0;
                        cur_col      <= 0;
                        data_to_send <= x"3C";
                        estado_apos_ack <= ST_PAGE_CMD;
                        estado_atual <= ST_START;
                    end if;

                -- -------------------------------------------------------------
                -- START condition: SDA desce com SCL alto
                -- -------------------------------------------------------------
                when ST_START =>
                    if timer < 250 then
                        sda_reg <= '0';
                        timer   := timer + 1;
                    else
                        scl_reg      <= '0';
                        timer        := 0;
                        bit_idx      <= 7;
                        estado_atual <= ST_SEND_BYTE;
                    end if;

                -- -------------------------------------------------------------
                -- Serializa data_to_send bit a bit (MSB first)
                -- -------------------------------------------------------------
                when ST_SEND_BYTE =>
                    if timer < 125 then
                        sda_reg <= data_to_send(bit_idx);
                        timer   := timer + 1;
                    elsif timer < 375 then
                        scl_reg <= '1';
                        timer   := timer + 1;
                    elsif timer < 500 then
                        scl_reg <= '0';
                        timer   := timer + 1;
                    else
                        timer := 0;
                        if bit_idx > 0 then
                            bit_idx <= bit_idx - 1;
                        else
                            estado_atual <= ST_ACK;
                        end if;
                    end if;

                -- -------------------------------------------------------------
                -- ACK: libera SDA e gera pulso de clock para o slave responder
                -- -------------------------------------------------------------
                when ST_ACK =>
                    if timer < 250 then
                        sda_reg <= '1';
                        scl_reg <= '1';
                        timer   := timer + 1;
                    elsif timer < 500 then
                        scl_reg <= '0';
                        timer   := timer + 1;
                    else
                        timer        := 0;
                        bit_idx      <= 7;
                        estado_atual <= estado_apos_ack;
                    end if;

                -- -------------------------------------------------------------
                -- Envia os bytes de init um a um
                -- -------------------------------------------------------------
                when ST_INIT_SEND =>
                    if cmd_idx < NUM_INIT_CMDS then
                        data_to_send    <= INIT_CMDS(cmd_idx);
                        cmd_idx         <= cmd_idx + 1;
                        estado_apos_ack <= ST_INIT_SEND;
                        estado_atual    <= ST_SEND_BYTE;
                    else
                        -- Init concluído
                        cmd_idx      <= 0;
                        tarefa_atual <= FRAME;
                        estado_atual <= ST_STOP;
                    end if;

                -- -------------------------------------------------------------
                -- Envia comando de seleção de página: 0xB0 + cur_page
                -- -------------------------------------------------------------
                when ST_PAGE_CMD =>
                    data_to_send    <= std_logic_vector(
                                           to_unsigned(16#B0# + cur_page, 8));
                    estado_apos_ack <= ST_COL_LOW;
                    estado_atual    <= ST_SEND_BYTE;

                -- -------------------------------------------------------------
                -- Envia nibble baixo da coluna inicial (sempre 0x00)
                -- -------------------------------------------------------------
                when ST_COL_LOW =>
                    data_to_send    <= x"00";   -- coluna 0, nibble baixo = 0x00
                    estado_apos_ack <= ST_COL_HIGH;
                    estado_atual    <= ST_SEND_BYTE;

                -- -------------------------------------------------------------
                -- Envia nibble alto da coluna inicial: 0x10 (coluna 0, hi=0)
                -- -------------------------------------------------------------
                when ST_COL_HIGH =>
                    data_to_send    <= x"10";   -- coluna 0, nibble alto = 0x10
                    estado_apos_ack <= ST_DATA_CTRL;
                    estado_atual    <= ST_SEND_BYTE;

                -- -------------------------------------------------------------
                -- Envia byte de controle 0x40 indicando que os próximos bytes são dados de pixel (GDDRAM)
                -- -------------------------------------------------------------
                when ST_DATA_CTRL =>
                    data_to_send    <= x"40";
                    estado_apos_ack <= ST_FRAME_SEND;
                    cur_col         <= 0;
                    estado_atual    <= ST_SEND_BYTE;

                -- -------------------------------------------------------------
                -- Lê frame_buffer e envia os 128 bytes da página atual
                -- Depois da última coluna da última página → STOP e WAIT
                -- -------------------------------------------------------------
                when ST_FRAME_SEND =>
                    -- s_fb_byte já está disponível de forma combinacional
                    data_to_send <= s_fb_byte;

                    if cur_col < 127 then
                        cur_col         <= cur_col + 1;
                        estado_apos_ack <= ST_FRAME_SEND;
                        estado_atual    <= ST_SEND_BYTE;
                    else
                        -- Última coluna da página atual
                        cur_col <= 0;
                        if cur_page < 7 then
                            -- Avança para a próxima página
                            cur_page        <= cur_page + 1;
                            estado_apos_ack <= ST_PAGE_CMD;
                            estado_atual    <= ST_SEND_BYTE;
                        else
                            -- Frame completo — encerra a transação
                            cur_page     <= 0;
                            estado_atual <= ST_SEND_BYTE;
                            -- Após o último ACK vai para STOP
                            estado_apos_ack <= ST_STOP;
                        end if;
                    end if;

                -- -------------------------------------------------------------
                -- STOP condition
                -- -------------------------------------------------------------
                when ST_STOP =>
                    if timer < 250 then
                        sda_reg <= '0';
                        scl_reg <= '1';
                        timer   := timer + 1;
                    else
                        sda_reg      <= '1';
                        timer        := 0;
                        estado_atual <= ST_WAIT;
                    end if;

                -- -------------------------------------------------------------
                -- Intervalo entre frames (~5000 ciclos de clock)
                -- -------------------------------------------------------------
                when ST_WAIT =>
                    if timer < 5000 then
                        timer := timer + 1;
                    else
                        timer        := 0;
                        estado_atual <= ST_IDLE;
                    end if;

                when others =>
                    estado_atual <= ST_IDLE;

            end case;
        end if;
    end process;

end architecture behavioral;