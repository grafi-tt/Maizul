library ieee;
use ieee.std_logic_1164.ALL;

entity TBFMul is
end TBFMul;

architecture Instantiate of TBFMul is
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

    signal clk : std_logic;
    signal a1, b1, d1 : std_logic_vector(31 downto 0);
    signal a2, b2, d2 : std_logic_vector(31 downto 0) := (others => '0');
    signal a3, b3, d3 : std_logic_vector(31 downto 0) := (others => '0');
    signal d_out, d_fmul : std_logic_vector(31 downto 0);
    signal x1 : boolean;
    signal x2, x3 : boolean := false;

    signal a_sgn, b_sgn : std_logic;
    signal a_exp, b_exp : std_logic_vector(7 downto 0);
    signal a_frc, b_frc : std_logic_vector(22 downto 0);

    constant z_exp : std_logic_vector(7 downto 0) := (others => '0');
    constant h_exp : std_logic_vector(7 downto 0) := (others => '1');
    constant z_frc : std_logic_vector(22 downto 0) := (others => '0');
    constant o_frc : std_logic_vector(22 downto 0) := x"00000" & "001";

begin
    tbcommon_map : TBCommon port map (
        clk => clk,
        a => a1,
        b => b1,
        d => d_out);

    fmul_map : FMul port map (
        clk => clk,
        flt_in1 => a1,
        flt_in2 => b1,
        flt_out => d_fmul);

    main : process(clk)
    begin
        if rising_edge(clk) then
            a2 <= a1;
            b2 <= b1;
            d2 <= d1;
            x2 <= x1;

            a3 <= a2;
            b3 <= b2;
            d3 <= d2;
            x3 <= x2;
        end if;
    end process;

    a_sgn <= a1(31);
    b_sgn <= b1(31);
    a_exp <= a1(30 downto 23);
    b_exp <= b1(30 downto 23);
    a_frc <= a1(22 downto 0);
    b_frc <= b1(22 downto 0);

    d1 <= (a_sgn xor b_sgn) & h_exp & o_frc when a_exp = z_exp or b_exp = z_exp else
          (a_sgn xor b_sgn) & h_exp & (a_frc or b_frc);
    x1 <= a_exp = h_exp or b_exp = h_exp;

    d_out <= d3 when x3 else d_fmul;

end Instantiate;
