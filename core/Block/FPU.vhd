library ieee;
use ieee.std_logic_1164.all;
use work.types.all;

entity FPU is
    port (
        clk : in std_logic;
        code : in std_logic_vector(2 downto 0);
        funct : in std_logic_vector(1 downto 0);
        tagD : in tag_t;
        valA : in value_t;
        valB : in value_t;
        tag1 : buffer tag_t := (others => '0');
        tag2 : buffer tag_t := (others => '0');
        emitTag : out tag_t := (others => '0');
        emitVal : out value_t);
end FPU;

architecture Implementation of FPU is
    component FAdd
        port (
            clk : in std_logic;
            flt_in1 : in  std_logic_vector(31 downto 0);
            flt_in2 : in  std_logic_vector(31 downto 0);
            flt_out : out std_logic_vector(31 downto 0));
    end component;

    component FMul
        port (
            clk : in std_logic;
            flt_in1 : in  std_logic_vector(31 downto 0);
            flt_in2 : in  std_logic_vector(31 downto 0);
            flt_out : out std_logic_vector(31 downto 0));
    end component;

    component ItoF
        port (
            clk : in std_logic;
            i : in  std_logic_vector(31 downto 0);
            f : out std_logic_vector(31 downto 0));
    end component;

    signal a_sgn, b_sgn : std_logic;
    signal a_exp, b_exp : std_logic_vector(7 downto 0);
    signal a_frc, b_frc : std_logic_vector(22 downto 0);

    constant z_exp : std_logic_vector(7 downto 0) := (others => '0');
    constant h_exp : std_logic_vector(7 downto 0) := (others => '1');
    constant z_frc : std_logic_vector(22 downto 0) := (others => '0');
    constant o_frc : std_logic_vector(22 downto 0) := x"00000" & "001";
    signal invalid : boolean;

    signal code1, code2 : std_logic_vector(2 downto 0) := (others => '0');
    signal funct1, funct2, funct3 : std_logic_vector(1 downto 0) := (others => '0');

    signal a1, b1, d2, d3, d_fadd, d_fmul, d_finv, d_fflr, d_fsqr, d_itof : std_logic_vector(31 downto 0) := (others => '0');

begin
    pipe0 : process(clk)
    begin
        if rising_edge(clk) then
            a1 <= std_logic_vector(valA);
            b1 <= std_logic_vector(valB);
            code1 <= code;
            funct1 <= funct;
            tag1 <= tagD;
        end if;
    end process;

    fadd_map : FAdd port map (
        clk => clk,
        flt_in1 => a1,
        flt_in2 => b1,
        flt_out => d_fadd);

    fmul_map : FMul port map (
        clk => clk,
        flt_in1 => a1,
        flt_in2 => b1,
        flt_out => d_fmul);

    -- TODO
    d_finv <= (others => '1');
    d_fsqr <= (others => '1');

    itof_map : ItoF port map (
        clk => clk,
        i => a1,
        f => d_itof);

    a_sgn <= a1(31);
    b_sgn <= b1(31);
    a_exp <= a1(30 downto 23);
    b_exp <= b1(30 downto 23);
    a_frc <= a1(22 downto 0);
    b_frc <= b1(22 downto 0);
    invalid <= (a_exp = h_exp or b_exp = h_exp) and code1 /= "111";

    pipe1 : process(clk)
    begin
        if rising_edge(clk) then
            case code1 is
                when "000" =>
                    if b_exp /= h_exp then
                        d2 <= a_sgn & h_exp & a_frc;
                    elsif b_exp /= h_exp then
                        d2 <= b_sgn & h_exp & b_frc;
                    else
                        d2 <= (a_sgn and b_sgn) & h_exp & (a_frc or b_frc or (x"00000" & "00" & (a_sgn xor b_sgn)));
                    end if;
                when "001" =>
                    if b_exp /= h_exp then
                        d2 <= a_sgn & h_exp & a_frc;
                    elsif b_exp /= h_exp then
                        d2 <= not b_sgn & h_exp & b_frc;
                    else
                        d2 <= (a_sgn and not b_sgn) & h_exp & (a_frc or b_frc or (x"00000" & "00" & (a_sgn xor (not b_sgn))));
                    end if;
                when "010" =>
                    if a_exp = z_exp or b_exp = z_exp then
                        d2 <= (a_sgn xor b_sgn) & h_exp & o_frc;
                    else
                        d2 <= (a_sgn xor b_sgn) & h_exp & (a_frc or b_frc);
                    end if;
                when "011" =>
                    if a_frc = z_frc then
                        d2 <= a_sgn & z_exp & z_frc;
                    else
                        d2 <= a_sgn & h_exp & o_frc;
                    end if;
                when "100" =>
                    if a_sgn = '1' then
                        d2 <= '1' & h_exp & o_frc;
                    else
                        d2 <= valA;
                    end if;
                when "101" =>
                    d2 <= valA;
                when "110" =>
                    -- TODO
                    d2 <= valA;
                when others =>
                    d2 <= valA;
            end case;

            if invalid then
                code2 <= "101";
            else
                code2 <= code1;
            end if;

            funct2 <= funct;
            tag2 <= tag1;
        end if;
    end process;

    pipe2 : process(clk)
    begin
        if rising_edge(clk) then
            case code2 is
                when "000" =>
                    d3 <= d_fadd;
                when "001" =>
                    d3 <= d_fadd;
                when "010" =>
                    d3 <= d_fmul;
                when "011" =>
                    d3 <= d_finv;
                when "100" =>
                    d3 <= d_fsqr;
                when "101" =>
                    d3 <= d2;
                when "110" =>
                    d3 <= d_fflr;
                when others =>
                    d3 <= d_itof;
            end case;

            emitTag <= tag2;
            funct3 <= funct2;
        end if;
    end process;

    with funct3 select
        emitVal <= value_t(d3) when "00",
                   value_t(not d3(31) & d3(30 downto 0)) when "01",
                   value_t('0' & d3(30 downto 0)) when "10",
                   value_t('1' & d3(30 downto 0)) when others;

end Implementation;
