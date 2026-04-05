library ieee;
use ieee.std_logic_1164.all;

entity interface_leds_botoes is
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
        estado_out : out std_logic_vector(3 downto 0) 
    );
end entity interface_leds_botoes;

architecture estrutural of interface_leds_botoes is

    component interface_leds_botoes_uc is
        port (
            clock     : in  std_logic;
            reset     : in  std_logic;
            iniciar   : in  std_logic;
            resposta  : in  std_logic;
            rco       : in  std_logic;
            zeraCont  : out std_logic;
            contaCont : out std_logic;
            ligado    : out std_logic;
            estimulo  : out std_logic;
            erro      : out std_logic;
            pronto    : out std_logic;
            estado    : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Declaração do componente do fluxo de dados
    component cont10 is
        port (
            clock   : in  std_logic;
            clear   : in  std_logic;
            enable  : in  std_logic;
            Q       : out std_logic_vector(3 downto 0);
            RCO     : out std_logic
        );
    end component;

    -- Sinais internos para interligar os blocos
    signal s_rco       : std_logic;
    signal s_zeraCont  : std_logic;
    signal s_contaCont : std_logic;
    signal s_estimulo  : std_logic;
    signal s_pulso     : std_logic;

begin

    -- Instanciação da UC
    UC: interface_leds_botoes_uc
        port map (
            clock     => clock,
            reset     => reset,
            iniciar   => iniciar,
            resposta  => resposta,
            rco       => s_rco,
            zeraCont  => s_zeraCont,
            contaCont => s_contaCont,
            ligado    => ligado,
            estimulo  => s_estimulo,
            erro      => erro,
            pronto    => pronto,
            estado    => estado_out
        );

    -- Instanciação do FD
    FD: cont10
        port map (
            clock   => clock,
            clear   => s_zeraCont,
            enable  => s_contaCont,
            Q       => open,       
            RCO     => s_rco       
        );

    process(s_estimulo, resposta, reset)
    begin
        if reset = '1' or resposta = '1' then
            s_pulso <= '0';
        elsif s_estimulo = '1' then
            s_pulso <= '1';
        end if;
    end process;

    estimulo <= s_estimulo;
    pulso    <= s_pulso;

end architecture estrutural;
