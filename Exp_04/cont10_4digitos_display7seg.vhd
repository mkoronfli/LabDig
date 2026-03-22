-------------------------------------------------------------------------------
-- Componente: Conversor de hexadecimal para 7 segmentos        
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity hex7seg is
	port (  
			hex      : in  std_logic_vector(3 downto 0);
         display  : out std_logic_vector(6 downto 0)
	);
end hex7seg;

architecture arch of hex7seg is
begin
   --
   --       0  
   --      ---  
   --     |   |
   --    5|   |1
   --     | 6 |
   --      ---  
   --     |   |
   --    4|   |2
   --     |   |
   --      ---  
   --       3  
   --
  display <= "1000000" when hex = "0000" else -- 0
				 "1111001" when hex = "0001" else -- 1
				 "0100100" when hex = "0010" else -- 2
			 	 "0110000" when hex = "0011" else -- 3
				 "0011001" when hex = "0100" else -- 4
				 "0010010" when hex = "0101" else -- 5
				 "0000010" when hex = "0110" else -- 6
				 "1111000" when hex = "0111" else -- 7
				 "0000000" when hex = "1000" else -- 8
				 "0010000" when hex = "1001" else -- 9
				 "0001000" when hex = "1010" else -- A
				 "0000011" when hex = "1011" else -- B
				 "1000110" when hex = "1100" else -- C
				 "0100001" when hex = "1101" else -- D
				 "0000110" when hex = "1110" else -- E
				 "0001110" when hex = "1111" else -- F
				 "1111111";
end architecture;

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
entity cont10_4digitos_display7seg is
    port (
        clock    : in  std_logic;
        clear    : in  std_logic;
        enable   : in  std_logic;
        display0 : out std_logic_vector(6 downto 0);
        display1 : out std_logic_vector(6 downto 0);
        display2 : out std_logic_vector(6 downto 0);
        display3 : out std_logic_vector(6 downto 0);
        RCO      : out std_logic
    );
end entity cont10_4digitos_display7seg;

-- Declaracao da arquitetura do contador de 4 digitos
architecture arch of cont10_4digitos_display7seg is
	-- Sinais internos
	signal RCO_uni, RCO_dez, RCO_cen, RCO_mil, enable_dez, enable_cen, enable_mil : std_logic;
    signal s_Q0, s_Q1, s_Q2, s_Q3: std_logic_vector(3 downto 0);
	
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

    component hex7seg is
        port (
            hex      : in  std_logic_vector(3 downto 0);
            display  : out std_logic_vector(6 downto 0)
        );
    end component;

begin
	-- Logica de habilitacao dos contadores
	enable_dez <= enable and RCO_uni;
	enable_cen <= enable_dez and RCO_dez; -- Contador habilitado quando o contador anterior estiver
	enable_mil <= enable_cen and RCO_cen; -- ligado e todos os digitos anteriores estiverem em 9

	-- Contador referente ao digito da unidade
	UNI: cont10 port map(
	clock => clock, -- clock ligado ao clock global
	clear => clear,
	enable => enable,	
	Q => s_Q0, -- sinal ligado ao digito menos significativo do contador de 4 digitos
	RCO => RCO_uni
	);
	
	-- Contador do digito da dezena
	DEZ: cont10 port map(
	clock => clock,
	clear => clear,
	enable => enable_dez,	
	Q => s_Q1,
	RCO => RCO_dez
	);

	-- Contador da centena
	CEN: cont10 port map(
	clock => clock,
	clear => clear,
	enable => enable_cen,	
	Q => s_Q2,
	RCO => RCO_cen
	);

	-- Contador do milhar
	MIL: cont10 port map(
	clock => clock,
	clear => clear,
	enable => enable_mil,	
	Q => s_Q3,
	RCO => RCO_mil
	);

    -- Conexao com os displays
    h0: hex7seg port map (
        hex     => s_Q0,
        display => display0
    );

    h1: hex7seg port map (
        hex     => s_Q1,
        display => display1
    );

    h2: hex7seg port map (
        hex     => s_Q2,
        display => display2
    );

    h3: hex7seg port map (
        hex     => s_Q3,
        display => display3
    );

    -- controle da saída RCO
	RCO <= RCO_mil and RCO_cen and RCO_dez and RCO_uni; -- RCO do contador de 4 digitos ligado quando todos os digitos estao em 9 

end architecture;
