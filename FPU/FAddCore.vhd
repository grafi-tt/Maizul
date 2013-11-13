library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsinged.all;

entity FAdd is
    port (
        clk : in std_logic;
        flt_in1 : in  std_logic_vector(31 downto 0);
        flt_in2 : in  std_logic_vector(31 downto 0);
        flt_out : out std_logic_vector(31 downto 0));
end FAdd;

architecture Implementation of FAdd is
    component FractionLeftPadding
        port (
            frc_in  : in  std_logic_vector(23 downto 0);
            nlz     : out std_logic_vector( 4 downto 0);
            frc_out : out std_logic_vector(23 downto 0));
    end component;

    component FractionRightShifter is
        port (
            frc_in  : in  std_logic_vector(23 downto 0);
            len     : in  std_logic_vector( 4 downto 0);
            frc_out : out std_logic_vector(23 downto 0);
            fst_over_out : out std_logic;
            snd_over_out : out std_logic;
            tail_any_out : out std_logic);
    end component;


    signal s1_sgn1, s1_sgn2 : std_logic;
    signal s1_exp1, s1_exp2 : std_logic_vector( 7 downto 0);
    signal s1_frc1, s1_frc2 : std_logic_vector(23 downto 0);

    signal s1_raw_len_sft : std_logic_vector(8 downto 0);
    signal s1_len_sft : std_logic_vector(4 downto 0);
    signal s1_valid_pos_sft, s1_valid_neg_sft : boolean;
    signal s1_pos_sft : boolean;

    signal s1_sgn_sup, s1_sgn_inf : std_logic;
    signal s1_exp_unif : std_logic_vector(7 downto 0);
    signal s1_frc_inf : std_logic_vector(23 downto 0);
    signal s1_frc_unif_sup, s1_frc_unif_inf : std_logic_vector(23 downto 0);
    signal s1_zero_sft, s1_is_add : boolean := false;


    signal s2_sgn_sup, s2_sgn_inf : std_logic := '0';
    signal s2_exp_unif : std_logic_vector(7 downto 0) := (others => '0');
    signal s2_frc_inf : std_logic_vector(23 downto 0) := (others => '0');
    signal s2_frc_unif_sup, s2_frc_unif_inf : std_logic_vector(23 downto 0) := (others => '0');
    signal s2_fst_over, s2_snd_over, s2_tail_any : std_logic := '0';
    signal s2_zero_sft, s2_is_add : boolean := false;

    signal s2_round_further, s2_round_further_dbl, s2_round_further_hlf : std_logic;
    signal s2_frc_out_adder1, s2_frc_out_adder2 : std_logic_vector(24 downto 0);


    signal s3_sgn_sup, s3_sgn_inf : std_logic := '0';
    signal s3_exp_unif : std_logic_vector(7 downto 0) := (others => '0');
    signal s3_frc_out_adder1, s3_frc_out_adder2 : std_logic_vector(24 downto 0);
    signal s3_zero_sft, s3_is_add : boolean := false;

    signal s3_no_flow, s3_no_down : boolean;
    signal s3_frc_ireg : std_logic_vector(23 downto 0);
    signal s3_nlz : std_logic_vector(4 downto 0);
    signal s3_down_frc : std_logic;
    signal s3_exp_out_sub_raw : std_logic_vector(8 downto 0);

    signal s3_exp_out_add, s3_exp_out_sub : std_logic_vector(7 downto 0);
    signal s3_frc_out_add, s3_frc_out_sub : std_logic_vector(23 downto 0);
    signal s3_sgn_out_sub : std_logic;

