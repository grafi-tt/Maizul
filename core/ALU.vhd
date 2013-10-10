library ieee, cpuex;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library cpuex;
use cpuex.cpuex_types.all;

entity ALU is
    port (
        clk : in std_logic;

        enable : in boolean;
        code : in std_logic_vector(3 downto 0);

        opS : in value;
        opT : in value;

        outLine : out value);
end ALU;

architecture Implementation of ALU is
    signal s : value;
    signal t : value;

    signal add : value;
    signal sub : value;
    signal eq  : std_logic;
    signal lt  : std_logic;

    signal xor_ : value;
    signal and_ : value;
    signal or_  : value;
    signal rol_ : value;

    signal movh : value;
    signal sll_ : value;
    signal srl_ : value;
    signal sra_ : value;

    signal zeroPad : std_logic_vector(31 downto 1) := (others => '0');
    signal result : value;

begin
    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            s <= opS;
            t <= opT;
        end if;
    end process;

    xor_ <= s xor t;
    and_ <= s and t;
    or_ <= s or t;
    rol_ <= rotate_left(unsigned(s), to_integer(unsigned(s(4 downto 0))));

    add <= unsigned(s) + unsigned(t);
    sub <= unsigned(s) - unsigned(t);
    eq <= '1' when s = t else '0';
    lt <= '1' when s < t else '0';

    movh <= t(15 downto 0) & s(15 downto 0);
    sll_ <= shift_left(unsigned(s), to_integer(unsigned(s(4 downto 0))));
    srl_ <= shift_right(unsigned(s), to_integer(unsigned(s(4 downto 0))));
    sra_ <= shift_right(signed(s), to_integer(unsigned(s(4 downto 0))));

    with code select
        result <= xor_ when "0000",
                  and_ when "0001",
                  or_  when "0010",
                  rol_ when "0011",
                  add  when "0100",
                  sub  when "0101",
                  zeroPad & eq when "0110",
                  zeroPad & lt when "0111",
                  movh when "1000",
                  sll_ when "1000",
                  srl_ when "1000",
                  sra_ when "1000",
                  -- now multiplication and conditional move are not supported
                  (others => 0) when others;

    outLine <= result when enable else (others => '0');

end Implementation;
