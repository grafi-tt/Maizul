library ieee;
use ieee.std_logic_1164.all;
use work.types.all;

entity IO is
    port (
        clk : in std_logic;
        enable : in boolean;
        code : in std_logic;
        serialOk : buffer std_logic;
        serialGo : buffer std_logic;
        serialRecvData : in std_logic_vector(7 downto 0);
        serialSendData : out std_logic_vector(7 downto 0);
        serialRecved : in std_logic;
        serialSent : in std_logic;
        putVal : in value_t;
        getTag : out tag_t;
        getVal : out value_t;
        blocking : out boolean);
end IO;

architecture Implementation of IO is
    type state_t is (Sleep, Recv, Send);
    signal state : state_t := Sleep;
    signal byteState : integer range 4 downto 0 := 4;
    signal buf : value_t := (others => '0');

begin
    every_clock_do : process(clk)
    begin
        if (rising_edge(clk)) then
            if enable then
                if code = '0' then
                    state <= Recv;
                else
                    state <= Send;
                end if;
                buf <= putVal;
            end if;

            case state is
                when Recv =>
                    if serialRecved = '0' and serialOk = '1' then
                        serialOk <= '0';
                        if byteState = 0 then
                            byteState <= 4;
                            state <= Sleep;
                        else
                            byteState <= byteState - 1;
                        end if;
                        if bytestate /= 4 then
                            buf <= buf(23 downto 0) & serialRecvData;
                        end if;
                    end if;

                    if serialRecved = '1' and serialOk = '0' then
                        serialOk <= '1';
                    end if;

                when Send =>
                    if serialSent = '1' and serialGo = '0' then
                        if byteState = 0 then
                            byteState <= 4;
                            state <= Sleep;
                        else
                            serialGo <= '1';
                            byteState <= byteState - 1;
                            buf <= buf(23 downto 0) & "00000000";
                        end if;
                    end if;

                    if serialSent = '0' and serialGo = '1' then
                        serialGo <= '0';
                    end if;

                when Sleep =>
                    null;
            end case;
        end if;
    end process;

    serialSendData <= buf(31 downto 24);
    blocking <= state /= Sleep;
    getLine <= buf;

end Implementation;
