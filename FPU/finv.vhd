library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity finv is
  port (
    clk : in std_logic;
    flt_in : in std_logic_vector(31 downto 0);
    flt_out : out std_logic_vector(31 downto 0));
end finv;

architecture blackbox of finv is
component finvTable is
  port (
    clk : in std_logic;
    addr : in std_logic_vector(9 downto 0);
    output : out std_logic_vector(35 downto 0));
end component;

signal sign: std_logic;
signal exp_out,exp_in : std_logic_vector(7 downto 0);
signal frac_out : std_logic_vector(22 downto 0);
signal key : std_logic_vector(9 downto 0);
signal rest : std_logic_vector(12 downto 0);
signal tvalue : std_logic_vector(35 downto 0);
signal const : std_logic_vector(22 downto 0);
signal grad : std_logic_vector(12 downto 0);
signal temp : std_logic_vector(25 downto 0);

begin
  table : finvTable port map(clk, key, tvalue);
  sign <= flt_in(31);
  exp_in <= flt_in(30 downto 23);
  key <= flt_in(22 downto 13);
  rest <= flt_in(12 downto 0);
  const <= tvalue(35 downto 13);
  grad <= tvalue(12 downto 0);
  temp <= grad * rest;
  frac_out <= (others=>'0') when key = 0 and rest = 0
              else const - ("000000000"&temp(25 downto 12));
  exp_out <= (others=>'1') when exp_in = 255 or exp_in = 0
             else (others=>'0') when exp_in = 254
             else 254 - exp_in when key = 0 and rest = 0
             else 253 - exp_in;
  flt_out <= sign & exp_out & frac_out;
end blackbox;
