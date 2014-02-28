library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FInv is
    port (
        clk : in std_logic;
        flt_in  : in  std_logic_vector(31 downto 0);
        flt_out : out std_logic_vector(31 downto 0));
end FInv;

architecture twoproc_pipeline of FInv is
    component FInvTable is
      port (
        clk : in  std_logic;
        k : in  std_logic_vector(9 downto 0);
        v : out std_logic_vector(35 downto 0) := (others => '0'));
    end component;

    signal k : std_logic_vector(9 downto 0) := (others => '0');
    signal v : std_logic_vector(35 downto 0);
    signal rest : unsigned(12 downto 0) := (others => '0');
    signal sgn, sgn_p : std_logic := '0';
    signal exp_in, exp_in_p : unsigned(7 downto 0) := (others => '0');
    signal a0, a0_p : unsigned(22 downto 0) := (others => '0');
    signal a1, a1_p : unsigned(12 downto 0) := (others => '0');
    signal t1, t1_p : unsigned(22 downto 0) := (others => '0');
    signal no_flow1, no_flow1_p, no_flow2, no_flow2_p, frc_any, frc_any_p : std_logic := '0';

begin
    conbinatorial1 : process(flt_in)
    begin
        k <= flt_in(22 downto 13);
    end process;
    table_map : FInvTable port map (clk => clk, k => k, v => v);

    sequential2 : process(clk)
    begin
        if rising_edge(clk) then
            sgn <= flt_in(31);
            exp_in <= unsigned(flt_in(30 downto 23));
            rest <= unsigned(flt_in(12 downto 0));
            if unsigned(flt_in(22 downto 0)) = 0 then
                frc_any <= '0';
            else
                frc_any <= '1';
            end if;
            a0 <= unsigned(v(35 downto 13));
            a1 <= unsigned(v(12 downto  0));
        end if;
    end process;

    conbinatorial2 : process(exp_in, a1, rest)
        variable tmp : unsigned(25 downto 0);
    begin
        if exp_in = x"FD" then
            no_flow1 <= '0';
        else
            no_flow1 <= '1';
        end if;
        if exp_in = x"FE" then
            no_flow2 <= '0';
        else
            no_flow2 <= '1';
        end if;
        tmp := a1 * rest;
        t1 <= "000000000" & tmp(25 downto 12);
    end process;

    sequential3 : process(clk)
    begin
        if rising_edge(clk) then
            no_flow1_p <= no_flow1;
            no_flow2_p <= no_flow2;
            frc_any_p <= frc_any;
            exp_in_p <= exp_in;
            sgn_p <= sgn;
            a0_p <= a0;
            t1_p <= t1;
        end if;
    end process;

    conbinatorial3 : process(no_flow1_p, no_flow2_p, frc_any_p, exp_in_p, sgn_p, a0_p, t1_p)
        variable exp_out : unsigned(7 downto 0);
        variable frc_out : unsigned(22 downto 0);
    begin
        if exp_in_p = x"00" then
            exp_out := x"FF";
        else
            exp_out := x"FE" - exp_in_p - unsigned'(0 => (frc_any_p and no_flow2_p));
        end if;
        if (frc_any_p and no_flow1_p and no_flow2_p) = '1' then
            frc_out := a0_p - t1_p;
        else
            frc_out := (others => '0');
        end if;
        flt_out <= std_logic_vector(sgn_p & exp_out & frc_out);
    end process;

end twoproc_pipeline;
