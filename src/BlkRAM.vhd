library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity BlkRAM is
    port (
        clk : in std_logic;
        addr : in blkram_addr;
        inst : out instruction_t := (others => '0');
        w : in blkram_write_t);
end entity;

architecture behavioral of BlkRAM is
    type blkram_t is array (0 to 16383) of instruction_t;
    signal RAM : blkram_t := (
        0 => "01010000000000000011111111101011",
        16363 => "00010100000111100000000000000000",
        16364 => "00101000000111010000000000001100",
        16365 => "01011100000000010000000000000010",
        16366 => "01011100000000100000000000000010",
        16367 => "00011100001000010000000000001000",
        16368 => "01000000001000100000100000000101",
        16369 => "01011100000000000000000000000100",
        16370 => "00010100000000100000000000000000",
        16371 => "00000000010000100000000000000001",
        16372 => "01011100000000110000000000000010",
        16373 => "00011100011000110000000000001000",
        16374 => "01011100000001000000000000000010",
        16375 => "01000000100000110001100000000101",
        16376 => "00011100011000110000000000001000",
        16377 => "01011100000001000000000000000010",
        16378 => "01000000100000110001100000000101",
        16379 => "00011100011000110000000000001000",
        16380 => "01011100000001000000000000000010",
        16381 => "01000000100000110001100000000101",
        16382 => "01011100011000000000000000000101",
        16383 => "10001000010000010011111111110011",
        others => (others => '0'));
    attribute ram_style : string;
    attribute ram_style of RAM : signal is "block";

begin
    blk : process(clk)
    begin
        if rising_edge(clk) then
            inst <= RAM(to_integer(unsigned(addr(13 downto 0))));
            if w.enable then
                RAM(to_integer(unsigned(w.addr(13 downto 0)))) <= w.inst;
            end if;
        end if;
    end process;

end behavioral;
