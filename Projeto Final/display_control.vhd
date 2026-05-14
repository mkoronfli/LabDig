library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_control is
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
        cmd_telas     : in  std_logic_vector(1 downto 0);
        pos_x         : in  std_logic_vector(6 downto 0);
        pos_y         : in  std_logic_vector(5 downto 0);
        fruta_x       : in  std_logic_vector(6 downto 0);
        fruta_y       : in  std_logic_vector(5 downto 0);
        score         : in  std_logic_vector(7 downto 0);
        oled_scl      : out std_logic;
        oled_sda      : out std_logic
    );
end entity display_control;

architecture behavioral of display_control is

    component font_rom is
        port (
            numero   : in  integer range 0 to 9;
            coluna   : in  integer range 0 to 4;
            byte_out : out std_logic_vector(7 downto 0)
        );
    end component;

    type tipo_estado is (ST_IDLE, ST_INIT, ST_START, ST_SEND_BYTE, ST_ACK, ST_STOP, ST_WAIT, 
                         ST_DRAW_SCORE_SET_CURSOR, ST_DRAW_SCORE_DATA);
    signal estado_atual : tipo_estado := ST_IDLE;
    
    type tipo_sub_tarefa is (INIT, DRAW_SCORE);
    signal tarefa_atual : tipo_sub_tarefa := INIT;

    -- Sinais I2C Bit-Banging 
    signal sda_reg : std_logic := '1';
    signal scl_reg : std_logic := '1';
    signal data_to_send : std_logic_vector(7 downto 0);
    signal bit_idx : integer range 0 to 7 := 7;
    signal cmd_idx : integer := 0;
    
    -- Sinais para a Lógica de Texto
    signal s_score_digito : integer range 0 to 9;
    signal s_font_coluna  : integer range 0 to 4 := 0;
    signal s_font_byte    : std_logic_vector(7 downto 0);
    
    -- Array de Inicialização
    type comandos_array is array (0 to 6) of std_logic_vector(7 downto 0);
    constant INIT_CMDS : comandos_array := (x"AE", x"D5", x"80", x"A8", x"3F", x"D3", x"00");

begin
    oled_scl <= scl_reg;
    oled_sda <= sda_reg;

    -- Pega apenas o dígito menos significativo do score (unidades) para simplificar
    s_score_digito <= to_integer(unsigned(score)) mod 10;

    -- Instancia a ROM
    ROM_FONTES: font_rom
        port map (
            numero   => s_score_digito,
            coluna   => s_font_coluna,
            byte_out => s_font_byte
        );

    process(clock, reset)
        variable timer : integer := 0;
    begin
        if reset = '1' then
            estado_atual <= ST_IDLE;
            tarefa_atual <= INIT;
            sda_reg <= '1';
            scl_reg <= '1';
            timer := 0;
            s_font_coluna <= 0;
        elsif rising_edge(clock) then
            case estado_atual is

                when ST_IDLE =>
                    if tarefa_atual = INIT then
                        data_to_send <= x"3C"; -- Endereço OLED
                        estado_atual <= ST_START;
                    elsif cmd_telas = "01" then -- JOGANDO: Hora de desenhar o placar
                        tarefa_atual <= DRAW_SCORE;
                        data_to_send <= x"3C";
                        estado_atual <= ST_START;
                    end if;

                when ST_START =>
                    -- Gera o START condition do I2C
                    if timer < 250 then
                        sda_reg <= '0';
                        timer := timer + 1;
                    else
                        scl_reg <= '0';
                        timer := 0;
                        bit_idx <= 7;
                        estado_atual <= ST_SEND_BYTE;
                    end if;

                when ST_SEND_BYTE =>
                    if timer < 125 then sda_reg <= data_to_send(bit_idx); timer := timer + 1;
                    elsif timer < 375 then scl_reg <= '1'; timer := timer + 1;
                    elsif timer < 500 then scl_reg <= '0'; timer := timer + 1;
                    else
                        timer := 0;
                        if bit_idx > 0 then bit_idx <= bit_idx - 1;
                        else estado_atual <= ST_ACK;
                        end if;
                    end if;

                when ST_ACK =>
                    if timer < 250 then sda_reg <= 'Z'; scl_reg <= '1'; timer := timer + 1;
                    elsif timer < 500 then scl_reg <= '0'; timer := timer + 1;
                    else
                        timer := 0;
                        -- Desvio de fluxo dependendo do que estamos fazendo
                        if tarefa_atual = INIT then
                            if cmd_idx < 7 then
                                cmd_idx <= cmd_idx + 1;
                                data_to_send <= INIT_CMDS(cmd_idx);
                                estado_atual <= ST_SEND_BYTE;
                            else
                                estado_atual <= ST_STOP;
                            end if;
                            
                        elsif tarefa_atual = DRAW_SCORE then
                            -- Pede os comandos para setar cursor ou enviar dado
                            estado_atual <= ST_DRAW_SCORE_SET_CURSOR;
                        end if;
                    end if;

                -- LÓGICA DE TEXTO: Posiciona o Cursor I2C e envia os bytes da fonte
                when ST_DRAW_SCORE_SET_CURSOR =>
                    -- Simulação de um envio de comando de coluna (simplificado)
                    -- O OLED precisa de comandos como 0x00 e 0x10 para coluna, e 0xB0 para página.
                    data_to_send <= x"40"; -- "40" indica ao SSD1306 que os próximos bytes são pixels de Dados
                    estado_atual <= ST_SEND_BYTE;
                    tarefa_atual <= DRAW_SCORE; -- Retorna para o loop da fonte após o ACK

                -- LÓGICA DE TEXTO: Varre as 5 colunas da ROM e envia
                when ST_DRAW_SCORE_DATA =>
                    if s_font_coluna < 5 then
                        data_to_send <= s_font_byte; -- Pega o byte atual da ROM
                        s_font_coluna <= s_font_coluna + 1;
                        estado_atual <= ST_SEND_BYTE;
                    else
                        -- Terminou de desenhar a letra inteira
                        s_font_coluna <= 0;
                        estado_atual <= ST_STOP;
                    end if;

                when ST_STOP =>
                    if timer < 250 then sda_reg <= '0'; scl_reg <= '1'; timer := timer + 1;
                    else sda_reg <= '1'; timer := 0; estado_atual <= ST_WAIT;
                    end if;

                when ST_WAIT =>
                    if timer < 5000 then timer := timer + 1;
                    else timer := 0; estado_atual <= ST_IDLE;
                    end if;

                when others =>
                    estado_atual <= ST_IDLE;
            end case;
        end if;
    end process;
end architecture;
