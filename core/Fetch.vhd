library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library cpuex;
use cpuex.types.all;

entity Fetch is
    port (
        clk : in std_logic;

        stall : in boolean;
        jump : in boolean;
        jumpAddr : in blkram_addr

        instruction : out instruction);
end Fetch;

architecture Implementation of Fetch is
    signal pc : blkram_addr;
    signal pcOld : blkram_addr;
    signal pcInc : blkram_addr;

begin
    begin
        if rising_edge(clk) then
            pcOld <= pc;
            pcInc <= pc + 1;
        end if;
    end process;

    pc <= pcOld when stall else
          jumpAddr when jump else
          pcInc;

    instruction <= (others => '0'); -- TODO connect to block ram!!

end Implementation;
