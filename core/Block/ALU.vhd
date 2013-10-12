library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity ALU is
    port (
        clk : in std_logic;

        enable : in boolean;
        code : in std_logic_vector(3 downto 0);

        opS : in value_t;
        opT : in value_t;

        outLine : out value_t);
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
    signal rolD : value_t;

    signal catD : value_t;
    signal sllD  : value_t;
    signal srlD  : value_t;
    signal sraD  : value_t;

    signal zeroPad : std_logic_vector(31 downto 1) := (others => '0');
    signal result : value_t;

begin
    every_clock_do : process(clk)
    begin
        if rising_edge(clk) then
            s <= opS;
            t <= opT;
        end if;
    end process;

    xorD <= s xor t;
    andD <= s and t;
    orD <= s or t;
    rolD <= std_logic_vector(rotate_left(unsigned(s), to_integer(unsigned(s(4 downto 0)))));

    addD <= std_logic_vector(unsigned(s) + unsigned(t));
    subD <= std_logic_vector(unsigned(s) - unsigned(t));
    eqD <= '1' when s = t else '0';
    ltD <= '1' when s < t else '0';

    catD <= t(15 downto 0) & s(15 downto 0);
    sllD <= std_logic_vector(shift_left(unsigned(s), to_integer(unsigned(s(4 downto 0)))));
    srlD <= std_logic_vector(shift_right(unsigned(s), to_integer(unsigned(s(4 downto 0)))));
    sraD <= std_logic_vector(shift_right(signed(s), to_integer(unsigned(s(4 downto 0)))));

    with code select
        result <= xorD when "0000",
                  andD when "0001",
                  orD  when "0010",
                  rolD when "0011",
                  addD when "0100",
                  subD when "0101",
                  zeroPad & eqD when "0110",
                  zeroPad & ltD when "0111",
                  catD when "1000",
                  sllD when "1001",
                  srlD when "1010",
                  sraD when "1011",
                  -- now multiplication and conditional move are not supported
                  (others => '0') when others;

    outLine <= result when enable else (others => '0');

end Implementation;
