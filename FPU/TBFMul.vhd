library ieee;
use ieee.std_logic_1164.ALL;

entity TBFMul is
end TBFMul;

architecture Instantiate of TBFMul is
    signal clk : std_logic;
    signal a, b, d : std_logic_vector(31 downto 0);

    component TBCommon
        port (
            clk : buffer std_logic;
            a : out std_logic_vector(31 downto 0);
            b : out std_logic_vector(31 downto 0);
            d : in  std_logic_vector(31 downto 0));
    end component;

    component FMul
        port (
            clk : in std_logic;
            flt_in1 : in  std_logic_vector(31 downto 0);
            flt_in2 : in  std_logic_vector(31 downto 0);
            flt_out : out std_logic_vector(31 downto 0));
    end component;

begin
    tbcommon_map : port (
        clk => clk,
        a => a,
        b => b,
        d => d);

    fmul_map : port (
        clk => clk,
        flt_in1 => a,
        flt_in2 => b,
        flt_out => d);

end Instantiate;
