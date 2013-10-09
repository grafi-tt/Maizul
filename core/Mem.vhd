library ieee;
use ieee.std_logic_1164.all;

library cpuex;
use cpuex.types.all;

entity Mem is
    port (
        clk : in std_logic;

        enable : in std_logic;
        code : in std_logic_vector(2 downto 0);

        base : in value;
        disp : in std_logic(15 downto 0);

        loadLine : in value;
        storeLine : out value);
end Mem;

architecture Connection of Mem is
    signal addr : std_logic_vector (19 downto 0) := (others => '0');
    signal load : std_logic;
    signal store : std_logic;

begin
    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            addr <= base(19 downto 0) + ("0000" & disp);
            load <= (not code(0)) and enable;
            store <= code(0) and enable;
        end if;
    end process;

end MemImp;
