library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity U232CSend is
    generic (
        wTime : std_logic_vector(15 downto 0) := x"1ADB");
    port (
        clk : in std_logic;
        go : in std_logic;
        data : in std_logic_vector (7 downto 0);
        txPin : out std_logic;
        sent : out std_logic);
end U232CSend;

architecture statemachine of U232CSend is
    signal countdown : std_logic_vector(15 downto 0) := wTime;
    signal sendBuf : std_logic_vector(8 downto 0) := (others => '1');
    signal state : integer range 0 to 10 := 10;
    signal sigSent : std_logic := '1';
begin
    sent <= sigSent;
    txPin <= sendBuf(0);

    statemachine : process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when 10 =>
                    if go = '1' then
                        sendBuf <= data&"0";
                        sigSent <= '0';
                        countdown <= wTime;
                        state <= state-1;
                    end if;
                when 0 =>
                    if countdown = 0 then
                        sigSent <= '1';
                        state <= 10;
                    else
                        countdown <= countdown-1;
                    end if;
                when others =>
                    if countdown = 0 then
                        sendBuf <= "1"&sendBuf(8 downto 1);
                        countdown <= wTime;
                        state <= state-1;
                    else
                        countdown <= countdown-1;
                    end if;
            end case;
        end if;
    end process;
end statemachine;
