library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity RegSet is
    port (
        clk : in std_logic;
        blocking : in boolean;

        tagS : in std_logic_vector(4 downto 0);
        tagT : in std_logic_vector(4 downto 0);
        tagD : in std_logic_vector(4 downto 0);

        delayD : in schedule_t;
        writer : in std_logic;

        valS : out value_t;
        valT : out value_t;

        scheduleS : out schedule_t;
        scheduleT : out schedule_t;

        writeLineA : in value_t;
        writeLineB : in value_t);
end RegSet;

-- TODO : use generic for schedule length
architecture Multiplexer of RegSet is
    component Reg is
        port (
            clk : in std_logic;
            blocking : in boolean;

            delayEnable : in boolean;
            delay : in schedule_t;

            value : buffer value_t;
            schedule : buffer schedule_t;

            writeLineA : in value_t;
            writeLineB : in value_t);
    end component;

    type schedule_set_t is array(31 downto 0) of schedule_t;
    signal scheduleSet : schedule_set_t;

    type value_set_t is array(31 downto 0) of value_t;
    signal valueSet : value_set_t;

    type delay_enable_set_t is array(31 downto 1) of boolean;
    signal delayEnableSet : delay_enable_set_t;

begin
    reg_set_gen : for i in 31 downto 1 generate
        reg_port : Reg port map (
            clk => clk,
            blocking => blocking,
            delayEnable => delayEnableSet(i),
            delay => delayD,
            value => valueSet(i),
            schedule => scheduleSet(i),
            writeLineA => writeLineA,
            writeLineB => writeLineB);

        delayEnableSet(i) <= to_integer(unsigned(tagD)) = i;
    end generate reg_set_gen;

    valueSet(0) <= (others => '0');
    scheduleSet(0) <= (others => '0');

    valS <= valueSet(to_integer(unsigned(tagS)));
    valT <= valueSet(to_integer(unsigned(tagT)));

    scheduleS <= scheduleSet(to_integer(unsigned(tagS)));
    scheduleT <= scheduleSet(to_integer(unsigned(tagT)));

end Multiplexer;
