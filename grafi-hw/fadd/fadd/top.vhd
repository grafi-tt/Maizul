library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity TOP is
    port (
        MCLK1 : in  std_logic;
        RS_RX : in  std_logic;
        RS_TX : out std_logic);
end TOP;

architecture top_body of TOP is
    component FloatAdder is
        port (
            fltIn1 : in  std_logic_vector (31 downto 0);
            fltIn2 : in  std_logic_vector (31 downto 0);
            fltOut : out std_logic_vector (31 downto 0));
    end component;

    component U232C_RECV is
        generic (
            --WTIME : std_logic_vector(15 downto 0) := x"1B17");
            WTIME : std_logic_vector(15 downto 0) := x"0255");
        port (
            CLK : in std_logic;
            OK : in std_logic;
            RX : in std_logic;
            DATA : out std_logic_vector (7 downto 0);
            RECVED : out std_logic);
    end component;

    component U232C_SEND is
        generic (
            --WTIME : std_logic_vector(15 downto 0) := x"1ADB");
            WTIME : std_logic_vector(15 downto 0) := x"0240");
        port (
            CLK : in std_logic;
            GO : in std_logic;
            DATA : in std_logic_vector (7 downto 0);
            TX : out std_logic;
            SENT : out std_logic);
    end component;

    signal clk, iclk: std_logic;
    signal ok: std_logic := '0';
    signal go: std_logic := '0';
    signal recved, sent: std_logic;

    signal fltIn1, fltIn2, fltOut: std_logic_vector(31 downto 0);
    signal fltIn1Buf, fltIn2Buf, fltOutBuf: std_logic_vector(31 downto 0);

    signal recvData: std_logic_vector(7 downto 0);
    signal sendData: std_logic_vector(7 downto 0);

    constant FADD_INST: std_logic_vector(7 downto 0) := x"53";
    --constant HOGE_INST: std_logic_vector(7 downto 0) := x"54";
    signal fetchState: integer range 0 to 8 := 8;
    signal writeState: integer range 0 to 4 := 4;
    signal feedState: integer range 0 to 6 := 6;

    --signal myrx : std_logic;
    --constant myrxrom : std_logic_vector(0 to 31) := ("11111101100101011111110001010101"); -- "\53\54"
    --signal countdown : std_logic_vector(15 downto 0) := x"1B17";
    --signal count : std_logic_vector(4 downto 0) := "00000";
begin
    ib : IBUFG port map (i => MCLK1, o => iclk);
    bg : BUFG port map (i => iclk, o => clk);

    recv : U232C_RECV port map (
        CLK => clk,
        OK => ok,
        RX => RS_RX,
        DATA => recvData,
        RECVED => recved);

    send : U232C_SEND port map (
        CLK => clk,
        GO => go,
        DATA => sendData,
        TX => RS_TX,
        SENT => sent);

    --myrx <= myrxrom(conv_integer(count));
    every_clock_do : process(clk)
    begin
        if (rising_edge(clk)) then
            --if countdown = 0 then
            --    countdown <= x"1B17";
            --    count <= count+1;
            --else
            --    countdown <= countdown-1;
            --end if;

            case feedState is
                when 0 =>
                    fltIn1 <= fltIn1Buf;
                    fltIn2 <= fltIn2Buf;
                    feedState <= feedState+1;
                when 5 =>
                    fltOutBuf <= fltOut;
                    writeState <= 0;
                    feedState <= feedState+1;
                when 6 =>
                when others =>
                    feedState <= feedState+1;
            end case;

            if (recved = '1' and ok = '0') then
                ok <= '1';
            end if;

            if (recved = '0' and ok = '1') then
                ok <= '0';

                case fetchState is
                    when 0 =>
                        fltIn1Buf(31 downto 24) <= recvData;
                        fetchState <= 1;
                    when 1 =>
                        fltIn1Buf(23 downto 16) <= recvData;
                        fetchState <= 2;
                    when 2 =>
                        fltIn1Buf(15 downto  8) <= recvData;
                        fetchState <= 3;
                    when 3 =>
                        fltIn1Buf( 7 downto  0) <= recvData;
                        fetchState <= 4;
                    when 4 =>
                        fltIn2Buf(31 downto 24) <= recvData;
                        fetchState <= 5;
                    when 5 =>
                        fltIn2Buf(23 downto 16) <= recvData;
                        fetchState <= 6;
                    when 6 =>
                        fltIn2Buf(15 downto  8) <= recvData;
                        fetchState <= 7;
                    when 7 =>
                        fltIn2Buf( 7 downto  0) <= recvData;
                        fetchState <= 8;

                        feedState <= 0;

                    when 8 =>
                        case recvData is
                            when FADD_INST =>
                                fetchState <= 0;
                            --when HOGE_INST =>
                            --    fetchState <= 0;
                            when others =>
                        end case;
                end case;
            end if;

            if (sent = '1' and go = '0') then
                case writeState is
                    when 0 =>
                        sendData <= fltOutBuf(31 downto 24);
                        writeState <= 1;
                        go <= '1';
                    when 1 =>
                        sendData <= fltOutBuf(23 downto 16);
                        writeState <= 2;
                        go <= '1';
                    when 2 =>
                        sendData <= fltOutBuf(15 downto  8);
                        writeState <= 3;
                        go <= '1';
                    when 3 =>
                        sendData <= fltOutBuf( 7 downto  0);
                        writeState <= 4;
                        go <= '1';
                    when 4 =>
                end case;
            end if;

            if (sent = '0' and go = '1') then
                go <= '0';
            end if;
        end if;
    end process;

    faddRegister: FloatAdder port map (
        fltIn1 => fltIn1,
        fltIn2 => fltIn2,
        fltOut => fltOut);

end top_body;
