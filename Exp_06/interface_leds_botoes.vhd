library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
        db_estado  : out std_logic_vector(3 downto 0);
        db_rco     : out std_logic
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

    signal s_rco       : std_logic;
    signal s_zeraCont  : std_logic;
    signal s_contaCont : std_logic;
    signal s_estimulo  : std_logic;
    signal s_pulso     : std_logic;
    
    signal cont_5s : integer range 0 to 4999;

begin

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
            estado    => db_estado
        );

    process(clock, reset)
    begin
        if reset = '1' then
            cont_5s <= 0;
            s_rco <= '0';
        elsif rising_edge(clock) then
            if s_zeraCont = '1' then
                cont_5s <= 0;
                s_rco <= '0';
            elsif s_contaCont = '1' then
                if cont_5s = 4999 then
                    s_rco <= '1';
                else
                    cont_5s <= cont_5s + 1;
                    s_rco <= '0';
                end if;
            else
                s_rco <= '0';
            end if;
        end if;
    end process;

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
    db_rco   <= s_rco;

end architecture estrutural;
