library ieee;
use ieee.std_logic_1164.all;
 
-- entidade do testbench
entity semaforo_uc_tb is
end entity;
 
architecture tb of semaforo_uc_tb is
 
  -- Componente a ser testado (Device Under Test -- DUT)
  component semaforo_uc is
    port (
        clock        : in  std_logic;
        reset        : in  std_logic;
        rco_vermelho : in  std_logic;
        rco_amarelo  : in  std_logic;
        rco_verde    : in  std_logic;
        en_vermelho  : out std_logic;
        en_amarelo   : out std_logic;
        en_verde     : out std_logic;
        clr_vermelho : out std_logic;
        clr_amarelo  : out std_logic;
        clr_verde    : out std_logic
    );
  end component;
 
  ---- Declaracao de sinais de entrada para conectar o componente
  signal clock_in        : std_logic := '0';
  signal reset_in        : std_logic := '0';
  signal rco_vermelho_in : std_logic := '0';
  signal rco_amarelo_in  : std_logic := '0';
  signal rco_verde_in    : std_logic := '0';
 
  ---- Declaracao dos sinais de saida
  signal en_vermelho_out  : std_logic;
  signal en_amarelo_out   : std_logic;
  signal en_verde_out     : std_logic;
  signal clr_vermelho_out : std_logic;
  signal clr_amarelo_out  : std_logic;
  signal clr_verde_out    : std_logic;
 
  -- Configuracoes do clock
  signal keep_simulating : std_logic := '0'; -- delimita o tempo de geracao do clock
  constant clockPeriod   : time := 1 ms;     -- frequencia 1kHz
 
  -- Casos de teste
  signal caso : integer := 0;
 
begin
  -- Gerador de clock: executa enquanto 'keep_simulating = 1', com o periodo especificado.
  clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;
 
  ---- DUT
  dut: semaforo_uc
    port map (
      clock        => clock_in,
      reset        => reset_in,
      rco_vermelho => rco_vermelho_in,
      rco_amarelo  => rco_amarelo_in,
      rco_verde    => rco_verde_in,
      en_vermelho  => en_vermelho_out,
      en_amarelo   => en_amarelo_out,
      en_verde     => en_verde_out,
      clr_vermelho => clr_vermelho_out,
      clr_amarelo  => clr_amarelo_out,
      clr_verde    => clr_verde_out
    );
 
  ---- Gera sinais de estimulo para a simulacao
  stimulus: process is
  begin
 
    -- inicio da simulacao
    assert false report "inicio da simulacao" severity note;
    keep_simulating <= '1';  -- inicia geracao do sinal de clock
 
    -- Teste #1: reset assÃ­ncrono
    -- Ativa reset por 20 periodos sem nenhum RCO ativo
    -- Resultado esperado: estado = vermelho, en_vermelho = 1, clr_vermelho =0
    --                              en amarelo = 0, en_verde = 0, clr_amarelo = 1, clr_verde = 1

    caso <= 1;
    reset_in <= '1';
    wait for 20*clockPeriod;
    reset_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste #2: vermelho permanece sem RCO (antes de terminar a contagem)
    -- Mantem rco_vermelho = 0  por 20 peridos de clock
    -- resultado esperado: maquina de estados permanece em vermelho, saidas nao mudam

    caso <= 2;
    wait for 20*clockPeriod;
    wait until falling_edge(clock_in);

    -- Teste #3: transiÃ§Ã£o vermelho para verde
    -- Ativa rco_vermelho por 1 perÃ­dos e volta a 0
    -- Resultado esperado: estado = verde, en_verde = 1, clr_verde = 0
    --                     en_vermelho = 0, en_amarelo = 0, clr_vermelho = 1, clr_amarelo = 1

    caso <= 3;
    rco_vermelho_in  <= '1';
    wait for clockPeriod;
    rco_vermelho_in  <= '0';
    wait until falling_edge(clock_in);

    -- Teste #4: transiÃ§Ã£o verde para amarelo
    -- Ativa rco_verde por 1 perÃ­odo e volta a 0
    -- Resultado esperado: estado=amarelo, en_amarelo=1, clr_amarelo=0
    --                     en_vermelho=0, en_verde=0, clr_vermelho=1, clr_verde=1

    caso <= 4;
    rco_verde_in <= '1';
    wait for clockPeriod;
    rco_verde_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste #5: transicao amarelo para vermelho
    -- Ativa rco_amarelo por 1 perÃ­odo e volta a 0
    -- Resultado esperado: estado=vermelho, en_vermelho=1, clr_vermelho=0
    --                     en_amarelo=0, en_verde=0, clr_amarelo=1, clr_verde=1

    caso <= 5;
    rco_amarelo_in <= '1';
    wait for clockPeriod;
    rco_amarelo_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste #6: reset assincrono (iniciando em outro estado)
    -- No estdo verde, reset e ativado
    -- Resultado esperado: maquina volta imediatamente para vermelho

    caso <= 6;
    rco_vermelho_in <= '1';
    wait for clockPeriod;
    rco_vermelho_in <= '0';
    wait for 50*clockPeriod;
    reset_in <= '1';
    wait for clockPeriod;
    reset_in <= '0';
    wait until falling_edge(clock_in);

    -- tempo ate final do testbench (5 periodos de clock)
    caso <= 99;
    wait for 5*clockPeriod;

    ---- final do testbench
    assert false report "fim da simulacao" severity note;
    keep_simulating <= '0';
 
    wait; -- fim da simulacao: processo aguarda indefinidamente
  end process;
 
end architecture;
 
