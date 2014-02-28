library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FSqr is
    port (
        clk : in std_logic;
        flt_in  : in  std_logic_vector(31 downto 0);
        flt_out : out std_logic_vector(31 downto 0));
end FSqr;

architecture twoproc_pipeline of FSqr is
    component FSqrTable is
      port (
        clk : in  std_logic;
        k : in  std_logic_vector(9 downto 0);
        v : out std_logic_vector(35 downto 0) := (others => '0'));
    end component;

    signal k : std_logic_vector(9 downto 0) := (others => '0');
    signal v : std_logic_vector(35 downto 0);
    signal rest : unsigned(13 downto 0) := (others => '0');
    signal sgn_in, sgn_in_p : std_logic := '0';
    signal exp_in, exp_in_p : unsigned(7 downto 0) := (others => '0');
    signal a0, a0_p : unsigned(22 downto 0) := (others => '0');
    signal a1, a1_p : unsigned(12 downto 0) := (others => '0');
    signal t1, t1_p : unsigned(22 downto 0) := (others => '0');

begin
    conbinatorial1 : process(flt_in)
    begin
        k <= flt_in(23 downto 14);
    end process;
    table_map : FSqrTable port map (clk => clk, k => k, v => v);

    sequential2 : process(clk)
    begin
        if rising_edge(clk) then
            sgn_in <= flt_in(31);
            exp_in <= unsigned(flt_in(30 downto 23));
            rest <= unsigned(flt_in(13 downto 0));
            a0 <= unsigned(v(35 downto 13));
            a1 <= unsigned(v(12 downto  0));
        end if;
    end process;

    conbinatorial2 : process(a1, rest)
        variable tmp : unsigned(26 downto 0);
    begin
        tmp := a1 * rest;
        t1 <= "000000000" & tmp(26 downto 13);
    end process;

    sequential3 : process(clk)
    begin
        if rising_edge(clk) then
            sgn_in_p <= sgn_in;
            exp_in_p <= exp_in;
            a0_p <= a0;
            t1_p <= t1;
        end if;
    end process;

    conbinatorial3 : process(sgn_in_p, exp_in_p, a0_p, t1_p)
        variable exp_out : unsigned(7 downto 0);
        variable frc_out : unsigned(22 downto 0);
    begin
        if exp_in_p = x"00" then
            exp_out := x"00";
            frc_out := (others => '0');
        elsif sgn_in_p = '1' then
            exp_out := x"FF";
            frc_out := x"00000" & "00" & '1';
        else
            exp_out := x"3F" + ("0" & exp_in_p(7 downto 1)) + unsigned'(0 => exp_in_p(0));
            frc_out := a0_p + t1_p;
        end if;
        flt_out <= std_logic_vector(sgn_in_p & exp_out & frc_out);
    end process;

end twoproc_pipeline;
