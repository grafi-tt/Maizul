library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity Branch is
    port (
        clk : in std_logic;
        code : in std_logic_vector(4 downto 0);
        tagL : in tag_t;
        valA : in value_t;
        valB : in value_t;
        link : in blkram_addr;
        target : in blkram_addr;
        emitTag : out tag_t := (others => '0');
        emitLink : out blkram_addr := (others => '0');
        emitTarget : out blkram_addr := (others => '0');
        result : out boolean := false);
end Branch;

architecture BranchImp of Branch is
    signal c : std_logic_vector(2 downto 0) := "000";
    signal a : value_t := (others => '0');
    signal b : value_t := (others => '0');

begin
    sequential : process(clk)
    begin
        if rising_edge(clk) then
            c <= code(4) & code(1 downto 0); -- eliminating redundant bit
            emitTag <= tagL;
            a <= valA;
            b <= valB;
            emitLink <= link;
            emitTarget <= target;
        end if;
    end process;

    combinatorial : process(c, a, b)
        variable ieq, ilt, feq, flt : boolean;
        variable tmp_lt, tmp_z_a, tmp_z_b : boolean;
        constant z31 : std_logic_vector(30 downto 0) := (others => '0');

    begin
        tmp_lt := unsigned(a(30 downto 0)) < unsigned(b(30 downto 0));
        tmp_z_a := a(30 downto 0) = z31;
        tmp_z_b := b(30 downto 0) = z31;

        ieq := a = b;
        ilt := (a(31) = '1' and b(31) = '0') or
               ((a(31) = b(31)) and tmp_lt);
        feq := ieq or (tmp_z_a and tmp_z_b);
        flt := (a(31) = '1' and b(31) = '0') or
               (a(31) = '0' and b(31) = '0' and tmp_lt) or
               (a(31) = '1' and b(31) = '1' and not tmp_lt);

        case c is
            when "000" => result <= ieq;
            when "001" => result <= not ieq;
            when "010" => result <= ilt;
            when "011" => result <= not ilt and not ieq;
            when "100" => result <= feq;
            when "101" => result <= not feq;
            when "110" => result <= flt and not feq;
            when "111" => result <= not flt and not feq;
            when others => assert false;
        end case;
    end process;

end BranchImp;
