library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity Fetch is
    port (
        clk : in std_logic;

        stall : in boolean;
        jump : in boolean;
        jumpAddr : in blkram_addr;

        pc : out blkram_addr;
        instruction : out instruction_t);
end Fetch;

architecture Implementation of Fetch is
    signal pcInternal : blkram_addr;
    signal pcInc : blkram_addr;
    signal pcOld : blkram_addr;

begin
    everyClock : process(clk)
    begin
        if (rising_edge(clk)) then
            pcOld <= pcInternal;
            pcInc <= pcInternal + 1;
        end if;
    end process;

    pcInternal <= pcOld when stall else
                  jumpAddr when jump else
                  pcInc;
    pc <= pcInc;
    instruction <= (others => '0'); -- TODO connect to block ram!!

end Implementation;
