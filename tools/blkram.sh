#!/bin/sh

SIZE=1024

n=$SIZE
SIZE_MGN=0
while [ $n -gt 1 ]; do
    SIZE_MGN=$(expr $SIZE_MGN + 1)
    n=$(expr $n / 2)
done;

cat <<EOS
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity BlkRAM is
    port (
        clk : in std_logic;
        addr : in blkram_addr;
        inst : out instruction_t := (others => '0');
        we : in boolean;
        waddr : in blkram_addr;
        winst : in instruction_t);
end entity;

architecture instance of BlkRAM is
    type blkram_t is array (0 to $(expr $SIZE - 1)) of instruction_t;
    signal RAM : blkram_t := (
    attribute RAM_STYLE : string;
    attribute RAM_STYLE of RAM : signal is "blockram";
    attribute RAM_STYLE of RAM : signal is "blockram";
EOS

i=1
while [ $i -lt $SIZE ]; do
    if read line; then
        true
    else
        line="00000000000000000000000000000000"
    fi
    echo "        \"${line}\","
    i=$(expr $i + 1)
done

if read line; then
    true
else
    line="00000000000000000000000000000000"
fi
echo "        \"${line}\""

cat <<EOS
    );

begin
    everyClock : process(clk)
    begin
        if (rising_edge(clk)) then
            inst <= RAM(to_integer(unsigned(addr($(expr $SIZE_MGN - 1) downto 0))));
            if we then
                RAM(to_integer(unsigned(waddr($(expr $SIZE_MGN - 1) downto 0)))) <= winst;
            end if;
        end if;
    end process;

end instance;
EOS

if read line; then
    exit 1
fi
