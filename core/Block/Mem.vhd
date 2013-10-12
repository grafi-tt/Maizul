library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity Mem is
    port (
        clk : in std_logic;
        stall : out boolean;

        enable : in boolean;
        code : in std_logic_vector(3 downto 0);

        base : in sram_addr;
        disp : in sram_addr;

        storeValue : in value_t;
        outLine : out value_t;

        loadLine : in value_t;
        storeLine : out value_t);
end Mem;

architecture Connection of Mem is
    signal addr : sram_addr := (others => '0');
    signal load : std_logic;
    signal store : std_logic;

    signal val1 : value_t;

begin
    every_clock_do : process(clk)
    begin
        if rising_edge(clk) then
            addr <= sram_addr(unsigned(base) + unsigned(disp));
        end if;
        val1 <= storeValue;
        storeLine <= val1;
    end process;

    load <= (not code(0)) when enable else '0';
    store <= code(0) when enable else '0';

end Connection;