begin
    s1_sgn1 <= flt_in1(31);
    s1_exp1 <= flt_in1(30 downto 23);
    s1_frc1 <= '1' & flt_in1(22 downto 0);
    s1_sgn2 <= flt_in2(31);
    s1_exp2 <= flt_in2(30 downto 23);
    s1_frc2 <= '1' & flt_in2(22 downto 0);

    s1_raw_len_pos_sft <= ('0' & s1_exp1) - ('0' & s1_exp2);
    s1_raw_len_neg_sft <= ('0' & s1_exp2) - ('0' & s1_exp1);

    s1_valid_pos_sft <= s1_raw_len_pos_sft(8 downto 5) = "0000";
    s1_valid_neg_sft <= s1_raw_len_neg_sft(8 downto 5) = "0000";
    s1_pos_sft <= s1_raw_len_sft(8) = '0';

    s1_len_sft <= s1_raw_len_neg_sft(4 downto 0) when s1_valid_neg_sft else
                  s1_raw_len_pos_sft(4 downto 0) when s1_valid_pos_sft else
                  "11111";

    s1_sgn_sup <= s1_sgn1 when s1_pos_sft else s1_sgn2;
    s1_sgn_inf <= s1_sgn2 when s1_pos_sft else s1_sgn1;
    s1_exp_unif <= s1_exp1 when s1_pos_sft else s1_exp2;
    s1_frc_unif_sup <= s1_frc1 when s1_pos_sft else s1_frc2;
    s1_frc_inf <= frc2 when s1_pos_sft else s1_frc1;

    s1_zero_sft <= s1_raw_len_pos_sft(8) nand s1_raw_len_neg_sft(8);
    s1_is_add <= s1_sgn1 = s1_sgn2;

    sft_unif_frc_map : FractionRightShifter port map (
        frc_in => s1_frc_inf,
        len => s1_len_sft,
        frc_out => s1_frc_unif_inf,
        fst_over_out => s1_fst_over,
        snd_over_out => s1_snd_over,
        tail_any_out => s1_tail_any);

    pipe1: process(clk)
    begin
        if rising_edge(clk) then
            s2_sgn_sup <= s1_sgn_sup;
            s2_sgn_inf <= s1_sgn_inf;
            s2_exp_unif <= s1_sgn_unif;
            s2_frc_unif_sup <= s1_frc_unif_sup;
            s2_frc_unif_inf <= s1_frc_unif_inf;
            s2_fst_over <= s1_fst_over;
            s2_snd_over <= s1_snd_over;
            s2_tail_any <= s1_tail_any;
            s2_zero_sft <= s1_zero_sft;
            s2_is_add <= s1_is_add;
        end if;
    end process;

    s2_round_further_hlf <= s2_snd_over and (s2_tail_any or s2_fst_over);
    s2_round_further     <= s2_fst_over and ((s2_snd_over or tail_any) or (frc_unif_sup(0) xor frc_unif_inf(0)));
    s2_round_further_dbl <= (s2_frc_unif_sup(0) and frc_unif_inf(0)) or
                            ( (s2_frc_unif_sup(0) or frc_unif_inf(0)) and
                              (((s2_fst_over or s2_snd_over) or s2_tail_any) or (s2_frc_unif_sup(1) xor s2_frc_unif_inf(1))));


    s2_frc_out_adder1 <= ('0' & s2_frc_unif_sup) + ('0' & s2_frc_unif_inf) + s2_round_further when s2_is_add else
                         ('0' & s2_frc_unif_sup) - ('0' & s2_frc_unif_inf) - s2_round_further;
    s2_frc_out_adder2 <= ("00" & (s2_frc_unif_sup(23 downto 1))) + ("00" & (s2_frc_unif_inf(23 downto 1))) + s2_round_further_dbl when s2_is_add else
                         ('0' & s2_frc_unif_inf) - ('0' & s2_frc_unif_sup) - s2_round_further when s2_zero_sft else
                         ('0' & (s2_frc_unif_sup(22 downto 0)) & '0') - ('0' & (s2_frc_unif_inf(22 downto 0) & s2_fst_over)) - s2_round_further_hlf;

    pipe2: process(clk)
    begin
        if rising_edge(clk) then
            s3_sgn_sup <= s2_sgn_sup;
            s3_sgn_inf <= s2_sgn_inf;
            s3_exp_unif <= s2_exp_unif;
            s3_frc_out_adder1 <= s2_frc_out_adder1;
            s3_frc_out_adder2 <= s2_frc_out_adder2;
            s3_zero_sft <= s2_zero_sft;
            s3_is_add <= s2_is_add;
        end if;
    end process;

    s3_no_flow <= s3_frc_out_adder1(24) = '0';
    s3_no_down <= s3_frc_out_adder1(23) = '1';

    s3_exp_out_add <= s3_exp_unif when s3_no_flow else s3_exp_unif+1;
    s3_frc_out_add <= (others => '0') when s3_exp_out_add = "11111111" else
                      s3_frc_out_adder1(23 downto 0) when s3_no_flow else
                      s3_frc_out_adder2(23 downto 0);

    s3_sgn_out_sub <= s3_sgn_sup when not s3_zero_sft or s3_no_flow else s3_sgn_inf;

    s3_frc_ireg <= s3_frc_out_adder1(23 downto 0) when s3_zero_sft and s3_no_flow else
                   s3_frc_out_adder2(23 downto 0) when s3_zero_sft and not s3_no_flow else
                   s3_frc_out_adder1(23 downto 0) when s3_no_down else
                   s3_frc_out_adder2(23 downto 0);
    pad_frc_ireg_map : FractionLeftPadding port map (
        frc_in => s3_frc_ireg,
        nlz => s3_nlz,
        frc_out => s3_frc_out_sub);

    s3_down_frc <= '0' when s3_zero_sft or s3_no_down else '1';
    s3_exp_out_sub_raw <= ('0' & s3_exp_unif) - ("0000" & s3_nlz) - s3_down_frc;
    s3_exp_out_sub <= s3_exp_out_sub_raw(7 downto 0) when s3_exp_out_sub_raw(8) = '0' else "00000000";

    flt_out <= s3_sgn_sup & s3_exp_out_add & s3_frc_out_add(22 downto 0) when s3_is_add else
               s3_sgn_out_sub & s3_exp_out_sub & s3_frc_out_sub(22 downto 0);

end Implementation;
