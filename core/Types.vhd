library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is
    subtype instruction_t is
        std_logic_vector(31 downto 0);
    subtype value_t is
        std_logic_vector(31 downto 0);
    subtype tag_t is
        std_logic_vector(4 downto 0);
    subtype blkram_addr is
        unsigned(15 downto 0);
    subtype sram_addr is
        unsigned(19 downto 0);
end;
