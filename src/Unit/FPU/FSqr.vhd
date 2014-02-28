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
    entity FSqrTable is
      port (
        clk : in  std_logic;
        key : in  std_logic_vector(9 downto 0);
        val : out std_logic_vector(35 downto 0) := (others => '0'));
    end FsqrTable;

    signal key : std_logic_vector(9 downto 0) := (others => '0');
    signal rest : std_logic_vector(12 downto 0) := (others => '0');
    signal exp_in, exp_in_ : std_logic_vector(7 downto 0) := (others => '0');
    signal a0, a0_ : std_logic_vector(22 downto 0) := (others => '0');
    signal a1, a1_ : std_logic_vector(12 downto 0) := (others => '0');
    signal t1, t1_ : std_logic_vector(22 downto 0) := (others => '0');

begin
    conbinatorial1 : process(flt_in)
    begin
        key <= flt_in(23 downto 14);
    end process;
    table_map : FSqrTable port map (clk => clk, key => key, val => val);

    sequential2 : process(clk)
    begin
        if rising_edge(clk) then
            exp_in <= flt_in(30 downto 23);
            rest <= flt_in(13 downto 0);
            a0 <= val(35 downto 13);
            a1 <= val(12 downto 0);
        end if;
    end process;

    conbinatorial2 : process(a1, rest)
        variable tmp : std_logic_vector(26 downto 0);
    begin
        tmp := a1 * rest;
        t1 <= "000000000" & tmp(26 downto 13);
    end process;

    sequential3 : process(clk)
    begin
        if rising_edge(clk) then
            exp_in_ <= exp_in;
            a0_ <= a0;
            t1_ <= t1;
        end if;
    end process;

    conbinatorial3 : process(exp_in_, a0_, t1_)
        variable std_logic_vector(7 downto 0) exp_out;
        variable std_logic_vector(22 downto 0) frc_out;
    begin
        exp_out := add_unsigned(x"3F", "0" & exp_in_(7 downto 1), exp_in(0));
        frc_out := a0_ + t1_;
        flt_out <= '0' & exp_out & frc_out;
    end process;

end twoproc_pipeline;
