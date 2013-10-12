library ieee;
use ieee.std_logic_1164.all;
use work.types.all;

entity Reg is
    port (
        clk : in std_logic;
        blocking : in boolean;

        delayEnable : in boolean;
        delay : in schedule_t;
        writer : in std_logic;

        value : buffer value_t;
        schedule : buffer schedule_t;

        writeLineA : in value_t;
        writeLineB : in value_t);
end Reg;

architecture Implementation of Reg is
    signal currentWriter : std_logic;

begin
    everyClock : process(clk)
    begin
        if (rising_edge(clk)) then
            if delayEnable then
                currentWriter <= writer;
                schedule <= delay;
            elsif (not blocking) then
                schedule <= ("0" & schedule(6 downto 0));
            end if;

            if (schedule(0) = '1') then
                if (currentWriter = '0') then
                    value <= writeLineA;
                else
                    value <= writeLineB;
                end if;
            end if;
        end if;
    end process;

end Implementation;
