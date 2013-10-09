library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library cpuex;
use cpuex.types.all;

entity RegSet is
    port (
        clk : in std_logic;

        tagS : in std_logic_vector(4 downto 0);
        tagT : in std_logic_vector(4 downto 0);
        tagD : in std_logic_vector(4 downto 0);

        delayD : in schedule;

        valS : out value;
        valT : out value;

        scheduleS : out schedule;
        scheduleT : out schedule;
        scheduleD : out schedule;

        writtenLine : in value;
        storeLine : out value);
end RegSet;

-- TODO : fix hardcording of numbers of register (using generic or constant)
architecture Multiplexer of RegSet is
    component Reg is
        port (
            clk : in std_logic;

            delayEnable : in std_logic;
            delay : in schedule;

            value : buffer value;
            schedule : buffer schedule;

            writtenLine : in value;
            storeLine : out value);
    end component;

    type scheduleSet is array(31 downto 0) of schedule;
    signal scheduleSet : scheduleSet;

    type valueSet is array(31 downto 0) of value;
    signal valueSet : valueSet;

    signal delayEnableSet : std_logic_vector(31 downto 0);

begin
    regSet: for i in 0 to 31 generate
        reg : Reg port map (
            clk => clk,
            delayEnable => delayEnableSet(i),
            value => valueSet(i),
            schedule => scheduleSet(i),
            writtenLine => writtenLine,
            storeLine => storeLine);

        delayEnableSet(i) <= '1' when to_integer(unsigned(tagD)) = i else '0';
    end generate regSet;

    valS <= valueSet(to_integer(unsigned(tagS)));
    valT <= valueSet(to_integer(unsigned(tagT)));

    scheduleS <= scheduleSet(to_integer(unsigned(tagS)));
    scheduleT <= scheduleSet(to_integer(unsigned(tagT)));
    scheduleD <= scheduleSet(to_integer(unsigned(tagD)));
end Implementation;
