library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Rand128To32 is
    port (
        clk : in std_logic;
        set : in std_logic;
        data : in std_logic_vector(127 downto 0);
        rand : out std_logic_vector(31 downto 0);
        state : out std_logic_vector(127 downto 0));
end Rand128To32;

architecture XORShift of Rand128To32 is
    signal tmp : unsigned(31 downto 0);
    signal uState : unsigned(127 downto 0);
begin
    rand <= std_logic_vector(uState(127 downto 96));
    state <= std_logic_vector(uState);

    tmp <= uState(31 downto 0) xor (uState(31 downto 0) sll 11);
    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            if set = '1' then
                uState <= unsigned(data);
            else
                uState(95 downto 0) <= uState(127 downto 32);
                uState(127 downto 96) <= uState(127 downto 96) xor (uState(127 downto 96) srl 19) xor (tmp xor (tmp srl 8));
            end if;
        end if;
    end process;
end XORShift;
