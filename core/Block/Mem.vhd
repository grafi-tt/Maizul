library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity Mem is
    port (
        clk : in std_logic;
        enable : in boolean;
        base : in sram_addr;
        disp : in sram_addr;
        tag : in tag_t;
        pipeTag1 : buffer tag_t;
        pipeTag2 : buffer tag_t;
        emitTag : out tag_t;
        pipeMode1 : buffer boolean;
        pipeMode2 : buffer boolean;
        emitMode : out boolean;
        sramAddr : out std_logic_vector(19 downto 0);
        sramData : inout value_t;
        sramLoad : out std_logic;
        sramStore : out std_logic);
end Mem;

architecture Connection of Mem is
    signal addr : sram_addr := (others => '0');
    signal load : std_logic;
    signal store : std_logic;

    signal val1 : value_t;

begin
    everyClock : process(clk)
    begin
        if rising_edge(clk) then
        end if;

        val1 <= storeValue;
        storeLine <= val1;
    end process;

    load <= (not code(0)) when enable else '0';
    store <= code(0) when enable else '0';


end Connection;
