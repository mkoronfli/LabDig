library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_display_control_v3 is
end entity tb_display_control_v3;

architecture sim of tb_display_control_v3 is

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
            max_score  : in  std_logic_vector(7 downto 0);  -- novo na Rev.3
            oled_scl   : out std_logic;
            oled_sda   : out std_logic
        );
    end component;

    signal clock     : std_logic := '0';
    signal reset     : std_logic := '0';
    signal cmd_telas : std_logic_vector(1 downto 0) := "00";
    signal pos_x     : std_logic_vector(6 downto 0) := (others => '0');
    signal pos_y     : std_logic_vector(5 downto 0) := (others => '0');
    signal fruta_x   : std_logic_vector(6 downto 0) := (others => '0');
    signal fruta_y   : std_logic_vector(5 downto 0) := (others => '0');
    signal score     : std_logic_vector(7 downto 0) := (others => '0');
    signal max_score : std_logic_vector(7 downto 0) := (others => '0');  -- novo

    signal oled_scl  : std_logic;
    signal oled_sda  : std_logic;

    signal keep_simulating : std_logic := '0';
    constant clockPeriod   : time := 20 ns;  -- 50 MHz

    -- byte_decodificado: acumula os bits recebidos pelo decodificador
    signal byte_decodificado : std_logic_vector(7 downto 0) := (others => '0');

    -- byte_pronto: pulsa '1' quando um byte completo foi capturado
    signal byte_pronto       : std_logic := '0';

    -- contador global de bytes recebidos
    signal byte_count        : integer := 0;

    type init_array_type is array (0 to 22) of std_logic_vector(7 downto 0);
    constant INIT_ESPERADO : init_array_type := (
        x"AE", x"D5", x"80", x"A8", x"3F", x"D3", x"00", x"40",
        x"8D", x"14", x"20", x"00", x"A1", x"C8", x"DA", x"12",
        x"81", x"CF", x"D9", x"F1", x"DB", x"40", x"AF"
    );

begin

    clock <= (not clock) and keep_simulating after clockPeriod / 2;

    DUT: display_control
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
            oled_scl  => oled_scl,
            oled_sda  => oled_sda
        );

    stim_process : process
    begin
        keep_simulating <= '1';

        -- ---------------------------------------------------------------------
        -- CASO 0: Reset e aguarda inicialização completa do OLED
        --
        -- O init envia 23 comandos via I²C. 
        -- Com clock 50 MHz e timer=500 ciclos por bit, cada byte leva 500*8 = 4000 ciclos = 80 µs.
        -- 23 bytes × 80 µs ≈ 1,84 ms. Aguardamos 5 ms para folga.
        -- ---------------------------------------------------------------------
        reset     <= '1';
        cmd_telas <= "00";
        max_score <= "00000111";  -- max_score = 7
        wait for clockPeriod * 5;
        reset <= '0';

        report "=== CASO 0: Reset liberado, aguardando init do OLED ===" severity note;
        wait for 5 ms;
        report "=== CASO 0: Init deve estar concluido ===" severity note;

        -- ---------------------------------------------------------------------
        -- CASO 1: Tela de jogo — cobra em (32,16), fruta em (50,24), score=5
        --
        -- Verifica que o frame buffer passa a enviar pixels de jogo:
        --   borda, score "05" no canto, pixel da cobra, pixel da fruta.
        -- ---------------------------------------------------------------------
        report "=== CASO 1: Mudando para tela de JOGO ===" severity note;
        pos_x     <= "0100000";   -- x = 32
        pos_y     <= "010000";    -- y = 16
        fruta_x   <= "0110010";   -- fx = 50
        fruta_y   <= "011000";    -- fy = 24
        score     <= "00000101";  -- score = 5
        max_score <= "00000111";  -- max_score = 7
        cmd_telas <= "01";
        wait for 5 ms;

        -- ---------------------------------------------------------------------
        -- CASO 2: Tela de game over — score=5, max_score=7
        -- ---------------------------------------------------------------------
        report "=== CASO 2: Mudando para GAME OVER ===" severity note;
        cmd_telas <= "10";
        wait for 5 ms;

        -- ---------------------------------------------------------------------
        -- CASO 3: Volta ao menu
        -- ---------------------------------------------------------------------
        report "=== CASO 3: Voltando ao MENU ===" severity note;
        cmd_telas <= "00";
        score     <= (others => '0');
        wait for 3 ms;

        -- Fim
        report "=== Simulacao encerrada ===" severity note;
        keep_simulating <= '0';
        wait;
    end process;

    -- =========================================================================
    -- Processo decodificador I²C
    --
    -- Monitora SCL e SDA e reconstrói cada byte transmitido.
    -- Funciona amostrando SDA na borda de subida do SCL (conforme I²C spec).
    --
    -- A cada 8 bits capturados:
    --   - armazena o byte em byte_decodificado
    --   - pulsa byte_pronto por um delta
    --   - incrementa byte_count
    --   - imprime o byte no console
    -- =========================================================================
    i2c_decoder : process
        variable bits_capturados : integer := 0;
        variable byte_em_construcao : std_logic_vector(7 downto 0) := (others => '0');
        variable iniciou : boolean := false;
    begin
        -- Espera a borda de subida do SCL
        wait until rising_edge(oled_scl);

        -- Detecta START condition: SDA desceu enquanto SCL estava alto
        -- (no bit-banging do DUT, SDA='0' com SCL='1' logo antes do primeiro bit)
        -- Aqui apenas amostramos SDA normalmente em cada subida de SCL.

        -- Captura o bit atual de SDA
        byte_em_construcao := byte_em_construcao(6 downto 0) & oled_sda;
        bits_capturados    := bits_capturados + 1;

        if bits_capturados = 8 then
            -- Byte completo capturado
            byte_decodificado <= byte_em_construcao;
            byte_pronto       <= '1';
            byte_count        <= byte_count + 1;

            -- Imprime no console (visível no ModelSim/GHDL/Vivado)
            --report "I2C byte #" & integer'image(byte_count) &
                   --" = 0x" & to_hstring(byte_em_construcao)
                   --severity note;

            -- Zera para o próximo byte
            bits_capturados    := 0;
            byte_em_construcao := (others => '0');

            wait for 1 ns;  -- pulso mínimo para byte_pronto
            byte_pronto <= '0';
        end if;

    end process i2c_decoder;

    -- =========================================================================
    -- Processo de assertions automáticas
    --
    -- Verifica se os 23 bytes de init foram enviados na ordem correta.
    -- O byte_count=0 é o endereço (0x3C), bytes 1..23 são os INIT_CMDS.
    -- =========================================================================
    assertions_init : process
    begin
        -- Aguarda o primeiro byte pronto (endereço 0x3C)
        wait until byte_pronto = '1';
        assert byte_decodificado = x"3C";
        report "OK: Endereco I2C 0x3C confirmado" severity note;

        wait until byte_pronto = '1';
        assert byte_decodificado = x"00";

        -- Verifica cada um dos 23 comandos de init em sequência
        for i in 0 to 22 loop
            wait until byte_pronto = '1';
            assert byte_decodificado = INIT_ESPERADO(i);
        end loop;

        report "=== Todos os 23 bytes de init verificados com sucesso ===" severity note;
        wait;
    end process assertions_init;

end architecture sim;