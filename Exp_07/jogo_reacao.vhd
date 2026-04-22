library ieee;
use ieee.std_logic_1164.all;

entity jogo_reacao is
    port (
        clock      : in  std_logic;
        reset      : in  std_logic;
        jogar      : in  std_logic;
        resposta_1 : in  std_logic; 
        resposta_2 : in  std_logic; 
        display0   : out std_logic_vector(6 downto 0);
        display1   : out std_logic_vector(6 downto 0);
        display2   : out std_logic_vector(6 downto 0);
        display3   : out std_logic_vector(6 downto 0);
		  display5   : out std_logic_vector(6 downto 0);
        ligado     : out std_logic;
        pulso      : out std_logic;
        estimulo   : out std_logic;
        erro       : out std_logic;
        pronto     : out std_logic;
		db_estado  : out std_logic_vector(3 downto 0)
    );
end entity jogo_reacao;

architecture estrutural of jogo_reacao is

    component interface_leds_botoes is
        port (
            clock      : in  std_logic;
            reset      : in  std_logic;
            iniciar    : in  std_logic;
            resposta   : in  std_logic;
            ligado     : out std_logic;
            estimulo   : out std_logic;
            pulso      : out std_logic;
            erro       : out std_logic;
            pronto     : out std_logic;
            db_estado  : out std_logic_vector(3 downto 0);
            db_rco     : out std_logic
        );
    end component;

    component medidor_largura is
        port (
            clock        : in  std_logic;
            reset        : in  std_logic;
            liga         : in  std_logic;
            sinal        : in  std_logic;
            tempo        : out std_logic_vector(15 downto 0);
            display0     : out std_logic_vector(6 downto 0);
            display1     : out std_logic_vector(6 downto 0);
            display2     : out std_logic_vector(6 downto 0);
            display3     : out std_logic_vector(6 downto 0);
            db_estado    : out std_logic_vector(6 downto 0);
            pronto       : out std_logic;
            fim          : out std_logic;
            db_clock     : out std_logic;
            db_sinal     : out std_logic;
            db_zeraCont  : out std_logic;
            db_contaCont : out std_logic
        );
    end component;

    -- Sinais internos
    signal s_ligado   : std_logic;
    signal s_estimulo : std_logic;
    signal s_pulso_int: std_logic;
    signal s_erro     : std_logic;
    signal s_pronto   : std_logic;
    signal s_db_estado: std_logic_vector(3 downto 0);

    signal s_disp1_0, s_disp1_1, s_disp1_2, s_disp1_3 : std_logic_vector(6 downto 0);
	 signal s_disp2_0, s_disp2_1, s_disp2_2, s_disp2_3 : std_logic_vector(6 downto 0);
    signal s_tempo_1                          : std_logic_vector(15 downto 0);
    signal s_tempo_2                          : std_logic_vector(15 downto 0);
    signal s_win                              : std_logic;
    
    signal s_resposta_interface : std_logic;
    signal s_resp_1_reg         : std_logic;
    signal s_resp_2_reg         : std_logic;
    signal s_pulso_1            : std_logic;
    signal s_pulso_2            : std_logic;

begin

    process(clock, reset)
    begin
        if reset = '1' then
            s_resp_1_reg <= '0';
            s_resp_2_reg <= '0';
        elsif rising_edge(clock) then
            if s_db_estado = "0001" or s_db_estado = "1111" then 
                s_resp_1_reg <= '0';
                s_resp_2_reg <= '0';
            else
                if resposta_1 = '1' then s_resp_1_reg <= '1'; end if;
                if resposta_2 = '1' then s_resp_2_reg <= '1'; end if;
            end if;
        end if;
    end process;

    s_resposta_interface <= (resposta_1 or resposta_2) when s_db_estado = "0010" else 
                            (s_resp_1_reg and s_resp_2_reg);

    s_pulso_1 <= s_estimulo and not s_resp_1_reg;
    s_pulso_2 <= s_estimulo and not s_resp_2_reg;

    INTERFACE : interface_leds_botoes
        port map (
            clock      => clock,
            reset      => reset,
            iniciar    => jogar,     
            resposta   => s_resposta_interface,
            ligado     => s_ligado,
            estimulo   => s_estimulo,
            pulso      => s_pulso_int,
            erro       => s_erro,
            pronto     => s_pronto,
            db_estado  => s_db_estado,  
            db_rco     => open
        );

    MEDIDOR_1 : medidor_largura
        port map (
            clock        => clock,
            reset        => reset,
            liga         => s_ligado, 
            sinal        => s_pulso_1,  
            tempo        => s_tempo_1,     
            display0     => s_disp1_0,
            display1     => s_disp1_1,
            display2     => s_disp1_2,
            display3     => s_disp1_3,
            db_estado    => open,
            pronto       => open,
            fim          => open,
            db_clock     => open,
            db_sinal     => open,
            db_zeraCont  => open,
            db_contaCont => open
        );

    MEDIDOR_2: medidor_largura
        port map (
            clock        => clock,
            reset        => reset,
            liga         => s_ligado, 
            sinal        => s_pulso_2,  
            tempo        => s_tempo_2,     
            display0     => s_disp2_0,
            display1     => s_disp2_1,
            display2     => s_disp2_2,
            display3     => s_disp2_3,
            db_estado    => open,
            pronto       => open,
            fim          => open,
            db_clock     => open,
            db_sinal     => open,
            db_zeraCont  => open,
            db_contaCont => open
        );

    s_win <= '0' when s_tempo_1 <= s_tempo_2 else '1';

    display0 <= "0010000" when s_erro = '1' else 
                s_disp1_0 when s_win = '0'  else s_disp2_0;

    display1 <= "0010000" when s_erro = '1' else 
                s_disp1_1 when s_win = '0'  else s_disp2_1;

    display2 <= "0010000" when s_erro = '1' else 
                s_disp1_2 when s_win = '0'  else s_disp2_2;

    display3 <= "0010000" when s_erro = '1' else 
                s_disp1_3 when s_win = '0'  else s_disp2_3;

    display5 <= "1111001" when (s_db_estado = "1000" and s_win = '0') else 
                "0100100" when (s_db_estado = "1000" and s_win = '1') else 
					 "1111111";
	 
	 ligado   <= s_ligado;
    pulso    <= s_pulso_1 or s_pulso_2;
    estimulo <= s_estimulo;
    erro     <= s_erro;
    pronto   <= s_pronto;
    db_estado <= s_db_estado;

end architecture estrutural;
