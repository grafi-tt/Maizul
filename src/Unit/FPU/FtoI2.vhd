library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FtoI2 is
    port (
        clk : in std_logic;
        f : in  std_logic_vector(31 downto 0);
        i : out std_logic_vector(31 downto 0));
end FtoI2;

architecture dataflow_pipeline of FtoI2 is
    signal x_len_pre : std_logic_vector(8 downto 0);
    signal u_frc_4_pre : unsigned(31 downto 0);

    signal sgn_p : std_logic := '0';
    signal x_len : std_logic_vector(8 downto 0) := (others => '0');
    signal u_frc_4 : unsigned(31 downto 0) := (others => '0');
    signal u_frc_3, u_frc_2, u_frc_1, u_frc_0, u_frc_o : unsigned(31 downto 0);
    signal any_3, any_2, any_1, any_0, any_o : std_logic;
    signal round : std_logic;
    signal i_err : std_logic_vector(31 downto 0);
    signal err : boolean;

    signal sgn_pp : std_logic := '0';
    signal round_suf : std_logic := '0';
    signal u_frc_v : unsigned(31 downto 0) := (others => '0');
    signal i_err_suf : std_logic_vector(31 downto 0) := (others => '0');
    signal err_suf : boolean := false;

begin
    x_len_pre <= std_logic_vector(unsigned('0' & f(30 downto 23)) - "001111110");
    u_frc_4_pre <= unsigned('1' & f(22 downto 0) & "00000000");

    pipe2 : process(clk)
    begin
        if rising_edge(clk) then
            sgn_p <= f(31);
            x_len <= x_len_pre;
            u_frc_4 <= u_frc_4_pre;
        end if;
    end process;

    any_3 <= '1' when x_len(4) = '0' and u_frc_4(15 downto 0) /= 0 else '0';
    u_frc_3 <= u_frc_4 srl 16 when x_len(4) = '0' else u_frc_4;
    any_2 <= '1' when x_len(3) = '0' and u_frc_3( 7 downto 0) /= 0 else any_3;
    u_frc_2 <= u_frc_3 srl  8 when x_len(3) = '0' else u_frc_3;
    any_1 <= '1' when x_len(2) = '0' and u_frc_2( 3 downto 0) /= 0 else any_2;
    u_frc_1 <= u_frc_2 srl  4 when x_len(2) = '0' else u_frc_2;
    any_0 <= '1' when x_len(1) = '0' and u_frc_1( 1 downto 0) /= 0 else any_1;
    u_frc_0 <= u_frc_1 srl  2 when x_len(1) = '0' else u_frc_1;
    any_o <= '1' when x_len(0) = '0' and u_frc_0( 0 downto 0) /= 0 else any_0;
    u_frc_o <= u_frc_0 srl  1 when x_len(0) = '0' else u_frc_0;

    round <= (u_frc_o(0) and any_o) or (u_frc_o(1) and u_frc_o(0));

    i_err <= x"00000000" when x_len(8) = '1' else
             x"7FFFFFFF" when sgn_p = '0' else
             x"80000000";

    err <= x_len(8) = '1' or x_len(7 downto 5) /= "000";

    pipe3 : process(clk)
    begin
        if rising_edge(clk) then
            sgn_pp <= sgn_p;
            round_suf <= round;
            u_frc_v <= u_frc_o srl 1;
            i_err_suf <= i_err;
            err_suf <= err;
        end if;
    end process;

    i <= i_err_suf when err_suf else
         std_logic_vector(u_frc_v) when sgn_pp = '0' and round_suf = '0' else
         std_logic_vector(u_frc_v + 1) when sgn_pp = '0' and round_suf = '1' else
         std_logic_vector(0 - u_frc_v) when round_suf = '0' else
         std_logic_vector(not u_frc_v);

end dataflow_pipeline;
