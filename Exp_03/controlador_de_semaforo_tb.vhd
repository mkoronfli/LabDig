library ieee;
use ieee.std_logic_1164.all;
 
-- entidade do testbench
entity semaforo_tb is
end entity;
 
architecture tb of semaforo_tb is

-- Componente a ser testado (Device Under Test -- DUT)
  component semaforo is
    generic (
        MODULO_VERMELHO : integer := 1000;
        MODULO_VERDE    : integer := 1000;
        MODULO_AMARELO  : integer := 1000
    );
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        vermelho : out std_logic;
        amarelo  : out std_logic;
        verde    : out std_logic
    );
  end component;

---- Declaracao de sinais de entrada para conectar o componente
  signal clock_in : std_logic := '0';
  signal reset_in : std_logic := '0';

---- Declaracao dos sinais de saida
  signal vermelho_out : std_logic;
  signal amarelo_out  : std_logic;
  signal verde_out    : std_logic;
 
  -- Configuracoes do clock
  signal keep_simulating : std_logic := '0'; -- delimita o tempo de geracao do clock
  constant clockPeriod   : time := 1 ms;     -- frequencia 1kHz
 
  -- Casos de teste
  signal caso : integer := 0;

begin
  -- Gerador de clock: executa enquanto 'keep_simulating = 1', com o periodo especificado.
  clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;
 
  ---- DUT
  dut: semaforo
    port map (
      clock    => clock_in,
      reset    => reset_in,
      vermelho => vermelho_out,
      amarelo  => amarelo_out,
      verde    => verde_out
    );

---- Gera sinais de estimulo para a simulacao
  stimulus: process is
  begin
 
    -- inicio da simulacao
    assert false report "inicio da simulacao" severity note;
    keep_simulating <= '1';  -- inicia geracao do sinal de clock

    -- Teste #1: reset assincrono inicial
    -- Ativa reset por 20 periodos
    -- Resultado esperado: vermelho = 1, amarelo = 0, verde = 0

    caso     <= 1;
    reset_in <= '1';
    wait for 20*clockPeriod;
    reset_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste #2: periodo completo de vermelho
    -- Aguarda 5000 periodos de clock (5 segundos a 1kHz)
    -- Resultado esperado: vermelho = 1, apenas no final muda para o verde

    caso <= 2;
    wait for 5000*clockPeriod;
    wait until falling_edge(clock_in);

    -- Teste #3: periodo completo de verde
    -- Aguarda 4000 periodos de clock (4 segundos a 1kHz)
    -- Resultado esperado: verde = 1, apenas no final muda para o amarelo

    caso <= 3;
    wait for 4000*clockPeriod;
    wait until falling_edge(clock_in);
 
    -- Teste #4: periodo completo de amarelo
    -- Aguarda 2000 periodos de clock (2 segundos a 1kHz)
    -- Resultado esperado: amarelo = 1 apenas, no final muda para o vermelho

    caso <= 4;
    wait for 2000*clockPeriod;
    wait until falling_edge(clock_in);

    -- Teste #5: inicio do segundo ciclo
    -- Confirma que o ciclo recomeca corretamente apos o ciclo completo
    -- Resultado esperado: vermelho = 1, apenas no final muda para o verde

    caso <= 5;
    wait for 5000*clockPeriod;
    wait until falling_edge(clock_in);

    -- Teste #6: reset assincrono no meio do estado verde
    -- Aguarda apenas 500 ciclos dentro do verde e entao ativa reset
    -- Resultado esperado: vermelho = 1, verde = 0, amarelo = 0 imediatamente (interrompe o ciclo)

    caso <= 6;
    wait for 500*clockPeriod;
    reset_in <= '1';
    wait for 2*clockPeriod;
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