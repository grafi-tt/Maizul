library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;
  
entity fmul is
  port (
    clk : in  std_logic;
    go_in  : in  std_logic;
    a   : in  std_logic_vector(31 downto 0);
    b   : in  std_logic_vector(31 downto 0);
    c   : out std_logic_vector(31 downto 0);
    go_out : out std_logic);
end fmul;

architecture blackbox of fmul is
  function "sra"(val : std_logic_vector; shift : integer) return std_logic_vector is
    variable ret : std_logic_vector(val'range) := val;
  begin
    if (shift /= 0) then
      for i in 1 to shift loop
        ret := '0' & ret(val'high downto val'low+1);
      end loop;
    end if;
    return ret;
  end;
  
  function "sla"(val : std_logic_vector; shift : integer) return std_logic_vector is
    variable ret : std_logic_vector(val'range) := val;
  begin
    if (shift /= 0) then
      for i in 1 to shift loop
        ret := ret(val'high-1 downto val'low) & '0';
      end loop;
    end if;
    return ret;
  end;

  signal state : std_logic_vector(3 downto 0) := "0000";
  signal temp : std_logic_vector(47 downto 0);
  signal c_sign : std_logic;
  signal c_exp : std_logic_vector(8 downto 0);
  signal c_frac : std_logic_vector(22 downto 0);
begin  -- blackbox
  setgo : process(clk)
    begin
      if rising_edge(clk) then
        if state = "0011" then
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
              temp <= (others => '0');
              c_sign <= a(31) xor b(31);
              c_exp <= ('0' & a(30 downto 23)) + ('0' & b(30 downto 23));
              state <= "0001";
            end if;
          when "0001" =>
            if conv_integer(c_exp) > 382 then
              c_exp <= (others => '1');
              temp <= (others => '0');
              state <= "0011";
            else
              if conv_integer(c_exp) < 127 then
                c_exp <= (others => '0');
              else
                c_exp <= c_exp - 127;
              end if;
              temp <= ('1' & a(22 downto 0)) * ('1' & b(22 downto 0));
              state <= "0010";      
            end if;
          when "0010" =>
            if temp(47) = '1' then
              c_exp <= c_exp+1;
              c_frac <= temp(46 downto 24);
            else
              c_frac <= temp(45 downto 23);
            end if;
            state <= "0011";
          when "0011" =>
            c <= c_sign & c_exp(7 downto 0) & c_frac;
            state <= "0000";
          when others => state <= "0000";
        end case;
      end if;
    end process;           
end blackbox;
