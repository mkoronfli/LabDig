-- adicione estes sinais
signal fb_byte_reg  : std_logic_vector(7 downto 0);
signal fb_bit_reg   : integer range 0 to 7;
signal pixel_on_reg : std_logic;

-- registre fb_byte e fb_bit no clock
process(s_clock_25MHz)
begin
    if rising_edge(s_clock_25MHz) then
        fb_byte_reg <= fb_byte;
        fb_bit_reg  <= fb_bit;
    end if;
end process;

-- use os valores registrados para pixel_on
pixel_on <= fb_byte_reg(fb_bit_reg);