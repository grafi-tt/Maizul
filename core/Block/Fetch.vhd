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
        inst : out instruction_t,
        we => in boolean,
        wpc => in blkram_addr,
        winst => in instruction_t);
end Fetch;

architecture Implementation of Fetch is
    component BlkRAM is
        port (
            clk : in std_logic;
            addr : in blkram_addr;
            inst : out instruction_t;
            we : in boolean;
            waddr : in blkram_addr;
            winst : in instruction_t);
    end component;

    signal pcInternal : blkram_addr := (others => '0');

begin
    blkram_map : BlkRAM port map (
        clk => clk,
        addr => pcInternal,
        inst => inst,
        we => we,
        waddr => wpc,
        winst => winst);

    sequential : process(clk)
        signal pcInc : blkram_addr := (others => '0');
        signal pcOld : blkram_addr := (others => '0');

    begin
        if (rising_edge(clk)) then
            pcOld := pcInternal;
            pcInc := pcInternal + 1;

            if stall then
                pcInternal <= pcOld;
            elsif jump then
                pcInternal <= jumpAddr;
            else
                pcInternal <= pcInc;
            end if;
            pc <= pcInc;
        end if;
    end process;

    pcInternal <= pcOld when stall else
                  jumpAddr when jump else
                  pcInc;
    pc <= pcInc;

end Implementation;
