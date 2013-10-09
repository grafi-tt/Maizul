library ieee;
use ieee.std_logic_1164.all;

entity Branch is
    port (
        clk : in std_logic;

        enable : in std_logic;
        code : in std_logic_vector(2 downto 0);

        opA : in value;
        opB : in value;
        addr : in sram_addr;

        PCLine : out blkram_addr;
        result : out std_logic);
end Branch;

architecture BranchImp of Branch is
    signal rEq : boolean;
    signal uLt : boolean;
    signal sLt : boolean;
    signal fEq : boolean;
    signal fLt : boolean;
    signal ltTmp : boolean;
begin
    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            a <= opA;
            b <= opB;
            PCLine <= addr;
        end if;
    end process;

    ltTmp <= a(30 downto 0) < b(30 downto 0);
    zATmp <= a(30 downto 23) = 0;
    zBTmp <= a(30 downto 23) = 0;

    rEq <= a = b;
    uLt <= (a(31) = '1' and b(31) = '0') or
           ((a(31) = b(31)) and ltTmp);
    sLt <= (a(31) = '0' and b(31) = '1') or
           ((a(31) = b(31)) and ltTmp);
    fEq <= rEq or (zATmp and zBTmp);
    fLt <= (a(31) = '0' and b(31) = '1') or
           ((a(31) = '0' and b(31) = '0') and ltTmp) or
           ((a(31) = '1' and b(31) = '1') and (not ltTmp));


end BranchImp;
