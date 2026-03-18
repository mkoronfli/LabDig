entity semaforo_uc is
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
end entity semaforo_uc;
