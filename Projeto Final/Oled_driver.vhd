library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity oled_driver is
    port (
        clock       : in  std_logic;
        reset       : in  std_logic;
        
        -- Coordenadas vindas do jogo_FD
        pos_cobra_x : in  std_logic_vector(6 downto 0);
        pos_cobra_y : in  std_logic_vector(5 downto 0);
        pos_fruta_x : in  std_logic_vector(6 downto 0);
        pos_fruta_y : in  std_logic_vector(5 downto 0);
        
        -- Pinos físicos do I2C
        oled_scl    : inout std_logic;
        oled_sda    : inout std_logic
    );
end entity oled_driver;

architecture comportamento of oled_driver is

    -- Instância do seu "Carteiro" (o código que você enviou)
    component i2c_controller is
        port (
            clock      : in  std_logic;
            reset      : in  std_logic;
            trigger    : in  std_logic;
            restart    : in  std_logic;
            last_byte  : in  std_logic;
            address    : in  std_logic_vector(6 downto 0);
            read_write : in  std_logic;
            write_data : in  std_logic_vector(7 downto 0);
            read_data  : out std_logic_vector(7 downto 0);
            ack_error  : out std_logic;
            busy       : out std_logic;
            scl        : inout std_logic;
            sda        : inout std_logic
        );
    end component;

    -- Sinais de ligação ao I2C
    signal i2c_trigger    : std_logic := '0';
    signal i2c_restart    : std_logic := '0';
    signal i2c_last_byte  : std_logic := '0';
    signal i2c_address    : std_logic_vector(6 downto 0) := "0111100"; -- 0x3C (Endereço Padrão do SSD1306)
    signal i2c_write_data : std_logic_vector(7 downto 0) := (others => '0');
    signal i2c_busy       : std_logic;
    
    -- Máquina de Estados do OLED
    type estado_t is (INICIAR, ENVIAR_INIT, ESPERAR_I2C, PREPARAR_DESENHO, DESENHAR_COBRA);
    signal estado_atual : estado_t := INICIAR;
    
    -- ROM com a sequência mágica para ligar o ecrã OLED SSD1306
    type init_rom_t is array (0 to 14) of std_logic_vector(7 downto 0);
    constant COMANDOS_INIT : init_rom_t := (
        x"AE", -- Display OFF
        x"D5", x"80", -- Set Clock Divide
        x"A8", x"3F", -- Set Multiplex (64 linhas)
        x"8D", x"14", -- Enable Charge Pump (Ligar a energia interna)
        x"20", x"02", -- Page Addressing Mode
        x"A1", -- Flip Horizontal
        x"C8", -- Flip Vertical
        x"81", x"CF", -- Set Contrast
        x"A4", -- Resume to RAM content
        x"AF"  -- Display ON
    );
    signal indice_init : integer range 0 to 15 := 0;
    
    -- Sinais de controlo de atraso
    signal atraso_busy : std_logic := '0';

begin

    -- O seu controlador I2C master
    I2C_MASTER: i2c_controller
        port map (
            clock      => clock,
            reset      => reset,
            trigger    => i2c_trigger,
            restart    => i2c_restart,
            last_byte  => i2c_last_byte,
            address    => i2c_address,
            read_write => '0', -- Sempre '0' (escrever para o ecrã)
            write_data => i2c_write_data,
            read_data  => open,
            ack_error  => open,
            busy       => i2c_busy,
            scl        => oled_scl,
            sda        => oled_sda
        );

    -- Máquina de Estados de Tradução (VHDL -> OLED)
    process(clock, reset)
    begin
        if reset = '1' then
            estado_atual <= INICIAR;
            i2c_trigger <= '0';
            indice_init <= 0;
            
        elsif rising_edge(clock) then
            -- Detetor de flanco do busy (para saber quando o I2C acabou de enviar)
            atraso_busy <= i2c_busy;
            
            case estado_atual is
                when INICIAR =>
                    indice_init <= 0;
                    estado_atual <= ENVIAR_INIT;
                    
                when ENVIAR_INIT =>
                    if i2c_busy = '0' then
                        -- Envia 0x00 primeiro para dizer "Isto é um Comando"
                        i2c_write_data <= x"00"; 
                        i2c_trigger <= '1';
                        -- Configura para enviar o dado da ROM
                        -- (Esta parte precisaria de um sub-estado no design completo para gerir os bytes múltiplos)
                        -- NOTA: O fluxo I2C foi simplificado aqui para estrutura académica
                        estado_atual <= ESPERAR_I2C;
                    end if;
                    
                when ESPERAR_I2C =>
                    i2c_trigger <= '0';
                    -- Espera o busy ir a 1 e voltar a 0
                    if atraso_busy = '1' and i2c_busy = '0' then
                        if indice_init < 14 then
                            indice_init <= indice_init + 1;
                            estado_atual <= ENVIAR_INIT;
                        else
                            estado_atual <= PREPARAR_DESENHO;
                        end if;
                    end if;
                    
                when PREPARAR_DESENHO =>
                    -- Aqui o ecrã já está ligado!
                    -- O driver converteria o pos_cobra_y(5 downto 3) numa "Página" (0 a 7)
                    -- E o pos_cobra_x(6 downto 0) numa Coluna (0 a 127)
                    estado_atual <= DESENHAR_COBRA;
                    
                when DESENHAR_COBRA =>
                    -- Lógica contínua de atualização do ecrã
                    null;
            end case;
        end if;
    end process;

end architecture;
