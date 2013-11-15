library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ItoF is
    port (
        clk : in std_logic;
        i : in  std_logic_vector(31 downto 0);
        f : out std_logic_vector(31 downto 0) := (others => '0'));
end IToF;

architecture Implementation of ItoF is
    type u_frc_ary_t is array (4 downto 0) of unsigned(32 downto 0);
    signal u_frc : u_frc_ary_t;
    signal x_nlz : std_logic_vector(4 downto 0);
    signal u_frc_tmp : unsigned(32 downto 0);
    signal u_frc_norm : unsigned(23 downto 0);
    signal exp_out : std_logic_vector(7 downto 0);
    signal frc_out : std_logic_vector(22 downto 0);
    signal tail_any : std_logic;
    signal round : std_logic;
    signal f_pipe : std_logic_vector(31 downto 0) := (others => '0');

begin
    u_frc(4) <= '0' & unsigned(i) when i(31) = '0' else
                '0' & (x"00000000" - unsigned(i));
    x_nlz(4) <= '0'             when u_frc(4)(32 downto 17) = 0 else '1';
    u_frc(3) <= u_frc(4) sll 16 when u_frc(4)(32 downto 17) = 0 else u_frc(4);
    x_nlz(3) <= '0'             when u_frc(3)(32 downto 25) = 0 else '1';
    u_frc(2) <= u_frc(3) sll 8  when u_frc(3)(32 downto 25) = 0 else u_frc(3);
    x_nlz(2) <= '0'             when u_frc(2)(32 downto 29) = 0 else '1';
    u_frc(1) <= u_frc(2) sll 4  when u_frc(2)(32 downto 29) = 0 else u_frc(2);
    x_nlz(1) <= '0'             when u_frc(1)(32 downto 31) = 0 else '1';
    u_frc(0) <= u_frc(1) sll 2  when u_frc(1)(32 downto 31) = 0 else u_frc(1);
    x_nlz(0) <= '0'             when u_frc(0)(32 downto 32) = 0 else '1';
    u_frc_tmp <= u_frc(0) sll 1 when u_frc(0)(32 downto 32) = 0 else u_frc(0);

    tail_any <= '0' when u_frc_tmp(7 downto 0) = 0 else '1';
    round <= (u_frc_tmp(8) and tail_any) or (u_frc_tmp(9) and u_frc_tmp(8));

    u_frc_norm <= u_frc_tmp(32 downto 9) + (x"00000" & "000" & round);

    frc_out <= std_logic_vector('0' & u_frc_norm(21 downto 0)) when u_frc_norm(23) = '0' else -- round up or `itof(1)` or `itof(0)`, always 0
               std_logic_vector(u_frc_norm(22 downto 0));

    exp_out <= "00000000" when u_frc_tmp(32 downto 31) = "00" else
               "01111111" when u_frc_tmp(32 downto 31) = "01" else
               "100" & std_logic_vector(unsigned(x_nlz) + 1) when u_frc_norm(23) = '0' else
               "100" & x_nlz;

    pipe : process(clk)
    begin
        if rising_edge(clk) then
            f_pipe <= i(31) & exp_out & frc_out;
            f <= f_pipe;
        end if;
    end process;

end Implementation;
