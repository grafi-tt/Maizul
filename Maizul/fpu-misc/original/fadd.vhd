-- written by panooz
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity fadd is
  port (
    clk : in  std_logic;
    go_in  : in  std_logic;
    a   : in  std_logic_vector(31 downto 0);
    b   : in  std_logic_vector(31 downto 0);
    c   : out std_logic_vector(31 downto 0);
    go_out : out std_logic);
end fadd;

architecture blackbox of fadd is
  signal state : std_logic_vector(3 downto 0) := "0000";
  signal a_sign : std_logic;
  signal a_exp : std_logic_vector(7 downto 0);
  signal a_frac : std_logic_vector(24 downto 0);
  signal b_sign : std_logic;
  signal b_exp : std_logic_vector(7 downto 0);
  signal b_frac : std_logic_vector(24 downto 0);
  signal c_sign : std_logic;
  signal c_exp : std_logic_vector(7 downto 0);
  signal c_frac : std_logic_vector(24 downto 0);
  signal zero : std_logic_vector(24 downto 0) := "0000000000000000000000000";
begin  -- blackbox
  setgo : process(clk)
    begin
      if rising_edge(clk) then
        if state = "0110" then
          go_out <= '1';
        else
          go_out <= '0';
        end if;
      end if;
    end process;
    
  main : process(clk)
    begin
      if rising_edge(clk) then
        case state is
          when "0000" =>
            if go_in = '1' then
              state <= "0001";
            end if;
          when "0001" =>
            if a(30 downto 23) > b(30 downto 23) then
              a_sign <= a(31);
              a_exp <= a(30 downto 23);
              a_frac <= "01" & a(22 downto 0);
              b_sign <= b(31);
              b_exp <= b(30 downto 23);
              b_frac <= "01" & b(22 downto 0);
            else
              a_sign <= b(31);
              a_exp <= b(30 downto 23);
              a_frac <= "01" & b(22 downto 0);
              b_sign <= a(31);
              b_exp <= a(30 downto 23);
              b_frac <= "01" & a(22 downto 0);
            end if;
            state <= "0010";
          when "0010" =>
            if conv_integer(a_exp - b_exp) < 24
            then
              b_frac <= zero(24 downto 24-conv_integer(a_exp - b_exp)) & b_frac(23 downto conv_integer(a_exp - b_exp));
            else
              b_frac <= zero;
            end if;
            state <= "0011";
          when "0011" =>
            if a_sign = b_sign then
              c_frac <= a_frac + b_frac;
            else
              c_frac <= a_frac - b_frac;
            end if;
            c_exp <= a_exp;
            c_sign <= a_sign;
            state <= "0100";
          when "0100" =>
            if c_frac(24) = '1' then
              c_exp <= c_exp + 1;
              c_frac <= '0' & c_frac(24 downto 1);
            end if;
            state <= "0101";
          when "0101" =>
            c <= c_sign & c_exp & c_frac(22 downto 0);
            state <= "0110";
          when others => state <= "0000";
        end case;
      end if;
    end process;
end blackbox;
