library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity RegSet is
    port (
        clk : in std_logic;
        tagS : in tag_t;
        valS : out value_t;
        tagT : in tag_t;
        valT : out value_t;
        tagW : in tag_t;
        lineW : in value_t);
end RegSet;

architecture OnlyArray of RegSet is
    type value_set_t is array(31 downto 0) of value_t;
    signal valSet : value_set_t;

begin
    valS <= valSet(to_integer(unsigned(tagS)));
    valT <= valSet(to_integer(unsigned(tagT)));

    write : process(clk)
    begin
        if rising_edge(clk) then
            lineW <= valSet(to_integer(unsigned(tagW)));
        end if;
    end process;

end OnlyArray;
