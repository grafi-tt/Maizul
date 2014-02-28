library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity U232CRecv is
    generic (
        wTime : std_logic_vector(15 downto 0) := x"1B17");
    port (
        clk : in std_logic;
        ok : in std_logic;
        rx_pin : in std_logic;
        data : out std_logic_vector (7 downto 0);
        recf : out std_logic);
end U232CRecv;

architecture statemachine of U232CRecv is
    signal countdown : std_logic_vector(15 downto 0);
    signal buf : std_logic_vector(8 downto 0) := (others => '0');
    signal state : integer range 0 to 11 := 11;
    signal recf_i : std_logic;

begin
    recf <= recf_i;
    recf_i <= '1' when state = 0 else '0';
    buf(8) <= rx_pin;

    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when 11 =>
                    if buf(8) = '1' then
                        -- read start bit at half of wTime
                        countdown <= "0"&wTime(15 downto 1);
                        state <= 10;
                    end if;
                when 10 =>
                    if buf(8) = '0' then
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
                        if buf(8) = '1' then
                            state <= 0;
                        else
                            state <= 11;
                        end if;
                    else
                        countdown <= countdown-1;
                    end if;
                when 0 =>
                    if ok = '1' then
                        state <= 11;
                    end if;
                when others =>
                    if countdown = 0 then
                        buf(7 downto 0) <= buf(8 downto 1);
                        countdown <= wTime;
                        state <= state-1;
                    else
                        countdown <= countdown-1;
                    end if;
            end case;
        end if;
    end process;

    transfer_data : process(recf_i, ok)
    begin
        if recf_i = '1' and rising_edge(ok) then
            data <= buf(7 downto 0);
        end if;
    end process;
end statemachine;
