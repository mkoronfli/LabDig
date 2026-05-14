library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity font_rom is
    port (
        numero   : in  integer range 0 to 9; 
        coluna   : in  integer range 0 to 4; 
        byte_out : out std_logic_vector(7 downto 0)
    );
end entity font_rom;

architecture lut of font_rom is
begin
    process(numero, coluna)
    begin
        case numero is
            when 0 =>
                case coluna is
                    when 0 => byte_out <= "00111110"; 
                    when 1 => byte_out <= "01010001"; 
                    when 2 => byte_out <= "01001001"; 
                    when 3 => byte_out <= "01000101"; 
                    when 4 => byte_out <= "00111110"; 
                end case;
            when 1 =>
                case coluna is
                    when 0 => byte_out <= "00000000";
                    when 1 => byte_out <= "01000010";
                    when 2 => byte_out <= "01111111";
                    when 3 => byte_out <= "01000000";
                    when 4 => byte_out <= "00000000";
                end case;
            when 2 =>
                case coluna is
                    when 0 => byte_out <= "01000010";
                    when 1 => byte_out <= "01100001";
                    when 2 => byte_out <= "01010001";
                    when 3 => byte_out <= "01001001";
                    when 4 => byte_out <= "01000110";
                end case;
            when 3 =>
                case coluna is
                    when 0 => byte_out <= "00100001";
                    when 1 => byte_out <= "01000001";
                    when 2 => byte_out <= "01000101";
                    when 3 => byte_out <= "01001011";
                    when 4 => byte_out <= "00110001";
                end case;
            when 4 =>
                case coluna is
                    when 0 => byte_out <= "00011000";
                    when 1 => byte_out <= "00010100";
                    when 2 => byte_out <= "00010010";
                    when 3 => byte_out <= "01111111";
                    when 4 => byte_out <= "00010000";
                end case;
            when others => 
                byte_out <= "01111111"; 
        end case;
    end process;
end architecture;
