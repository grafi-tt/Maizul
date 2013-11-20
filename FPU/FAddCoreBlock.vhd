library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FractionLeftTrimming is
    port (
        frc_in  : in  std_logic_vector(23 downto 0);
        nlz     : out std_logic_vector( 4 downto 0);
        frc_out : out std_logic_vector(22 downto 0));
end FractionLeftTrimming;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FractionRightShifter is
    port (
        frc_in  : in  std_logic_vector(23 downto 0);
        len     : in  std_logic_vector( 4 downto 0);
        frc_out : out std_logic_vector(23 downto 0);
        fst_over_out : out std_logic;
        snd_over_out : out std_logic;
        tail_any_out : out std_logic);
end FractionRightShifter;


architecture TrimmingL24 of FractionLeftTrimming is
    type ufrc_step_vector is array (3 downto 0) of unsigned(23 downto 0);

    signal u_frc     : ufrc_step_vector;
    signal u_frc_in  : unsigned(23 downto 0);
    signal u_frc_out : unsigned(23 downto 0);

begin
    u_frc_in <= unsigned(frc_in);

    nlz(4)    <= '1'             when u_frc_in(23 downto  8) = 0 else '0';
    u_frc(3)  <= u_frc_in sll 16 when u_frc_in(23 downto  8) = 0 else u_frc_in;
    nlz(3)    <= '1'             when u_frc(3)(23 downto 16) = 0 else '0';
    u_frc(2)  <= u_frc(3) sll 8  when u_frc(3)(23 downto 16) = 0 else u_frc(3);
    nlz(2)    <= '1'             when u_frc(2)(23 downto 20) = 0 else '0';
    u_frc(1)  <= u_frc(2) sll 4  when u_frc(2)(23 downto 20) = 0 else u_frc(2);
    nlz(1)    <= '1'             when u_frc(1)(23 downto 22) = 0 else '0';
    u_frc(0)  <= u_frc(1) sll 2  when u_frc(1)(23 downto 22) = 0 else u_frc(1);
    nlz(0)    <= '1'             when u_frc(0)(23 downto 23) = 0 else '0';
    u_frc_out <= u_frc(0) sll 1  when u_frc(0)(23 downto 23) = 0 else u_frc(0);

    frc_out <= std_logic_vector(u_frc_out(22 downto 0));

end TrimmingL24;

architecture BarrelShifterR24Mod of FractionRightShifter is
    type ufrc_step_vector is array (3 downto 0) of unsigned(25 downto 0);

    signal u_frc: ufrc_step_vector;
    signal u_frc_in: unsigned(25 downto 0);
    signal u_frc_out: unsigned(25 downto 0);

    signal tail_any: std_logic_vector (3 downto 0);

begin
    u_frc_in <= unsigned(frc_in) & "00";

    tail_any(3)  <= '1'             when len(4) = '1' and u_frc_in(15 downto 0) /= 0 else '0';
    u_frc(3)     <= u_frc_in srl 16 when len(4) = '1' else u_frc_in;
    tail_any(2)  <= '1'             when len(3) = '1' and u_frc(3)( 7 downto 0) /= 0 else tail_any(3);
    u_frc(2)     <= u_frc(3) srl 8  when len(3) = '1' else u_frc(3);
    tail_any(1)  <= '1'             when len(2) = '1' and u_frc(2)( 3 downto 0) /= 0 else tail_any(2);
    u_frc(1)     <= u_frc(2) srl 4  when len(2) = '1' else u_frc(2);
    tail_any(0)  <= '1'             when len(1) = '1' and u_frc(1)( 1 downto 0) /= 0 else tail_any(1);
    u_frc(0)     <= u_frc(1) srl 2  when len(1) = '1' else u_frc(1);
    tail_any_out <= '1'             when len(0) = '1' and u_frc(0)( 0 downto 0) /= 0 else tail_any(0);
    u_frc_out    <= u_frc(0) srl 1  when len(0) = '1' else u_frc(0);

    snd_over_out <= u_frc_out(0);
    fst_over_out <= u_frc_out(1);
    frc_out <= std_logic_vector(u_frc_out(25 downto 2));

end BarrelShifterR24Mod;
