library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity fsqrt is
  port (
    clk : in std_logic;
    flt_in : in std_logic_vector(31 downto 0);
    flt_out : out std_logic_vector(31 downto 0));
end fsqrt;

architecture blackbox of fsqrt is
component fsqrtTable is
  port (
    clk : in std_logic;
    addr : in std_logic_vector(9 downto 0);
    output : out std_logic_vector(35 downto 0));
end component;

signal sign: std_logic;
signal exp_out,exp_in : std_logic_vector(7 downto 0);
signal frac_out : std_logic_vector(22 downto 0);
signal key : std_logic_vector(9 downto 0);
signal rest : std_logic_vector(13 downto 0);
signal tvalue : std_logic_vector(35 downto 0);
signal const : std_logic_vector(22 downto 0);
signal grad : std_logic_vector(12 downto 0);
signal temp : std_logic_vector(26 downto 0);

begin
  table : fsqrtTable port map(clk, key, tvalue);
  sign <= flt_in(31);
  exp_in <= flt_in(30 downto 23);
  key <= flt_in(23 downto 14);
  rest <= flt_in(13 downto 0);
  const <= tvalue(35 downto 13);
  grad <= tvalue(12 downto 0);
  temp <= grad * rest;
  frac_out <= const + ("000000000"&temp(26 downto 13));
  exp_out <= (others => '1') when exp_in = 255 or exp_in = 0
             else ('0' & exp_in(7 downto 1)) + 64 when exp_in(0) = '1'
             else ('0' & exp_in(7 downto 1)) + 63;
  flt_out <= sign & exp_out & frac_out;
end blackbox;
