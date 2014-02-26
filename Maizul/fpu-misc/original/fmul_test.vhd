-- written by panooz
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use STD.TEXTIO.all;

library UNISIM;
use UNISIM.VComponents.all;
use IEEE.STD_LOGIC_TEXTIO.all;

entity tb is  
end tb;

architecture testbench of tb is
  signal simclk : std_logic := '0';
  signal sig_a : std_logic_vector(31 downto 0);
  signal sig_b : std_logic_vector(31 downto 0);
  signal sig_c : std_logic_vector(31 downto 0) := (others => '0');
  signal fa_go_in : std_logic := '0';
  signal fa_go_out : std_logic;
  signal state : std_logic_vector(1 downto 0) := "00";
  signal answer : std_logic_vector(31 downto 0);
  signal res : std_logic := '1';
  file testdata : text open read_mode is "testdata.txt";
  
  component fmul
    port (
      clk : in  std_logic;
      go_in  : in  std_logic;
      a   : in  std_logic_vector(31 downto 0);
      b   : in  std_logic_vector(31 downto 0);
      c   : out std_logic_vector(31 downto 0);
      go_out : out std_logic);
  end component;

begin
  fm : fmul port map (
    clk => simclk,
    go_in  => fa_go_in,
    a   => sig_a,
    b   => sig_b,
    c   => sig_c,
    go_out => fa_go_out);

  main : process(simclk)
    variable l : line;
    variable at, bt, ct : std_logic_vector(31 downto 0);
  begin
    if rising_edge(simclk) then
      case state is
        when "00" =>
          if endfile(testdata) then
            state <= "11";
          else
            readline (testdata,l);
            read (l, at);
            read (l, bt);
            read (l, ct);
            sig_a <= at;
            sig_b <= bt;
            answer <= ct;
            state <= "01";
            fa_go_in <= '1';
          end if;
        when "01" =>
          fa_go_in <= '0';
          if fa_go_out = '1' then
            state <= "10";
          end if;
        when "10" =>
          if sig_c = answer or sig_c + 1 = answer or sig_c = answer +1 then
            res <= '1';
          else
            res <= '0';
          end if;
          state <= "00";
        when others => null;
      end case;
    end if;
  end process;
      
  clockgen: process
  begin
    simclk<='0';
    wait for 5 ns;
    simclk<='1';
    wait for 5 ns;
  end process;
end testbench;
