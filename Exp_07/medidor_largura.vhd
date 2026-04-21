library ieee;
use ieee.std_logic_1164.all;

entity medidor_largura is
    port (
        clock : in std_logic;
        reset : in std_logic;
        liga : in std_logic;
        sinal : in std_logic;
	    tempo : out std_logic_vector(15 downto 0);
        display0 : out std_logic_vector(6 downto 0);
        display1 : out std_logic_vector(6 downto 0);
        display2 : out std_logic_vector(6 downto 0);
        display3 : out std_logic_vector(6 downto 0);
        db_estado : out std_logic_vector(6 downto 0);
        pronto : out std_logic;
        fim : out std_logic;
        db_clock : out std_logic;
        db_sinal : out std_logic;
        db_zeraCont : out std_logic;
        db_contaCont : out std_logic
    );
end entity medidor_largura;

architecture medidor of medidor_largura is
-- Declaracao de sinais internos
    signal s_zera, s_conta, s_pronto: std_logic;
    signal s_db_estado: std_logic_vector(3 downto 0);
    signal s_contagem: std_logic_vector(15 downto 0);
    signal s_registrador: std_logic_vector(15 downto 0);

-- Componentes
    component controlador is
        port (
            clock : in std_logic;
            reset : in std_logic;
            liga : in std_logic;
            sinal : in std_logic;
            zeraCont : out std_logic;
            contaCont : out std_logic;
            pronto : out std_logic;
            db_estado : out std_logic_vector(3 downto 0) -- sinal de depuracao
        );
    end component;

    component cont10_4digitos_display7seg is
        port (
            clock    : in  std_logic;
            clear    : in  std_logic;
            enable   : in  std_logic;
            display0 : out std_logic_vector(6 downto 0);
            display1 : out std_logic_vector(6 downto 0);
            display2 : out std_logic_vector(6 downto 0);
            display3 : out std_logic_vector(6 downto 0);
	    Q        : out std_logic_vector(15 downto 0);
            RCO      : out std_logic
        );
    end component cont10_4digitos_display7seg;

    component hex7seg is
        port (
            hex      : in  std_logic_vector(3 downto 0);
            display  : out std_logic_vector(6 downto 0)
        );
    end component;

begin   

DISPLAY5: hex7seg
    port map (
        hex => s_db_estado, -- sinal de conexao display e controlador
        display => db_estado -- saida no display conectado ao sistema
    );

CNTROLADOR: controlador
    port map (
        clock => clock,
        reset => reset,
        liga => liga,
        sinal => sinal,
        zeraCont => s_zera, -- sinal de controle do estado PREPARA
        contaCont => s_conta, -- sinal de controle do esatdo CONTA
        pronto => s_pronto,       -- saida direta do sistema
        db_estado => s_db_estado -- sinal para conexao com o display5
    );

CONTADOR : cont10_4digitos_display7seg
    port map (
            clock    => clock,
            clear    => s_zera, -- sinal controlado pelo componente controlador (estado PREPARA)
            enable   => s_conta, -- sinal controlado pelo componente controlador (estado CONTA)
            display0 => display0, -- saida no display conectado ao sistema
            display1 => display1, -- saida no display conectado ao sistema
            display2 => display2, -- saida no display conectado ao sistema
            display3 => display3, -- saida no display conectado ao sistema
	         Q        => s_contagem,
            RCO      => fim         -- saida direta do sistema
        );

process(clock, reset)
    begin
        if reset = '1' then
            s_registrador <= (others => '0');
        elsif rising_edge(clock) then
            if s_pronto = '1' then 
                s_registrador <= s_contagem;
            end if;
        end if;
    end process;

    tempo  <= s_registrador;
    pronto <= s_pronto;
-- Controle de saidas de depuracao
    db_clock <= clock;  -- sinal de clock
    db_sinal <= sinal; -- pulso de entrada
    db_zeraCont <= s_zera; -- copia do sinal de controle seraCont
    db_contaCont <= s_conta; -- copia do sinal de controle contaCont

end architecture;
