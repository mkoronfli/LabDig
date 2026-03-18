library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

-- entidade do testbench
entity contador_tb is
end entity;

architecture tb of contador_tb is

  -- Componente a ser testado (Device Under Test -- DUT)
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
  
  ---- Declaracao de sinais de entrada para conectar o componente
  signal clock_in  : std_logic := '0';
  signal clear_in  : std_logic := '0';
  signal enable_in : std_logic := '0';

  ---- Declaracao dos sinais de saida
  signal q_out      : std_logic_vector(14 downto 0) := (others => '0');
  signal rco_out    : std_logic := '0';

  -- Configurações do clock
  signal keep_simulating : std_logic := '0'; -- delimita o tempo de geração do clock
  constant clockPeriod   : time := 1 ms;      -- frequencia 1kHz
  
  -- Casos de teste
  signal caso            : integer := 0;

begin
  -- Gerador de clock: executa enquanto 'keep_simulating = 1', com o período especificado. 
  -- Quando keep_simulating=0, clock é interrompido, bem como a simulação de eventos
  clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;
  
  ---- DUT para Caso de Teste 1
  dut: contador
      port map
      (
          clock   =>  clock_in, 
          clear   =>  clear_in,
          enable  =>  enable_in,
          Q       =>  q_out,
          RCO     =>  rco_out
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

    -- Teste #3: habilita contagem por 1005 periodos de clock
    -- resultados esperados: Q=varia de 0 a 999, depois volta a contar com início em 0
    -- RCO permanece em 0, exceto quando Q=999
    caso      <= 3;
    enable_in <= '1';
    wait for 1005*clockPeriod;
    enable_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste 4: clear assincrono  
    -- resultado esperado: Q=0 e RCO=0   
    caso     <= 4;
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
