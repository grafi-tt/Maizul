library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity U232CRecv is
    generic (
        wTime : std_logic_vector(15 downto 0) := x"1B17");
    port (
        clk : in std_logic;
        ok : in std_logic;
        rxPin : in std_logic;
        data : out std_logic_vector (7 downto 0);
        recved : out std_logic);
end U232CRecv;

architecture StateMachine of U232CRecv is
    signal countdown : std_logic_vector(15 downto 0);
    signal recvBuf : std_logic_vector(8 downto 0) := (others => '0');
    signal state : integer range 0 to 11 := 11;
    signal sigRecved : std_logic := '0';
begin
    recved <= sigRecved;
    recvBuf(8) <= rxPin;

    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when 11 =>
                    if recvBuf(8) = '1' then
                        -- read start bit at half of wTime
                        countdown <= "0"&wTime(15 downto 1);
                        state <= 10;
                    end if;
                when 10 =>
                    if recvBuf(8) = '0' then
                        if countdown = 0 then
                            countdown <= wTime;
                            state <= state-1;
                        else
                            countdown <= countdown-1;
                        end if;
                    else
                        countdown <= "0"&wTime(15 downto 1);
                    end if;
                when 1 =>
                    if countdown = 0 then
                        if recvBuf(8) = '1' then
                            sigRecved <= '1';
                            state <= 0;
                        else
                            state <= 11;
                        end if;
                    else
                        countdown <= countdown-1;
                    end if;
                when 0 =>
                    if ok = '1' then
                        data <= recvBuf(7 downto 0);
                        sigRecved <= '0';
                        state <= 11;
                    end if;
                when others =>
                    if countdown = 0 then
                        recvBuf(7 downto 0) <= recvBuf(8 downto 1);
                        countdown <= wTime;
                        state <= state-1;
                    else
                        countdown <= countdown-1;
                    end if;
            end case;
        end if;
    end process;
end StateMachine;
