-------------------------------------------------------------------------------
-- Arquivo   : cont10_4digitos_tb.vhd
-------------------------------------------------------------------------------
-- Descricao : Testbench para o contador decimal com quatro testes        
-------------------------------------------------------------------------------
-- Testbench adaptado do material cont10_tb, diponibilizado no moodle
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

-- entidade do testbench
entity cont10_4digitos_tb is
end entity;

architecture tb of cont10_4digitos_tb is

  -- Componente a ser testado (Device Under Test -- DUT)
  component cont10 is
      port (
        clock   : in  std_logic;
        clear   : in  std_logic;
        enable  : in  std_logic;
        Q0      : out std_logic_vector(3 downto 0);
		    Q1      : out std_logic_vector(3 downto 0);
		    Q2      : out std_logic_vector(3 downto 0);
		    Q3      : out std_logic_vector(3 downto 0);
        RCO     : out std_logic
      );
  end component;
  
  ---- Declaracao de sinais de entrada para conectar o componente
  signal clock_in  : std_logic := '0';
  signal clear_in  : std_logic := '0';
  signal enable_in : std_logic := '0';

  ---- Declaracao dos sinais de saida
  signal q0_out      : std_logic_vector(3 downto 0) := (others => '0');
  signal q1_out      : std_logic_vector(3 downto 0) := (others => '0');
  signal q2_out      : std_logic_vector(3 downto 0) := (others => '0');
  signal q3_out      : std_logic_vector(3 downto 0) := (others => '0');
  signal rco_out     : std_logic := '0';

  -- Configurações do clock
  signal keep_simulating : std_logic := '0'; -- delimita o tempo de geração do clock
  constant clockPeriod   : time := 1 sec;      -- frequencia 1Hz
  
  -- Casos de teste
  signal caso            : integer := 0;

begin
  -- Gerador de clock: executa enquanto 'keep_simulating = 1', com o período especificado. 
  -- Quando keep_simulating=0, clock é interrompido, bem como a simulação de eventos
  clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;
  
  ---- DUT para Caso de Teste 1
  dut: cont10
      port map
      (
          clock    =>  clock_in, 
          clear    =>  clear_in,
          enable   =>  enable_in,
          Q0       =>  q0_out,
          Q1       =>  q1_out,
          Q2       =>  q2_out,
          Q3       =>  q3_out,
          RCO      =>  rco_out
      );
 
  ---- Gera sinais de estimulo para a simulacao
  stimulus: process is
  begin

    -- inicio da simulacao
    assert false report "inicio da simulacao" severity note;
    keep_simulating <= '1';  -- inicia geracao do sinal de clock

    -- Teste #1: gera pulso de clear assincrono (2 periodos de clock)
    -- (sinais de controle mudam nas bordas de descida do clock)
    -- resultado esperado: Q=0 e RCO=0
    caso     <= 1;
    --wait until falling_edge(clock_in);
    clear_in <= '1';
    wait for 2*clockPeriod;
    clear_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste 2: espera por 2 periodos de clock sem habilitacao de contagem
    -- resultado esperado: Q=0 e RCO=0
    caso     <= 2;
    wait for 2*clockPeriod;
    wait until falling_edge(clock_in);

    -- Teste #3: habilita contagem por 18 periodos de clock (teste de Q0 e Q1)
    -- resultados esperados: Q0=varia de 0 a 9, Q1=varia de 1 até 8, Q2 e Q3 peranecem em 0
    -- RCO permanece em 0
    caso      <= 3;
    enable_in <= '1';
    wait for 18*clockPeriod;
    enable_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste #4: habilita contagem por 999 periodos de clock (teste de Q0, Q1 e Q2)
    -- resultados esperados: Q0-Q2 variam de '0' a '999' (decimal), Q3 permanece em 0 
    -- RCO permanece em 0
    caso      <= 4;
    enable_in <= '1';
    wait for 999*clockPeriod;
    enable_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste #5: habilita contagem por 9999 periodos de clock (teste de Q0, Q1, Q2 e Q3)
    -- resultados esperados: Q0-Q3 variam de '0' a '9999' (decimal)
    -- RCO permanece em 0
    caso      <= 5;
    enable_in <= '1';
    wait for 9999*clockPeriod;
    enable_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste #6: habilita contagem por 10000 periodos de clock (teste de RC0)
    -- resultados esperados: Q0-Q3 variam de '0' a '9999' (decimal), depois zeram
    -- RCO muda para 1, na última etapa
    caso      <= 6;
    enable_in <= '1';
    wait for 10000*clockPeriod;
    enable_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste #7: clear assincrono  
    -- resultado esperado: Q=0 e RCO=0   
    caso     <= 7;
    clear_in <= '1';
    wait for clockPeriod;
    clear_in <= '0';
    wait until falling_edge(clock_in);

    -- tempo até final do testbench (5 periodos de clock)
    caso     <= 99;
    wait for 5*clockPeriod;  
 
    ---- final do testbench
    assert false report "fim da simulacao" severity note;
    keep_simulating <= '0';
    
    wait; -- fim da simulação: processo aguarda indefinidamente
  end process;

end architecture;
