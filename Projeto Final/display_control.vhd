library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_control is
    port (
        clock     : in  std_logic;
        reset     : in  std_logic;
        cmd_telas : in  std_logic_vector(1 downto 0);
        pos_x     : in  std_logic_vector(6 downto 0);
        pos_y     : in  std_logic_vector(5 downto 0);
        fruta_x   : in  std_logic_vector(6 downto 0);
        fruta_y   : in  std_logic_vector(5 downto 0);
        score     : in  std_logic_vector(7 downto 0);
        oled_scl  : out std_logic;
        oled_sda  : out std_logic
    );
end entity display_control;

architecture behavioral of display_control is

    -- -------------------------------------------------------------------------
    -- Componente font_rom
    -- -------------------------------------------------------------------------
    component font_rom is
        port (
            numero   : in  integer range 0 to 9;
            coluna   : in  integer range 0 to 4;
            byte_out : out std_logic_vector(7 downto 0)
        );
    end component;

    -- -------------------------------------------------------------------------
    -- Estados da FSM principal
    -- -------------------------------------------------------------------------
    type tipo_estado is (
        ST_IDLE,
        ST_START,
        ST_SEND_BYTE,
        ST_ACK,
        ST_STOP,
        ST_WAIT,
        ST_DRAW_SCORE_SET_CURSOR,
        ST_DRAW_SCORE_DATA
    );
    signal estado_atual : tipo_estado := ST_IDLE;

    type tipo_sub_tarefa is (INIT, DRAW_SCORE);
    signal tarefa_atual : tipo_sub_tarefa := INIT;

    -- Sub-passos do posicionamento de cursor
    type tipo_cursor_step is (CURSOR_PAGE, CURSOR_COL_L, CURSOR_COL_H, CURSOR_DATA_CMD);
    signal cursor_step : tipo_cursor_step := CURSOR_PAGE;

    -- -------------------------------------------------------------------------
    -- Sinais de I2C bit-banging
    -- -------------------------------------------------------------------------
    signal sda_reg      : std_logic := '1';
    signal scl_reg      : std_logic := '1';
    signal data_to_send : std_logic_vector(7 downto 0);
    signal bit_idx      : integer range 0 to 7 := 7;
    signal cmd_idx      : integer := 0;

    -- -------------------------------------------------------------------------
    -- Sinais da font_rom
    -- -------------------------------------------------------------------------
    signal s_score_digito : integer range 0 to 9;
    signal s_font_coluna  : integer range 0 to 4 := 0;
    signal s_font_byte    : std_logic_vector(7 downto 0);

    -- -------------------------------------------------------------------------
    -- Sequência de inicialização completa — 23 comandos
    --
    --  Índice  Valor   Descrição
    --    0     0xAE    Display OFF (seguro durante power-up)
    --    1     0xD5    Set display clock divide ratio
    --    2     0x80    ratio recomendado pelo datasheet
    --    3     0xA8    Set multiplex ratio
    --    4     0x3F    64 linhas (painel 64 px)
    --    5     0xD3    Set display offset
    --    6     0x00    sem offset vertical
    --    7     0x40    Set display start line = 0
    --    8     0x8D    Charge pump setting        
    --    9     0x14    habilita charge pump     
    --   10     0x20    Set memory addressing mode
    --   11     0x00    modo horizontal          
    --   12     0xA1    Segment remap              
    --   13     0xC8    COM output scan remapped   
    --   14     0xDA    Set COM pins hardware config 
    --   15     0x12    alternativo, sem remap   
    --   16     0x81    Set contrast control       
    --   17     0xCF    contraste alto           
    --   18     0xD9    Set pre-charge period      
    --   19     0xF1    phase1=1, phase2=15      
    --   20     0xDB    Set VCOMH deselect level   
    --   21     0x40    ~0.89 × Vcc              
    --   22     0xAF    Display ON                 
    -- -------------------------------------------------------------------------
    constant NUM_INIT_CMDS : integer := 23;
    type comandos_array is array (0 to NUM_INIT_CMDS - 1) of std_logic_vector(7 downto 0);
    constant INIT_CMDS : comandos_array := (
        x"AE",  --  0
        x"D5",  --  1
        x"80",  --  2
        x"A8",  --  3
        x"3F",  --  4
        x"D3",  --  5
        x"00",  --  6
        x"40",  --  7
        x"8D",  --  8  
        x"14",  --  9
        x"20",  -- 10  
        x"00",  -- 11  
        x"A1",  -- 12  
        x"C8",  -- 13  
        x"DA",  -- 14  
        x"12",  -- 15  
        x"81",  -- 16 
        x"CF",  -- 17  
        x"D9",  -- 18 
        x"F1",  -- 19 
        x"DB",  -- 20  
        x"40",  -- 21  
        x"AF"   -- 22  
    );

    -- -------------------------------------------------------------------------
    -- Posição do score no display
    -- TEXT_PAGE: página SSD1306 (0xB0 = linha 0, 0xB1 = linha 8 px, etc.)
    -- TEXT_COL : coluna inicial em pixels (0–127)
    -- -------------------------------------------------------------------------
    constant TEXT_PAGE : std_logic_vector(7 downto 0) := x"B0";  -- página 0
    constant TEXT_COL  : integer := 96;                           -- coluna 96

