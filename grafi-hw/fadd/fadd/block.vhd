library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity FractionLeftPadding is
    port (
        frcIn  : in  std_logic_vector(23 downto 0);
        nlz    : out std_logic_vector( 4 downto 0);
        frcOut : out std_logic_vector(23 downto 0));
end FractionLeftPadding;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity FractionRightShifter is
    port (
        frcIn  : in  std_logic_vector(23 downto 0);
        len    : in  std_logic_vector( 4 downto 0);
        frcOut : out std_logic_vector(23 downto 0);
        fstOverOut : out std_logic;
        sndOverout : out std_logic;
        tailAnyout : out std_logic);
end FractionRightShifter;


architecture PaddingL24 of FractionLeftPadding is
    type ufrc_step_vector is array (3 downto 0) of unsigned(23 downto 0);

    signal uFrc    : ufrc_step_vector;
    signal uFrcIn  : unsigned(23 downto 0);
    signal uFrcOut : unsigned(23 downto 0);
begin
    uFrcIn <= unsigned(frcIn);

    nlz(4)  <= '1'           when uFrcIn (23 downto  8) = 0 else '0';
    uFrc(3) <= uFrcIn sll 16 when uFrcIn (23 downto  8) = 0 else uFrcIn;
    nlz(3)  <= '1'           when uFrc(3)(23 downto 12) = 0 else '0';
    uFrc(2) <= uFrc(3) sll 8 when uFrc(3)(23 downto 12) = 0 else uFrc(3);
    nlz(2)  <= '1'           when uFrc(2)(23 downto 20) = 0 else '0';
    uFrc(1) <= uFrc(2) sll 4 when uFrc(2)(23 downto 20) = 0 else uFrc(2);
    nlz(1)  <= '1'           when uFrc(1)(23 downto 22) = 0 else '0';
    uFrc(0) <= uFrc(1) sll 2 when uFrc(1)(23 downto 22) = 0 else uFrc(1);
    nlz(0)  <= '1'           when uFrc(0)(23 downto 23) = 0 else '0';
    uFrcOut <= uFrc(0) sll 1 when uFrc(0)(23 downto 23) = 0 else uFrc(0);

    frcOut <= std_logic_vector(uFrcOut);
end PaddingL24;

architecture BarrelShifterR24Mod of FractionRightShifter is
    type ufrc_step_vector is array (3 downto 0) of unsigned(25 downto 0);

    signal uFrc: ufrc_step_vector;
    signal uFrcIn: unsigned(25 downto 0);
    signal uFrcOut: unsigned(25 downto 0);

    signal tailAny: std_logic_vector (3 downto 0);
begin
    uFrcIn <= unsigned(frcIn) & "00";

    tailAny(3) <= '1'            when len(4) = '1' and uFrcIn(15 downto 0) /= 0 else '0';
    uFrc(3)    <= uFrcIn srl 16  when len(4) = '1' else uFrcIn;
    tailAny(2) <= '1'            when len(3) = '1' and uFrc(3)(7 downto 0)  /= 0 else tailAny(3);
    uFrc(2)    <= uFrc(3) srl 8  when len(3) = '1' else uFrc(3);
    tailAny(1) <= '1'            when len(2) = '1' and uFrc(2)(3 downto 0)  /= 0 else tailAny(2);
    uFrc(1)    <= uFrc(2) srl 4  when len(2) = '1' else uFrc(2);
    tailAny(0) <= '1'            when len(1) = '1' and uFrc(1)(1 downto 0)  /= 0 else tailAny(1);
    uFrc(0)    <= uFrc(1) srl 2  when len(1) = '1' else uFrc(1);
    tailAnyOut <= '1'            when len(0) = '1' and uFrc(0)(0 downto 0)  /= 0 else tailAny(0);
    uFrcOut    <= uFrc(0) srl 1  when len(0) = '1' else uFrc(0);

    sndOverOut <= uFrcOut(0);
    fstOverOut <= uFrcOut(1);
    frcOut <= std_logic_vector(uFrcOut(25 downto 2));
end BarrelShifterR24Mod;
