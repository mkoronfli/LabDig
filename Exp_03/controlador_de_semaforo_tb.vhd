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

-- tempo ate final do testbench (5 periodos de clock)
    caso <= 99;
    wait for 5*clockPeriod;
 
    ---- final do testbench
    assert false report "fim da simulacao" severity note;
    keep_simulating <= '0';
 
    wait; -- fim da simulacao: processo aguarda indefinidamente
  end process;
 
end architecture;