library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is
    subtype instruction is
        std_logic_vector(31 downto 0);
    subtype value is
        std_logic_vector(31 downto 0);
    subtype blkram_addr is
        unsigned(15 downto 0);
    subtype sram_addr is
        unsigned(19 downto 0);
    subtype schedule is
        std_logic_vector(15 downto 0);
end;
