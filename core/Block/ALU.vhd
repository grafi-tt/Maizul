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
        emitTag : out tag_t;
        emitVal : out value_t);
end ALU;

architecture Implementation of ALU is
    signal s : value_t;
    signal t : value_t;

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
    signal mulD : std_logic_vector(63 downto 0);

    signal result : value_t;
    constant zeroPad : std_logic_vector(31 downto 1) := (others => '0');

begin
    every_clock_do : process(clk)
    begin
        if rising_edge(clk) then
            emitTag <= tagD;
            s <= valA;
            t <= valB;
        end if;
    end process;

    addD <= std_logic_vector(unsigned(s) + unsigned(t));
    subD <= std_logic_vector(unsigned(s) - unsigned(t));

    eqD <= '1' when s = t else '0';
    ltD <= '1' when signed(s) < signed(t) else '0';

    andD <= s and t;
    xorD <= s xor t;
    orD <= s or t;

    sllD <= std_logic_vector(shift_left(unsigned(s), to_integer(unsigned(s(4 downto 0)))));
    srlD <= std_logic_vector(shift_right(unsigned(s), to_integer(unsigned(s(4 downto 0)))));
    sraD <= std_logic_vector(shift_right(signed(s), to_integer(unsigned(s(4 downto 0)))));

    catD <= t(15 downto 0) & s(15 downto 0);
    mulD <= std_logic_vector((unsigned(t) * unsigned(s)));

    with code select
        emitVal <= addD when "0000",
                   subD when "0001",
                   zeroPad & eqD when "0010",
                   zeroPad & ltD when "0011",
                   andD when "0100",
                   orD  when "0101",
                   xorD when "0110",
                   sllD when "0111",
                   srlD when "1000",
                   sraD when "1001",
                   catD when "1010",
                   mulD(31 downto 0) when "1011",
                   -- TODO floating point related
                   (others => '0') when others;

end Implementation;
