library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity Branch is
    port (
        clk : in std_logic;
        code : in std_logic_vector(3 downto 0);
        tagL : in tag_t;
        valA : in value_t;
        valB : in value_t;
        link : in blkram_addr;
        target : in blkram_addr;
        emitTag : out tag_t;
        emitLink : out blkram_addr;
        emitTarget : out blkram_addr;
        result : out boolean);
end Branch;

architecture BranchImp of Branch is
    signal a : value_t;
    signal b : value_t;

    signal rEq : boolean;
    signal sLt : boolean;
    signal fEq : boolean;
    signal fLt : boolean;

    signal ltTmp : boolean;
    signal zATmp : boolean;
    signal zBTmp : boolean;

    constant z31 : std_logic_vector(30 downto 0) := (others => '0');
    signal effCode : std_logic_vector(2 downto 0);

begin
    every_clock_do : process(clk)
    begin
        if rising_edge(clk) then
            emitTag <= tagL;
            a <= valA;
            b <= valB;
            emitLink <= link;
            emitTarget <= target;
        end if;
    end process;

    effCode <= code(3) & code(1 downto 0); -- eliminate redundant bit
    with effCode select
        result <= rEq when "000",
                  not rEq when "001",
                  sLt when "010",
                  sLt or rEq when "011",
                  fEq when "100",
                  not fEq when "101",
                  fLt when "110",
                  fLt or fEq when others; -- "111"

    ltTmp <= unsigned(a(30 downto 0)) < unsigned(b(30 downto 0));
    zATmp <= a(30 downto 0) = z31;
    zBTmp <= b(30 downto 0) = z31;

    rEq <= a = b;
    sLt <= (a(31) = '0' and b(31) = '1') or
           ((a(31) = b(31)) and ltTmp);
    fEq <= rEq or (zATmp and zBTmp);
    fLt <= (a(31) = '0' and b(31) = '1') or
           ((a(31) = '0' and b(31) = '0') and ltTmp) or
           ((a(31) = '1' and b(31) = '1') and (not ltTmp));

end BranchImp;
