library ieee;
use ieee.std_logic_1164.all;
use work.types.all;

entity IO is
    port (
        clk : in std_logic;
        enable : in boolean;
        code : in std_logic;
        serialOk : out std_logic;
        serialGo : out std_logic;
        serialRecvData : in std_logic_vector(7 downto 0);
        serialSendData : out std_logic_vector(7 downto 0);
        serialRecved : in std_logic;
        serialSent : in std_logic;
        getTag : in tag_t;
        putVal : in value_t;
        emitTag : out tag_t := (others => '0');
        emitVal : out value_t := (others => '0');
        blocking : out boolean);
end IO;

architecture Implementation of IO is
    type state_t is (Sleep, Recv, Send);
    signal state : state_t := Sleep;
    signal byteState : integer range 3 downto 0 := 3;
    signal buf : value_t := (others => '0');
    signal ok, go : std_logic := '0';

begin
    every_clock_do : process(clk)
    begin
        if (rising_edge(clk)) then
            case state is
                when Sleep =>
                    if enable then
                        case code is
                            when "00" =>
                                state <= Recv;
                            when "01" =>
                                state <= Send;
                            when "10" =>
                                state <= Recv;
                                byteState <= 0;
                            when others =>
                                state <= Send;
                                byteState <= 0;
                        end case;
                        emitTag <= getTag;
                        buf <= putVal;
                    end if;

                when Recv =>
                    if serialRecved = '1' and ok = '0' then
                        ok <= '1';
                    end if;

                    if serialRecved = '0' and ok = '1' then
                        ok <= '0';
                        buf <= buf(23 downto 0) & serialRecvData;
                        if byteState = 0 then
                            byteState <= 3;
                            state <= Sleep;
                        else
                            byteState <= byteState - 1;
                        end if;
                    end if;

                when Send =>
                    if serialSent = '1' and go = '0' then
                        go <= '1';
                    end if;

                    if serialSent = '0' and go = '1' then
                        go <= '0';
                        buf <= buf(23 downto 0) & x"00";
                        if byteState = 0 then
                            byteState <= 3;
                            state <= Sleep;
                        else
                            byteState <= byteState - 1;
                        end if;
                    end if;
            end case;
        end if;
    end process;

    serialOk <= ok;
    serialGo <= go;
    serialSendData <= buf(31 downto 24);
    emitVal <= buf;
    blocking <= state /= Sleep;

end Implementation;
