library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity FloatAdder is
    port (
        fltIn1 : in  std_logic_vector(31 downto 0);
        fltIn2 : in  std_logic_vector(31 downto 0);
        fltOut : out std_logic_vector(31 downto 0));
end FloatAdder;

architecture FAddImp of FloatAdder is
    component FractionLeftPadding
        port (
            frcIn  : in  std_logic_vector(23 downto 0);
            nlz    : out std_logic_vector( 4 downto 0);
            frcOut : out std_logic_vector(23 downto 0));
    end component;

    component FractionRightShifter is
        port (
            frcIn  : in  std_logic_vector(23 downto 0);
            len    : in  std_logic_vector( 4 downto 0);
            frcOut : out std_logic_vector(23 downto 0);
            fstOverOut : out std_logic;
            sndOverOut : out std_logic;
            tailAnyOut : out std_logic);
    end component;

    signal sgn1, sgn2 : std_logic;
    signal exp1, exp2 : std_logic_vector( 7 downto 0);
    signal frc1, frc2 : std_logic_vector(23 downto 0);
    signal isAdd : boolean;

    signal lenRawSft : std_logic_vector(8 downto 0);
    signal lenSft    : std_logic_vector(4 downto 0);
    signal validPosSft, validNegSft : boolean;
    signal zeroSft, posSft : boolean;

    signal sgnSup, sgnInf : std_logic;
    signal expUnif : std_logic_vector(7 downto 0);
    signal frcInf : std_logic_vector(23 downto 0);
    signal frcUnifSup, frcUnifInf : std_logic_vector(23 downto 0);

    signal fstOver, sndOver, tailAny : std_logic;
    signal roundFurther, roundFurtherDbl, roundFurtherHlf : std_logic;

    signal frcOutAdder1, frcOutAdder2 : std_logic_vector(24 downto 0);
    signal noFlow, noDown : boolean;

    signal frcIreg : std_logic_vector(23 downto 0);
    signal nlz : std_logic_vector(4 downto 0);
    signal downFrc : std_logic;
    signal expOutSubRaw : std_logic_vector(8 downto 0);

    signal expOutAdd, expOutSub : std_logic_vector( 7 downto 0);
    signal frcOutAdd, frcOutSub : std_logic_vector(23 downto 0);
    signal sgnOutSub: std_logic;

begin
    sgn1 <= fltIn1(31);
    exp1 <= fltIn1(30 downto 23);
    frc1 <= '1' & fltIn1(22 downto 0);
    sgn2 <= fltIn2(31);
    exp2 <= fltIn2(30 downto 23);
    frc2 <= '1' & fltIn2(22 downto 0);

    lenRawSft <= ('0' & exp1) - ('0' & exp2);

    validPosSft <= lenRawSft(8 downto 5) = "0000";
    zeroSft <= validPosSft and lenRawSft(4 downto 0) = "00000";
    validNegSft <= lenRawSft(8 downto 5) = "1111" and lenRawSft(4 downto 0) /= "00000";
    posSft <= lenRawSft(8) = '0';

    lenSft <= lenRawSft(4 downto 0)           when validPosSft else
              "00000"-(lenRawSft(4 downto 0)) when validNegSft else
              "11111";

    sgnSup <= sgn1 when posSft else sgn2;
    sgnInf <= sgn2 when posSft else sgn1;
    expUnif <= exp1 when posSft else exp2;
    frcUnifSup <= frc1 when posSft else frc2;
    frcInf <= frc2 when posSft else frc1;

    sftUnifFrc: FractionRightShifter port map (
        frcIn => frcInf,
        len => lenSft,
        frcOut => frcUnifInf,
        fstOverOut => fstOver,
        sndOverOut => sndOver,
        tailAnyOut => tailAny);

    roundFurtherHlf <= sndOver and (tailAny or fstOver);
    roundFurther    <= fstOver and ((sndOver or tailAny) or (frcUnifSup(0) xor frcUnifInf(0)));
    roundFurtherDbl <= (frcUnifSup(0) and frcUnifInf(0)) or
                       ( (frcUnifSup(0) or frcUnifInf(0)) and
                         (((fstOver or sndOver) or tailAny) or (frcUnifSup(1) xor frcUnifInf(1))));


    isAdd <= sgn1 = sgn2;

    frcOutAdder1 <= ('0' & frcUnifSup) + ('0' & frcUnifInf) + roundFurther when isAdd else
                    ('0' & frcUnifSup) - ('0' & frcUnifInf) - roundFurther;
    frcOutAdder2 <= ("00" & (frcUnifSup(23 downto 1))) + ("00" & (frcUnifInf(23 downto 1))) + roundFurtherDbl when isAdd else
                    ('0' & frcUnifInf) - ('0' & frcUnifSup) - roundFurther when zeroSft else
                    ('0' & (frcUnifSup(22 downto 0)) & '0') - ('0' & (frcUnifInf(22 downto 0) & fstOver)) - roundFurtherHlf;
    noFlow <= frcOutAdder1(24) = '0';
    noDown <= frcOutAdder1(23) = '1';

    expOutAdd <= expUnif when noFlow else expUnif+1;
    frcOutAdd <= (others => '0') when expOutAdd = "11111111" else
                 frcOutAdder1(23 downto 0) when noFlow else
                 frcOutAdder2(23 downto 0);


    sgnOutSub <= sgnSup when not zeroSft or noFlow else sgnInf;

    frcIreg <= frcOutAdder1(23 downto 0) when zeroSft and noFlow else
               frcOutAdder2(23 downto 0) when zeroSft and not noFlow else
               frcOutAdder1(23 downto 0) when noDown else
               frcOutAdder2(23 downto 0);
    padFrcIreg: FractionLeftPadding port map (
        frcIn => frcIreg,
        nlz => nlz,
        frcOut => frcOutSub);

    downFrc <= '0' when zeroSft or noDown else '1';
    expOutSubRaw <= ('0' & expUnif) - ("0000" & nlz) - downFrc;
    expOutSub <= expOutSubRaw(7 downto 0) when expOutSubRaw(8) = '0' else "00000000";

    fltOut <= sgnSup & expOutAdd & frcOutAdd(22 downto 0) when isAdd else
              sgnOutSub & expOutSub & frcOutSub(22 downto 0);
end FAddImp;
