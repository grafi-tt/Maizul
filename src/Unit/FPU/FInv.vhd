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
    entity finv_table is
      port (
        clk : in  std_logic;
        key : in  std_logic_vector(9 downto 0);
        val : out std_logic_vector(35 downto 0) := (others => '0'));
    end finv_table;

    signal key : std_logic_vector(9 downto 0) := (others => '0');
    signal rest : std_logic_vector(12 downto 0) := (others => '0');
    signal sgn, sgn_ : std_logic := '0';
    signal exp_in, exp_in_ : std_logic_vector(7 downto 0) := (others => '0');
    signal a0, a0_ : std_logic_vector(22 downto 0) := (others => '0');
    signal a1, a1_ : std_logic_vector(12 downto 0) := (others => '0');
    signal t1, t1_ : std_logic_vector(22 downto 0) := (others => '0');
    signal no_flow1, now_flow1_, no_flow2, no_flow2_, frc_any, frc_any_ : std_logic := '0';

begin
    conbinatorial1 : process(flt_in)
    begin
        key <= flt_in(22 downto 13);
    end process;
    table_map : FInvTable port map (clk => clk, key => key, val => val);

    sequential2 : process(clk)
    begin
        if rising_edge(clk) then
            sgn <= flt_in(31);
            exp_in <= flt_in(30 downto 23);
            rest <= flt_in(12 downto 0);
            frc_any <= flt_in(22 downto 0) = 0;
            a0 <= val(35 downto 13);
            a1 <= val(12 downto 0);
        end if;
    end process;

    conbinatorial2 : process(exp_in, a1, rest)
        variable tmp : std_logic_vector(25 downto 0);
    begin
        no_flow1 <= exp_in /= "0xFD";
        no_flow2 <= exp_in /= "0xFE";
        tmp := a1 * rest;
        t1 <= "000000000" & tmp(25 downto 12);
    end process;

    sequential3 : process(clk)
    begin
        if rising_edge(clk) then
            no_flow1_ <= no_flow1;
            no_flow2_ <= no_flow2;
            frc_any_ <= frc_any;
            exp_in_ <= exp_in;
            sgn_ <= sgn;
            a0_ <= a0;
            t1_ <= t1;
        end if;
    end process;

    conbinatorial3 : process(no_flow1_, no_flow2_, frc_any_, exp_in_, sgn_, a0_, t1_)
        variable std_logic_vector(7 downto 0) exp_out;
        variable std_logic_vector(22 downto 0) frc_out;
    begin
        exp_out := add_unsigned(x"FE", not exp_in_, not (frc_any_ and no_flow2_));
        if (frc_any_ and no_flow1_ and no_flow2_) = '1' then
            frc_out := a0_ - t1_(25 downto 12);
        else
            frc_out := 0;
        end if;
        flt_out <= sgn_ & exp_out & frc_out;
    end process;

end twoproc_pipeline;
