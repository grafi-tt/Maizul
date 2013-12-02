library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity ALU is
    port (
        clk : in std_logic;
        code : in std_logic_vector(3 downto 0);
        tagD : in tag_t;
        valA : in value_t;
        valB : in value_t;
        emitTag : out tag_t := (others => '0');
        emitVal : out value_t);
end ALU;

architecture Implementation of ALU is
    component FtoI
        port (
            clk : in std_logic;
            f : in  std_logic_vector(31 downto 0);
            i : out std_logic_vector(31 downto 0));
    end component;
    signal d_ftoi : std_logic_vector(31 downto 0);

    signal c : std_logic_vector(3 downto 0) := "0000";
    signal s : value_t := (others => '0');
    signal t : value_t := (others => '0');

    function boolean_value(b : boolean) return value_t;
    function boolean_value(b : boolean) return value_t is
        constant z31 : std_logic_vector(31 downto 1) := (others => '0');
    begin
        if b then
            return z31 & '1';
        else
            return z31 & '0';
        end if;
    end boolean_value;

begin
    sequential : process(clk)
    begin
        if rising_edge(clk) then
            c <= code;
            emitTag <= tagD;
            s <= valA;
            t <= valB;
        end if;
    end process;

    ftoi_map : FtoI port map (
        clk => clk,
        f => s,
        i => d_ftoi);

    combinatorial : process(c, s, t, d_ftoi)
        variable d_add, d_sub, d_xor, d_and, d_or, d_sll, d_srl, d_sra, d_cat, d_mul : value_t;
        variable d_eq, d_lt, d_feq, d_flt : boolean;
        variable tmp_lt, tmp_z_s, tmp_z_t : boolean;

    begin
        d_add := std_logic_vector(unsigned(s) + unsigned(t));
        d_sub := std_logic_vector(unsigned(s) - unsigned(t));

        tmp_lt := unsigned(s(30 downto 0)) < unsigned(t(30 downto 0));
        tmp_z_s := unsigned(s(30 downto 0)) = 0;
        tmp_z_t := unsigned(t(30 downto 0)) = 0;

        d_eq := s = t;
        d_lt := (s(31) = '1' and t(31) = '0') or (s(31) = t(31) and tmp_lt);

        d_and := s and t;
        d_xor := s xor t;
        d_or := s or t;

        d_sll := std_logic_vector(shift_left(unsigned(s), to_integer(unsigned(t(4 downto 0)))));
        d_srl := std_logic_vector(shift_right(unsigned(s), to_integer(unsigned(t(4 downto 0)))));
        d_sra := std_logic_vector(shift_right(signed(s), to_integer(unsigned(t(4 downto 0)))));

        d_cat := t(15 downto 0) & s(15 downto 0);
        d_mul := value_t((unsigned(s(15 downto 0)) * unsigned(t(15 downto 0))));

        d_feq := d_eq or (tmp_z_s and tmp_z_t);
        d_flt := not d_feq and
                ( (s(31) = '1' and t(31) = '0') or
                  (s(31) = '0' and t(31) = '0' and tmp_lt) or
                  (s(31) = '1' and t(31) = '1' and not tmp_lt));

        case c is
            when "0000" => emitVal <= d_add;
            when "0001" => emitVal <= d_sub;
            when "0010" => emitVal <= boolean_value(d_eq);
            when "0011" => emitVal <= boolean_value(d_lt);
            when "0100" => emitVal <= d_and;
            when "0101" => emitVal <= d_or;
            when "0110" => emitVal <= d_xor;
            when "0111" => emitVal <= d_sll;
            when "1000" => emitVal <= d_srl;
            when "1001" => emitVal <= d_sra;
            when "1010" => emitVal <= d_cat;
            when "1011" => emitVal <= d_mul;
            when "1100" => emitVal <= s;
            when "1101" => emitVal <= value_t(d_ftoi);
            when "1110" => emitVal <= boolean_value(d_feq);
            when "1111" => emitVal <= boolean_value(d_flt);
            when others => assert false;
        end case;
    end process;

end Implementation;
