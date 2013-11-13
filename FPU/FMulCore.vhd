library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FMul is
    port (
        clk : in std_logic;
        flt_in1 : in  std_logic_vector(31 downto 0);
        flt_in2 : in  std_logic_vector(31 downto 0);
        flt_out : out std_logic_vector(31 downto 0));
end FMul;

architecture Implementation of FMul is
    signal s1_sgn : std_logic;
    signal s1_exp_add : std_logic_vector(9 downto 0);
    signal s1_frc_all : std_logic_vector(47 downto 0);

    signal s2_sgn : std_logic := '0';
    signal s2_exp_add : std_logic_vector(9 downto 0) := (others => '0');
    signal s2_frc_all : std_logic_vector(47 downto 0) := (others => '0');
    signal s2_exp : std_logic_vector(9 downto 0) := (others => '0');
    signal s2_exp_up : std_logic_vector(9 downto 0) := (others => '0');
    signal s2_ulp : std_logic_vector(25 downto 0) := (others => '0');
    signal s2_frc : std_logic_vector(25 downto 0) := (others => '0');
    signal s2_frc_up : std_logic_vector(25 downto 0) := (others => '0');
    signal s2_tail_any : std_logic := '0';
    signal s2_round : std_logic := '0';

    signal s3_sgn : std_logic := '0';
    signal s3_exp : std_logic_vector(9 downto 0) := (others => '0');
    signal s3_exp_up : std_logic_vector(9 downto 0) := (others => '0');
    signal s3_frc : std_logic_vector(25 downto 0) := (others => '0');
    signal s3_frc_up : std_logic_vector(25 downto 0) := (others => '0');
    signal s3_round : std_logic := '0';
    signal s3_frc_out_tmp : std_logic_vector(25 downto 0);
    signal s3_exp_out_tmp : std_logic_vector(9 downto 0);
    signal s3_frc_out : std_logic_vector(22 downto 0);
    signal s3_exp_out : std_logic_vector(7 downto 0);

begin
    s1_sgn <= flt_in1(31) xor flt_in2(31);
    s1_exp_add <= ("00" & flt_in1(30 downto 23)) + ("00" & flt_in2(30 downto 23));
    s1_frc <= unsigned('1' & flt_in1(22 downto 0)) * unsigned('1' & flt_in2(22 downto 0));

    pipe1 : process(clk)
    begin
        if rising_edge(clk) then
            s2_sgn <= s1_sgn;
            s2_exp_add <= s1_exp_add;
            s2_frc_all <= s1_frc_all;
        end if;
    end process;

    s2_exp <= s1_exp_all - "0000111111";
    s2_exp_up <= s1_exp_all - "0000111110";
    s2_frc <= s2_frc_all(47 downto 23);
    s2_ulp <= x"00000" & "00001" when s2_frc(24) = '0' else x"00000" & "00010";
    s2_frc_up <= s2_frc + s2_ulp;
    s2_tail_any <= s2_frc(21 downto 0) /= (others => '0');
    s2_round <= (s2_frc(22) and s2_tail_any) or (s2_frc(23) and s2_frc(22)) when s2_frc(47) = '0' else
                (s2_frc(23) and (s2_frc(22) or s2_tail_any)) or (s2_frc(24) and s2_frc(23));

    pipe2 : process(clk)
    begin
        if rising_edge(clk) then
            s3_sgn <= s2_sgn;
            s3_exp <= s2_exp;
            s3_exp_up <= s2_exp_up;
            s3_frc <= s2_frc;
            s3_frc_up <= s2_frc_up;
            s3_round <= s2_round;
        end if;
    end process;

    s3_frc_out_tmp <= s3_frc when s3_round = '0' else s3_frc_up;
    s3_exp_out_tmp <= s3_exp when s3_frc_out_tmp(24) = '0' else s3_exp_up;
    s3_exp_out <= "00000000" when s3_exp_out_tmp(9) = '1' else
                  "11111111" when s3_exp_out_tmp(8) = '1' else
                  s3_exp_out_tmp;
    s3_frc_out <= (others => "0") when s3_exp_out = "00000000" or s3_exp_out = "11111111" else
                  s3_frc_out_tmp(23 downto 1) when s3_frc_out_tmp(47) = '0' else
                  s3_frc_out_tmp(24 downto 2);
    frc_out <= s3_sgn & s3_exp_out & s3_frc_out;

end Implementation;
