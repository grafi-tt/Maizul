library ieee;
use ieee.std_logic_1164.all;
use work.types.all;

entity Reg is
    port (
        clk : in std_logic;
        val : buffer value_t;
        enableW : in boolean;
        lineW : in value_t;
        enableM : in boolean;
        modeM : in boolean;
        lineM : inout value_t);
end Reg;

architecture Implementation of Reg is
begin
    everyClock : process(clk)
    begin
        if (rising_edge(clk)) then
            if enableW then
                val <= lineW;
            elsif enaleM then
                if modeM = '0'
                    val <= lineM;
                else
                    lineM <= val;
                end if;
            end if;
        end if;
    end process;

end Implementation;
