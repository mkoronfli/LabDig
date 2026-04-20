library ieee;
use ieee.std_logic_1164.all;

entity jogo_reacao is
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        jogar    : in  std_logic;
        resposta : in  std_logic;
        display0 : out std_logic_vector(6 downto 0);
        display1 : out std_logic_vector(6 downto 0);
        display2 : out std_logic_vector(6 downto 0);
        display3 : out std_logic_vector(6 downto 0);
        ligado   : out std_logic;
        pulso    : out std_logic;
        estimulo : out std_logic;
        erro     : out std_logic;
        pronto   : out std_logic;
		db_estado: out std_logic_vector(3 downto 0)
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
    signal s_pulso    : std_logic;
    signal s_erro     : std_logic;
    signal s_pronto   : std_logic;

    signal s_disp0, s_disp1, s_disp2, s_disp3 : std_logic_vector(6 downto 0);

begin

    INTERFACE : interface_leds_botoes
        port map (
            clock      => clock,
            reset      => reset,
            iniciar    => jogar,     
            resposta   => resposta,
            ligado     => s_ligado,
            estimulo   => s_estimulo,
            pulso      => s_pulso,
            erro       => s_erro,
            pronto     => s_pronto,
            db_estado  => db_estado,       
            db_rco     => open
        );

    MEDIDOR : medidor_largura
        port map (
            clock        => clock,
            reset        => reset,
            liga         => s_ligado, 
            sinal        => s_pulso,  
            tempo        => open,     
            display0     => s_disp0,
            display1     => s_disp1,
            display2     => s_disp2,
            display3     => s_disp3,
            db_estado    => open,
            pronto       => open,
            fim          => open,
            db_clock     => open,
            db_sinal     => open,
            db_zeraCont  => open,
            db_contaCont => open
        );

    display0 <= "0010000" when s_erro = '1' else s_disp0;
    display1 <= "0010000" when s_erro = '1' else s_disp1;
    display2 <= "0010000" when s_erro = '1' else s_disp2;
    display3 <= "0010000" when s_erro = '1' else s_disp3;

    ligado   <= s_ligado;
    pulso    <= s_pulso;
    estimulo <= s_estimulo;
    erro     <= s_erro;
    pronto   <= s_pronto;

end architecture estrutural;
