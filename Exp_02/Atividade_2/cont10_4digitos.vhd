-------------------------------------------------------------------------------
-- Componente: Contador decimal com clear assincrono      
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cont10 is
    port (
        clock   : in  std_logic;
        clear   : in  std_logic;
        enable  : in  std_logic;
        Q       : out std_logic_vector(3 downto 0);
        RCO     : out std_logic
    );
end cont10;

architecture arch of cont10 is
    signal IQ: integer range 0 to 9;
begin

    process (clock, clear, enable)
    begin
        if clear = '1' then         -- clear assincrono
            IQ <= 0;
            
        elsif clock'event and clock='1' then
            if enable = '1' then
                if IQ = 9 then
                    IQ <= 0;
                else
                    IQ <= IQ + 1;
                end if;
            end if;
        end if;    
    end process;	
  
    RCO <= '1' when IQ = 9 else '0'; -- fim de contagem
    Q   <= std_logic_vector(to_unsigned(IQ, Q'length));  -- saida Q
end architecture;

-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declaracao do contador de 4 digitos
entity cont10_4digitos is
    port (
        clock   : in  std_logic;
        clear   : in  std_logic;
        enable  : in  std_logic;
        Q0      : out std_logic_vector(3 downto 0);
	Q1      : out std_logic_vector(3 downto 0);
	Q2      : out std_logic_vector(3 downto 0);
	Q3      : out std_logic_vector(3 downto 0);
        RCO     : out std_logic
    );
end entity cont10_4digitos;

-- Declaracao da arquitetura do contador de 4 digitos
architecture arch of cont10_4digitos is
	-- Sinais internos
	signal RCO_uni, RCO_dez, RCO_cen, RCO_mil, enable_dez, enable_cen, enable_mil : std_logic;
	
	-- Declaracao do componente contador simples
	component cont10 is
		port (
			clock   : in  std_logic;
			clear   : in  std_logic;
			enable  : in  std_logic;
			Q       : out std_logic_vector(3 downto 0);
			RCO     : out std_logic
		);
		end component;
begin
	-- Logica de habilitacao dos contadores
	enable_dez <= enable and RCO_uni;
	enable_cen <= enable_dez and RCO_dez; -- Contador habilitado quando o contador anterior estiver
	enable_mil <= enable_cen and RCO_cen; -- ligado e todos os digitos anteriores estiverem em 9
	
	-- Contador referente ao digito da unidade
	UNI: cont10 port map(
	clock => clock, -- Clock ligado ao clock global
	clear => clear,
	enable => enable,	
	Q => Q0, -- Saida ligada ao digito menos significativo do contador de 4 digitos
	RCO => RCO_uni
	);
	
	-- Contador do digito da dezena
	DEZ: cont10 port map(
	clock => clock,
	clear => clear,
	enable => enable_dez,	
	Q => Q1,
	RCO => RCO_dez
	);

	-- Contador da centena
	CEN: cont10 port map(
	clock => clock,
	clear => clear,
	enable => enable_cen,	
	Q => Q2,
	RCO => RCO_cen
	);

	-- Contador do milhar
	MIL: cont10 port map(
	clock => clock,
	clear => clear,
	enable => enable_mil,	
	Q => Q3,
	RCO => RCO_mil
	);

	RCO <= RCO_mil and RCO_cen and RCO_dez and RCO_uni; -- RCO do contador de 4 digitos ligado quando todos os digitos estao em 9 

end architecture;
