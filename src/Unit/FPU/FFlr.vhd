library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FFlr is
    port (
        clk : in std_logic;
        f : in  std_logic_vector(31 downto 0);
        g : out std_logic_vector(31 downto 0) := (others => '0'));
end FFlr;

architecture dataflow of FFlr is
    signal len_raw : unsigned(8 downto 0);
    signal len : unsigned(4 downto 0);
    signal x_mask, incr : unsigned(30 downto 0);
    signal f_masked, f_incr : unsigned(30 downto 0);
    signal f_out : unsigned(30 downto 0);
    signal res : unsigned(31 downto 0);
    signal g_pipe : std_logic_vector(31 downto 0) := (others => '0');

begin
    len_raw <= unsigned('0' & f(30 downto 23)) - "001111111";
    len <= "00000" when len_raw(8) = '1' else
           "11111" when len_raw(7 downto 5) /= "000" else
           len_raw(4 downto 0);
    x_mask <= shift_right("000" & x"07FFFFF", to_integer(len));
    incr <= (x_mask(29 downto 0) & '1') xor x_mask;

    f_masked <= unsigned(f(30 downto 0)) and not x_mask;
    f_incr <= f_masked + incr;
    f_out <= f_masked when f(31) = '0' or unsigned(f(30 downto 0)) = f_masked else
             f_incr;

    res <= f(31) & "00000000" & f_out(22 downto 0) when (f(31) = '0' or f(30 downto 23) = "00000000") and len_raw(8) = '1' else
           f(31) & "01111111" & f_out(22 downto 0) when f(31) = '1' and len_raw(8) = '1' else
           f(31) & f_out;

    pipe : process(clk)
    begin
        if rising_edge(clk) then
            g_pipe <= std_logic_vector(res);
            g <= g_pipe;
        end if;
    end process;

end dataflow;
