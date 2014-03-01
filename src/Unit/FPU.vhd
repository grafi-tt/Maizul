library ieee;
use ieee.std_logic_1164.all;
use work.types.all;

entity FPU is
    port (
        clk : in std_logic;
        code : in std_logic_vector(5 downto 0);
        tagD : in tag_t;
        valA : in value_t;
        valB : in value_t;
        tag1 : buffer tag_t := (others => '0');
        tag2 : buffer tag_t := (others => '0');
        emitTag : out tag_t := (others => '0');
        emitVal : out value_t);
end FPU;

architecture twoproc_pipeline of FPU is
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

    component FInv
        port (
            clk : in std_logic;
            flt_in  : in  std_logic_vector(31 downto 0);
            flt_out : out std_logic_vector(31 downto 0));
    end component;

    component FSqr
        port (
            clk : in std_logic;
            flt_in  : in  std_logic_vector(31 downto 0);
            flt_out : out std_logic_vector(31 downto 0));
    end component;

    component ItoF
        port (
            clk : in std_logic;
            i : in  std_logic_vector(31 downto 0);
            f : out std_logic_vector(31 downto 0));
    end component;

    component FFlr
        port (
            clk : in std_logic;
            f : in  std_logic_vector(31 downto 0);
            g : out std_logic_vector(31 downto 0));
    end component;

    constant z_exp : std_logic_vector(7 downto 0) := (others => '0');
    constant h_exp : std_logic_vector(7 downto 0) := (others => '1');
    constant z_frc : std_logic_vector(22 downto 0) := (others => '0');
    constant o_frc : std_logic_vector(22 downto 0) := x"00000" & "001";

    signal code1, code1_out, code2, code3 : std_logic_vector(2 downto 0) := (others => '0');
    signal funct1, funct2, funct3 : std_logic_vector(1 downto 0) := (others => '0');

    signal a1, b1, d1, d2, d3 : std_logic_vector(31 downto 0) := (others => '0');
    signal b_fadd, d_fadd, d_fmul, d_finv, d_fsqr, d_fflr, d_itof : std_logic_vector(31 downto 0);

begin
    sequential1 : process(clk)
    begin
        if rising_edge(clk) then
            a1 <= std_logic_vector(valA);
            b1 <= std_logic_vector(valB);
            code1 <= code(2 downto 0);
            funct1 <= code(5 downto 4);
            tag1 <= tagD;
        end if;
    end process;

    fadd_map : FAdd port map (
        clk => clk,
        flt_in1 => a1,
        flt_in2 => b_fadd,
        flt_out => d_fadd);
    b_fadd <= (b1(31) xor code1(0)) & b1(30 downto 0);

    fmul_map : FMul port map (
        clk => clk,
        flt_in1 => a1,
        flt_in2 => b1,
        flt_out => d_fmul);

    finv_map : FInv port map (
        clk => clk,
        flt_in => a1,
        flt_out => d_finv);

    fsqr_map : FSqr port map (
        clk => clk,
        flt_in => a1,
        flt_out => d_fsqr);

    fflr_map : FFlr port map (
        clk => clk,
        f => a1,
        g => d_fflr);

    itof_map : ItoF port map (
        clk => clk,
        i => a1,
        f => d_itof);

    combinatorial1 : process(a1, b1, code1)
        variable a_sgn, b_sgn : std_logic;
        variable a_exp, b_exp : std_logic_vector(7 downto 0);
        variable a_frc, b_frc : std_logic_vector(22 downto 0);

    begin
        a_sgn := a1(31);
        b_sgn := b1(31);
        a_exp := a1(30 downto 23);
        b_exp := b1(30 downto 23);
        a_frc := a1(22 downto 0);
        b_frc := b1(22 downto 0);

        case code1 is
            when "000" =>
                if b_exp /= h_exp then
                    d1 <= a_sgn & h_exp & a_frc;
                elsif b_exp /= h_exp then
                    d1 <= b_sgn & h_exp & b_frc;
                else
                    d1 <= (a_sgn and b_sgn) & h_exp & (a_frc or b_frc or (x"00000" & "00" & (a_sgn xor b_sgn)));
                end if;
            when "001" =>
                if b_exp /= h_exp then
                    d1 <= a_sgn & h_exp & a_frc;
                elsif b_exp /= h_exp then
                    d1 <= not b_sgn & h_exp & b_frc;
                else
                    d1 <= (a_sgn and not b_sgn) & h_exp & (a_frc or b_frc or (x"00000" & "00" & (a_sgn xor (not b_sgn))));
                end if;
            when "010" =>
                if a_exp = z_exp or b_exp = z_exp then
                    d1 <= (a_sgn xor b_sgn) & h_exp & o_frc;
                else
                    d1 <= (a_sgn xor b_sgn) & h_exp & (a_frc or b_frc);
                end if;
            when "011" =>
                if a_frc = z_frc then
                    d1 <= a_sgn & z_exp & z_frc;
                else
                    d1 <= a_sgn & h_exp & o_frc;
                end if;
            when "100" =>
                d1 <= a_sgn & a_exp & (a_frc or (x"00000" & "00" & a_sgn));
            when "101" =>
                d1 <= a1;
            when "110" =>
                d1 <= a1;
            when others =>
                d1 <= a1;
        end case;

        if (a_exp = h_exp or b_exp = h_exp) and code1 /= "111" then
            code1_out <= "101";
        else
            code1_out <= code1;
        end if;
    end process;

    sequential2 : process(clk)
    begin
        if rising_edge(clk) then
            d2 <= d1;
            code2 <= code1_out;
            funct2 <= funct1;
            tag2 <= tag1;
        end if;
    end process;

    sequential3 : process(clk)
    begin
        if rising_edge(clk) then
            d3 <= d2;
            code3 <= code2;
            funct3 <= funct2;
            emitTag <= tag2;
        end if;
    end process;

    combinatorial3 : process(code3, funct3, d_fadd, d_fmul, d_finv, d_fsqr, d3, d_fflr, d_itof)
        variable d_out : std_logic_vector(31 downto 0);

    begin
        case code3 is
            when "000" => d_out := d_fadd;
            when "001" => d_out := d_fadd;
            when "010" => d_out := d_fmul;
            when "011" => d_out := d_finv;
            when "100" => d_out := d_fsqr;
            when "101" => d_out := d3;
            when "110" => d_out := d_fflr;
            when "111" => d_out := d_itof;
            when others => assert false;
        end case;

        case funct3 is
            when "00" => emitVal <= value_t(d_out);
            when "01" => emitVal <= value_t(not d_out(31) & d_out(30 downto 0));
            when "10" => emitVal <= value_t('0' & d_out(30 downto 0));
            when "11" => emitVal <= value_t('1' & d_out(30 downto 0));
            when others => assert false;
        end case;
    end process;

end twoproc_pipeline;
