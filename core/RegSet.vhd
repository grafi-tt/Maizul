library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity RegSet is
    port (
        clk : in std_logic;
        blocking : in boolean;
        tagS : in tag_t;
        valS : out value_t;
        tagT : in tag_t;
        valT : out value_t;
        tagW : in tag_t;
        lineW : in value_t;
        tagM : in tag_t;
        modeM : in boolean;
        lineM : inout value_t);
end RegSet;

-- TODO : use generic for schedule length
architecture Multiplexer of RegSet is
    component Reg is
        port (
            clk : in std_logic;
            val : buffer value_t;
            enableW : in boolean;
            lineW : in value_t;
            enableM : in boolean;
            modeM : in boolean;
            lineM : inout value_t);
    end component;

    type value_set_t is array(31 downto 0) of value_t;
    signal valSet : value_set_t;

    type enable_w_set is array(31 downto 1) of boolean;
    signal enableWSet : enable_w_set;

    type enable_m_set is array(31 downto 1) of boolean;
    signal enableWSet : enable_w_set;

begin
    valSet(0) <= (others => '0');

    reg_set_gen : for i in 31 downto 1 generate
        reg_port : Reg port map (
            clk => clk,
            val => valSet(i),
            enableW => enableWSet(i);
            lineW => lineW,
            enableM => enableMSet(i);
            modeM => modeM;
            lineM => lineM);

        enableWSet(i) <= to_integer(unsigned(tagW)) = i;
        enableMSet(i) <= to_integer(unsigned(tagM)) = i;
    end generate reg_set_gen;

    valS <= valueSet(to_integer(unsigned(tagS)));
    valT <= valueSet(to_integer(unsigned(tagT)));

end Multiplexer;
