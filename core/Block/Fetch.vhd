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
    component BlkRAM is
        port (
            clk : in std_logic;
            addr : in blkram_addr;
            instruction : out instruction_t);
    end component;

    signal pcInternal : blkram_addr := (others => '0');
    signal pcInc : blkram_addr := (others => '0');
    signal pcOld : blkram_addr := (others => '0');

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

    blkram_map : BlkRAM port map (
        clk => clk,
        addr => pcInternal,
        instruction => instruction);

end Implementation;
