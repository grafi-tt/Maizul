library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FFlr is
    port (
        clk : in std_logic;
        f : in  std_logic_vector(31 downto 0);
        g : out std_logic_vector(31 downto 0));
end FFlr;

architecture Implementation of FFlr is
    signal len : std_logic_vector(8 downto 0);
    signal x_mask, incr : unsigned(31 downto 0);
    signal f_masked, f_incr : unsigned(31 downto 0);
    signal f_out : std_logic_vector(31 downto 0);

begin
    len <= unsigned('0' & f(30 downto 23)) - "001111111";
    x_mask <= shift_right(unsigned(x"007FFFFF"), to_integer(len(4 downto 0)));
    incr <= (x_mask sll 1) xor x_mask;

    f_masked <= f and not mask;
    f_incr <= f_masked + incr;
    f_out <= std_logic_vector(f_masked) when f(31) = '0' or f =  f_masked else
             std_logic_vector(f_incr);

    g <= f_out(31) & "00000000" & f_out(22 downto 0) when f(31) = '0' and len(9) = '1' else
         f_out(31) & "7FFFFFFF" & f_out(22 downto 0) when f(31) = '1' and len(9) = '1' else
         f_incr when f(31) = '1' and f_masked /= f else f_masked;

end Implementation;
