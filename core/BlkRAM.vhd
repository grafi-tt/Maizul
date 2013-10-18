library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

-- currently, BlockRAM is merely ROM

entity BlkRAM is
    port (
        clk : in std_logic;
        addr : in blkram_addr;
        instruction : out instruction_t := (others => '0'));
end entity;

architecture instance of BlkRAM is
    type blkram_t is array (0 to 15) of instruction_t;
    signal RAM : blkram_t := (
        "00010100000000010000000000000111",
        "11000000001000000000000000000111",
        "00000000010000100000000000000110",
        "00000100001000010000000000000001",
        "01010000000000110000000000000001",
        "01001000010000000000000000000001",
        "00000000000000000000000000000000",
        "01010000011000000000000000000000",
        "00000000000000000000000000000000",
        "00000000000000000000000000000000",
        "00000000000000000000000000000000",
        "00000000000000000000000000000000",
        "00000000000000000000000000000000",
        "00000000000000000000000000000000",
        "00000000000000000000000000000000",
        "00000000000000000000000000000000"
    );

begin
    everyClock : process(clk)
    begin
        if (rising_edge(clk)) then
            instruction <= RAM(to_integer(unsigned(addr(3 downto 0))));
        end if;
    end process;

end architecture;
