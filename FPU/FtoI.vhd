library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FtoI is
    port (
        clk : in std_logic;
        f : in  std_logic_vector(31 downto 0);
        i : out std_logic_vector(31 downto 0));
end IToF;

architecture Implementation of ItoF is
    signal x_len : std_logic_vector(4 downto 0);
    signal u_frc_4, u_frc_3, u_frc_2, u_frc_1, u_frc_0, u_frc_o : unsigned(31 downto 0);
    signal any_4, any_3, any_2, any_1, any_0 : std_logic;
begin
    x_len <= unsigned(f(30 downto 23)) - "01111110";

    u_frc_4 <= unsigned(f(22 downto 0);
    any_4 <= '1';
    u_frc_3 <= u_frc_4 srl 16 when x_len(4) = '0' else u_frc_4;
    any_3 <= any_4 when u_frc_4(15 downto 0) = 0 else '1';
    u_frc_2 <= u_frc_3 srl  8 when x_len(3) = '0' else u_frc_3;
    any_2 <= any_3 when u_frc_3( 7 downto 0) = 0 else '1';
    u_frc_1 <= u_frc_2 srl  4 when x_len(2) = '0' else u_frc_2;
    any_1 <= any_2 when u_frc_2( 3 downto 0) = 0 else '1';
    u_frc_0 <= u_frc_1 srl  2 when x_len(1) = '0' else u_frc_1;
    any_0 <= any_1 when u_frc_1( 1 downto 0) = 0 else '1';
    u_frc_o <= u_frc_0 srl  1 when x_len(0) = '0' else u_frc_0;
    any_o <= any_0 when u_frc_1( 0 downto 0) = 0 else '1';

    round <= any_o ;

    i <= std_logic_vector(u_frc_o) when f(31) = '0' and round = '0' else
         std_logic_vector(u_frc_o + 1) when f(31) = '0' and round = '1' else
         std_logic_vector(0 - u_frc_o) when round = '0' else
         std_logic_vector(not u_frc_o);

end Implementation;
