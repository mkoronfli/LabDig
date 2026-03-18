library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity semaforo is
port (
clock : in std_logic;
reset : in std_logic;
vermelho : out std_logic;
amarelo : out std_logic;
verde : out std_logic
);
end entity semaforo;


architecture controlador_semaforo of semaforo is

-- Sinais internos
    signal clr_vermelho_sig, clr_amarelo_sig, clr_verde_sig, 
           en_vermelho_sig, en_amarelo_sig, en_verde_sig,
           rco_vermelho_sig, rco_amarelo_sig, rco_verde_sig:  std_logic;
    signal Q_vermelho, Q_amarelo, Q_verde: std_logic_vector(14 downto 0);              

-- Componentes
component contador is
    generic (
        MODULO : integer := 1000 -- modulo do contador
    );
    port (
        clock : in std_logic;
        clear : in std_logic;
        enable : in std_logic;
        Q : out std_logic_vector(14 downto 0); -- permite MODULO ate 32768
        RCO : out std_logic
    );
end component;

component semaforo_uc is
    port (
        clock : in std_logic;
        reset : in std_logic;
        rco_vermelho : in std_logic; -- Final do tempo do estado vermelho (5 sec)
        rco_amarelo : in std_logic; -- Final do tempo do estado amarelo (2 sec)
        rco_verde : in std_logic; -- Final do tempo do estado verde (4 sec)
        en_vermelho : out std_logic; -- Enable do Contador de tempo do estado vermelho
        en_amarelo : out std_logic; -- Enable do Contador de tempo do estado amarelo
        en_verde : out std_logic; -- Enable do Contador de tempo do estado verde
        clr_vermelho : out std_logic; -- Clear do contador de tempo do estado vermelho
        clr_amarelo : out std_logic; -- Clear do contador de tempo do estado amarelo
        clr_verde : out std_logic -- Clear do contador de tempo do estado verde
    );
end component semaforo_uc;

begin

VERM: contador 
    generic map (
        MODULO => 5000
    )
    port map(
	    clock => clock, -- Clock ligado ao clock global
	    clear => clr_vermelho_sig,
	    enable => en_vermelho_sig,	
	    Q => Q_vermelho,
	    RCO => rco_vermelho_sig
	);

AMAR: contador 
    generic map (
        MODULO => 2000
    )
    port map(
	    clock => clock, -- Clock ligado ao clock global
	    clear => clr_amarelo_sig,
	    enable => en_amarelo_sig,	
	    Q => Q_amarelo,
	    RCO => rco_amarelo_sig
	);

VERD: contador 
    generic map (
        MODULO => 4000
    )
    port map(
	    clock => clock, -- Clock ligado ao clock global
	    clear => clr_verde_sig,
	    enable => en_verde_sig,	
	    Q => Q_verde,
	    RCO => rco_verde_sig
	);

UC: semaforo_uc port map (
        clock => clock, -- Clock ligado ao clock global
        reset => reset,
        rco_vermelho => rco_vermelho_sig, 
        rco_amarelo => rco_amarelo_sig, 
        rco_verde => rco_verde_sig, 
        en_vermelho => en_vermelho_sig,
        en_amarelo => en_amarelo_sig, 
        en_verde => en_verde_sig, 
        clr_vermelho => clr_vermelho_sig, 
        clr_amarelo => clr_amarelo_sig, 
        clr_verde => clr_verde_sig 
    );

-- Controle de saidas
vermelho <= en_vermelho_sig;
amarelo <= en_amarelo_sig;
verde <= en_verde_sig;

end architecture;
