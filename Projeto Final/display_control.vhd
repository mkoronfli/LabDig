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

architecture estrutural of display_control is
    -- Estados da FSM do Display
    type tipo_estado is (ST_POWERUP, ST_INIT, ST_LIMPA, ST_DESENHA, ST_IDLE);
    signal estado_atual : tipo_estado := ST_POWERUP;

    signal s_i2c_ready : std_logic;
    signal s_i2c_exec  : std_logic;
    signal s_i2c_data  : std_logic_vector(7 downto 0);
    
begin
    process(clock, reset)
        variable counter : integer := 0;
    begin
        if reset = '1' then
            estado_atual <= ST_POWERUP;
            s_i2c_exec <= '0';
        elsif rising_edge(clock) then
            case estado_atual is
                when ST_POWERUP =>
                    -- Aguarda o display estabilizar a tensão (VCC 3.3V)
                    if counter < 50000 then 
                        counter := counter + 1;
                    else
                        estado_atual <= ST_INIT;
                        counter := 0;
                    end if;

                when ST_INIT =>
                    estado_atual <= ST_LIMPA;

                when ST_LIMPA =>
                    -- Comando para apagar todos os pixels antes de começar o frame
                    estado_atual <= ST_DESENHA;

                when ST_DESENHA =>
                    -- Lógica de renderização baseada no cmd_telas
                    if cmd_telas = "00" then
                        -- Desenha Texto: "PRESS START"
                        null; 
                    elsif cmd_telas = "01" then
                        -- Desenha a Cobra (pixel em pos_x, pos_y)
                        -- Desenha a Fruta (pixel em fruta_x, fruta_y)
                        null;
                    else
                        -- Desenha Texto: "GAME OVER" e Score 
                        null;
                    end if;
                    estado_atual <= ST_IDLE;

                when ST_IDLE =>
                    estado_atual <= ST_LIMPA;
                    
                when others =>
                    estado_atual <= ST_POWERUP;
            end case;
        end if;
    end process;

    oled_scl <= '1'; 
    oled_sda <= '1'; 

end architecture;
