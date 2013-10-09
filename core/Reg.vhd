library ieee;
use ieee.std_logic_1164.all;

library cpuex;
use cpuex.types.all;

entity Reg is
    port (
        clk : in std_logic;

        delayEnable : in std_logic;
        delay : in schedule;

        value : buffer value;
        schedule : buffer schedule;

        writtenLine : in value;
        storeLine : out value);
end Reg;

architecture Implementation Reg is
    signal delayTmp : schedule;

begin
    everyClock : process(clk)
        schedule <= ("00" & schedule(13 downto 0)) or delayTmp;

        if (schedule(1 downto 0) == "01") then
            value <= writtenLine;
        end if;

        if (schedule(1 downto 0) == "10") then
            storeLine <= value;
        end if;
    end process;

    delayTmp <= delay when delayEnable = '1' else
                (others => '0');
end Implementation;