begin

    oled_scl <= scl_reg;
    oled_sda <= sda_reg;

    s_score_digito <= to_integer(unsigned(score)) mod 10;

    ROM_FONTES: font_rom
        port map (
            numero   => s_score_digito,
            coluna   => s_font_coluna,
            byte_out => s_font_byte
        );

    -- -------------------------------------------------------------------------
    process(clock, reset)
        variable timer : integer := 0;
    begin
        if reset = '1' then
            estado_atual  <= ST_IDLE;
            tarefa_atual  <= INIT;
            cursor_step   <= CURSOR_PAGE;
            sda_reg       <= '1';
            scl_reg       <= '1';
            timer         := 0;
            cmd_idx       <= 0;
            s_font_coluna <= 0;

        elsif rising_edge(clock) then
            case estado_atual is

                -- -------------------------------------------------------------
                when ST_IDLE =>
                    if tarefa_atual = INIT then
                        data_to_send <= x"3C";
                        estado_atual <= ST_START;
                    elsif cmd_telas = "01" then
                        tarefa_atual  <= DRAW_SCORE;
                        cursor_step   <= CURSOR_PAGE;
                        data_to_send  <= x"3C";
                        estado_atual  <= ST_START;
                    end if;

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
                when ST_ACK =>
                    if timer < 250 then
                        sda_reg <= '1';   
                        scl_reg <= '1';
                        timer   := timer + 1;
                    elsif timer < 500 then
                        scl_reg <= '0';
                        timer   := timer + 1;
                    else
                        timer := 0;

                        if tarefa_atual = INIT then
                            if cmd_idx < NUM_INIT_CMDS then
                                data_to_send <= INIT_CMDS(cmd_idx);
                                cmd_idx      <= cmd_idx + 1;
                                estado_atual <= ST_SEND_BYTE;
                            else
                                cmd_idx      <= 0;
                                estado_atual <= ST_STOP;
                            end if;

                        elsif tarefa_atual = DRAW_SCORE then
                            estado_atual <= ST_DRAW_SCORE_SET_CURSOR;
                        end if;
                    end if;

                -- -------------------------------------------------------------
                when ST_DRAW_SCORE_SET_CURSOR =>
                    case cursor_step is

                        when CURSOR_PAGE =>
                            -- Comando de página: 0xB0 + número da página
                            data_to_send <= TEXT_PAGE;
                            cursor_step  <= CURSOR_COL_L;
                            estado_atual <= ST_SEND_BYTE;

                        when CURSOR_COL_L =>
                            -- Nibble baixo da coluna (bits 3:0 de TEXT_COL)
                            data_to_send <= std_logic_vector(
                                to_unsigned(TEXT_COL mod 16, 8));
                            cursor_step  <= CURSOR_COL_H;
                            estado_atual <= ST_SEND_BYTE;

                        when CURSOR_COL_H =>
                            -- Nibble alto da coluna: 0x10 OR (TEXT_COL / 16)
                            data_to_send <= std_logic_vector(
                                to_unsigned(16 + (TEXT_COL / 16), 8));
                            cursor_step  <= CURSOR_DATA_CMD;
                            estado_atual <= ST_SEND_BYTE;

                        when CURSOR_DATA_CMD =>
                            -- 0x40 = byte de controle "próximos bytes são dados"
                            data_to_send <= x"40";
                            cursor_step  <= CURSOR_PAGE;   -- reset para próximo frame
                            estado_atual <= ST_DRAW_SCORE_DATA;

                    end case;

                -- -------------------------------------------------------------
                when ST_DRAW_SCORE_DATA =>
                    if s_font_coluna < 5 then
                        data_to_send  <= s_font_byte;
                        s_font_coluna <= s_font_coluna + 1;
                        estado_atual  <= ST_SEND_BYTE;
                    else
                        s_font_coluna <= 0;
                        estado_atual  <= ST_STOP;
                    end if;

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
                when ST_WAIT =>
                    if timer < 5000 then
                        timer := timer + 1;
                    else
                        timer := 0;
                        if tarefa_atual = INIT then
                            tarefa_atual <= DRAW_SCORE;
                        end if;
                        estado_atual <= ST_IDLE;
                    end if;

                when others =>
                    estado_atual <= ST_IDLE;

            end case;
        end if;
    end process;

end architecture behavioral;