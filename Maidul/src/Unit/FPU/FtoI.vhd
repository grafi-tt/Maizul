library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FtoI is
    port (
        clk : in std_logic;
        f : in  std_logic_vector(31 downto 0);
        i : out std_logic_vector(31 downto 0));
end FtoI;

architecture Implementation of FtoI is
    signal x_len : std_logic_vector(8 downto 0);
    signal u_frc_4, u_frc_3, u_frc_2, u_frc_1, u_frc_0, u_frc_o, u_frc_v : unsigned(31 downto 0);
    signal any_4, any_3, any_2, any_1, any_0, any_o : std_logic;
    signal round : std_logic;

begin
    x_len <= std_logic_vector(unsigned('0' & f(30 downto 23)) - "001111110");

    any_4 <= '0';
    u_frc_4 <= unsigned('1' & f(22 downto 0) & "00000000");
    any_3 <= '1' when x_len(4) = '0' and u_frc_4(15 downto 0) /= 0 else any_4;
    u_frc_3 <= u_frc_4 srl 16 when x_len(4) = '0' else u_frc_4;
    any_2 <= '1' when x_len(3) = '0' and u_frc_3( 7 downto 0) /= 0 else any_3;
    u_frc_2 <= u_frc_3 srl  8 when x_len(3) = '0' else u_frc_3;
    any_1 <= '1' when x_len(2) = '0' and u_frc_2( 3 downto 0) /= 0 else any_2;
    u_frc_1 <= u_frc_2 srl  4 when x_len(2) = '0' else u_frc_2;
    any_0 <= '1' when x_len(1) = '0' and u_frc_1( 1 downto 0) /= 0 else any_1;
    u_frc_0 <= u_frc_1 srl  2 when x_len(1) = '0' else u_frc_1;
    any_o <= '1' when x_len(0) = '0' and u_frc_0( 0 downto 0) /= 0 else any_0;
    u_frc_o <= u_frc_0 srl  1 when x_len(0) = '0' else u_frc_0;

    u_frc_v <= u_frc_o srl 1;
    round <= (u_frc_o(0) and any_o) or (u_frc_o(1) and u_frc_o(0));

    i <= x"00000000" when x_len(8) = '1' else
         x"7FFFFFFF" when f(31) = '0' and x_len(7 downto 5) /= "000" else
         x"80000000" when f(31) = '1' and x_len(7 downto 5) /= "000" else
         std_logic_vector(u_frc_v) when f(31) = '0' and round = '0' else
         std_logic_vector(u_frc_v + 1) when f(31) = '0' and round = '1' else
         std_logic_vector(0 - u_frc_v) when round = '0' else
         std_logic_vector(not u_frc_v);

end Implementation;
