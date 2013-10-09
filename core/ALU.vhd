library ieee, cpuex;
use ieee.std_logic_1164.all;

library cpuex;
use cpuex.cpuex_types.all;

entity ALU is
    port (
        enable : in std_logic;
        code : in std_logic_vector(3 downto 0);

        opS : in value;
        opT : in value;

        outLine : out value);
end ALU;

architecture Implementation of ALU is
    signal s : std_logic;
    signal t : std_logic;

    signal add : std_logic_vector(31 downto 0);
    signal sub : std_logic_vector(31 downto 0);
    signal eq : std_logic;
    signal lt : std_logic;

    signal zeroPad : std_logic_vector(31 downto 1) := (others => '0');
    signal result : value;

begin
    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            s <= opS;
            t <= opT;
        end if;
    end process;

    add <= s + t;
    sub <= s - t;
    eq <= std_logic(s = t);
    lt <= std_logic(s < t);

    with code select
        result <= add when "0000",
                  sub when "0001",
                  zeroPad & eq when "0100",
                  zeroPad & (not eq) when "0101",
                  zeroPad & lt when "0110",
                  zeroPad & (eq or lt) when "0111",
                  (others => 0) when others;

    outLine <= result when enable = '1' else
               (others => '0');
end Implementation;
