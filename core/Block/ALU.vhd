library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity ALU is
    port (
        clk : in std_logic;
        code : in std_logic_vector(3 downto 0);
        tagD : in tag_t;
        valA : in value_t;
        valB : in value_t;
        emitTag : out tag_t := (others => '0');
        emitVal : out value_t);
end ALU;

architecture Implementation of ALU is
    component FtoI
        port (
            clk : in std_logic;
            f : in  std_logic_vector(31 downto 0);
            i : out std_logic_vector(31 downto 0));
    end component;

    signal codeInternal : std_logic_vector(3 downto 0) := "0000";

    signal s : value_t := (others => '0');
    signal t : value_t := (others => '0');

    signal addD : value_t;
    signal subD : value_t;

    signal eqD  : std_logic;
    signal ltD  : std_logic;

    signal xorD : value_t;
    signal andD : value_t;
    signal orD  : value_t;

    signal sllD  : value_t;
    signal srlD  : value_t;
    signal sraD  : value_t;

    signal catD : value_t;
    signal mulD : value_t;

    signal ftoiD : value_t;
    signal feqD  : std_logic;
    signal fltD  : std_logic;

    signal ltTmp : std_logic;
    signal zATmp : std_logic;
    signal zBTmp : std_logic;
    constant z31 : std_logic_vector(31 downto 1) := (others => '0');

begin
    every_clock_do : process(clk)
    begin
        if rising_edge(clk) then
            codeInternal <= code;
            emitTag <= tagD;
            s <= valA;
            t <= valB;
        end if;
    end process;

    addD <= std_logic_vector(unsigned(s) + unsigned(t));
    subD <= std_logic_vector(unsigned(s) - unsigned(t));

    ltTmp <= '1' when unsigned(s(30 downto 0)) < unsigned(t(30 downto 0)) else '0';
    zATmp <= '1' when s(30 downto 0) = z31 else '0';
    zBTmp <= '1' when t(30 downto 0) = z31 else '0';

    eqD <= '1' when s = t else '0';
    ltD <= ((s(31) xor t(31)) and ltTmp) or (not s(31) and t(31));

    andD <= s and t;
    xorD <= s xor t;
    orD <= s or t;

    sllD <= std_logic_vector(shift_left(unsigned(s), to_integer(unsigned(s(4 downto 0)))));
    srlD <= std_logic_vector(shift_right(unsigned(s), to_integer(unsigned(s(4 downto 0)))));
    sraD <= std_logic_vector(shift_right(signed(s), to_integer(unsigned(s(4 downto 0)))));

    catD <= t(15 downto 0) & s(15 downto 0);
    mulD <= value_t((unsigned(t(15 downto 0)) * unsigned(s(15 downto 0))));

    feqD <= eqD or (zATmp and zBTmp);
    fltD <= not feqD and
            ( (s(31) and not t(31)) or
              (not s(31) and not t(31) and ltTmp) or
              (s(31) and t(31) and not ltTmp));

    ftoi_map : FtoI port map (
        clk => clk,
        f => s,
        i => ftoiD);

    with codeInternal select
        emitVal <= addD when "0000",
                   subD when "0001",
                   z31 & eqD when "0010",
                   z31 & ltD when "0011",
                   andD when "0100",
                   orD  when "0101",
                   xorD when "0110",
                   sllD when "0111",
                   srlD when "1000",
                   sraD when "1001",
                   catD when "1010",
                   mulD when "1011",
                   s when "1100",
                   ftoiD when "1101",
                   z31 & feqD when "1110",
                   z31 & fltD when others;

end Implementation;
