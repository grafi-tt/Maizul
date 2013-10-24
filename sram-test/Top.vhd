library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity Top is
    port (
        -- Clock
        MCLK1 : in std_logic;

        -- RS-232C
        RS_RX : in  std_logic;
        RS_TX : out std_logic;

        -- SRAM
        ZCLKMA : out std_logic_vector(1 downto 0);
        ZD : inout std_logic_vector(31 downto 0);
        ZA : out std_logic_vector(19 downto 0);
        XWA : out std_logic;
        XE1 : out std_logic;
        E2A : out std_logic;
        XE3 : out std_logic;
        XGA : out std_logic;
        XZCKE : out std_logic;
        ADVA : out std_logic;
        XLBO : out std_logic;
        ZZA : out std_logic;
        XFT : out std_logic;
        XZBE : out std_logic_vector(3 downto 0));
end Top;

architecture test of Top is
    component U232CSend is
        generic (
            -- 9600bps
            --WTIME : std_logic_vector(15 downto 0) := x"1ADB");
            -- 115200bps
            wTime : std_logic_vector(15 downto 0) := x"0240");
        port (
            clk : in std_logic;
            go : in std_logic;
            data : in std_logic_vector (7 downto 0);
            txPin : out std_logic;
            sent : out std_logic);
    end component;

    signal clk, iclk : std_logic;
    type state_t is (Running, Sending, Finished);
    signal state : state_t := Running;
    signal counter : unsigned(31 downto 0) := (others => '0');

    signal sramLoad : boolean := true;
    signal sramAddr : std_logic_vector(19 downto 0) := (others => '0');
    signal sramData : std_logic_vector(31 downto 0) := (others => 'Z');

    signal emitLoad : boolean := true;
    signal emitAddr : std_logic_vector(19 downto 0) := (others => '0');
    signal emitData : std_logic_vector(31 downto 0) := (others => '0');
    signal drainData : std_logic_vector(31 downto 0) := (others => '0');
    signal load0, load1, load2, load3, load4 : boolean := true;
    signal data0, data1, data2, data3, data4 : std_logic_vector(31 downto 0) := (others => '0');
    signal stat0, stat1, stat2, stat3, stat4 : boolean := false;

    -- attribute IOB : string;
    -- attribute IOB of emitLoad : signal is "TRUE";
    -- attribute IOB of emitAddr : signal is "TRUE";
    -- attribute IOB of emitData : signal is "TRUE";
    -- attribute IOB of drainData : signal is "TRUE";
    -- attribute EQUIVALENT_REGISTER_REMOVAL : string;
    -- attribute EQUIVALENT_REGISTER_REMOVAL of emitLoad : signal is "NO";
    -- attribute EQUIVALENT_REGISTER_REMOVAL of load0 : signal is "NO";

    constant DataNum : natural := 8;
    type data_set_t is array (DataNum-1 downto 0) of std_logic_vector(31 downto 0);
    signal dataSet : data_set_t := (others => (others => '0'));

    signal sendCnt : integer := 0;
    signal sendBuf : std_logic_vector(31 downto 0) := (others => '0');
    signal byteState : integer range 3 downto 0 := 3;
    signal sendByte : std_logic_vector(7 downto 0);
    signal byteGo : std_logic := '0';
    signal byteSent : std_logic := '1';

begin
    ib : IBUFG port map (i => MCLK1, o => iclk);
    bg : BUFG port map (i => iclk, o => clk);

    ZCLKMA(0) <= clk;
    ZCLKMA(1) <= clk;
    XWA <= '1' when sramLoad else '0';
    ZA <= sramAddr;
    ZD <= sramData;

    XZBE <= "0000";
    XE1 <= '0';
    E2A <= '1';
    XE3 <= '0';
    XGA <= '0';
    XZCKE <= '0';
    ADVA <= '0';
    XLBO <= '1';
    ZZA <= '0';
    XFT <= '1';

    u232c_send_map : U232CSend port map (
        clk => clk,
        go => byteGo,
        data => sendByte,
        txPin => RS_TX,
        sent => byteSent);

    every_clock_do : process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when Running =>
                    -- phase 0
                    if stat0 or stat1 or stat2 or stat3 or stat4 then
                        load0 <= true;
                        data0 <= (others => '0');
                        stat0 <= false;
                        emitLoad <= true;
                        emitAddr <= (others => '0');
                    else
                        load0 <= counter(3) = '1';
                        data0 <= std_logic_vector(counter);
                        stat0 <= true;
                        emitLoad <= counter(3) = '1';
                        emitAddr <= "00000000000000000" & std_logic_vector(counter(2 downto 0));
                    end if;

                    -- phase 1
                    load1 <= load0;
                    data1 <= data0;
                    stat1 <= stat0;
                    sramLoad <= emitLoad;
                    sramAddr <= emitAddr;

                    -- phase 2
                    load2 <= load1;
                    emitData <= data1;
                    stat2 <= stat1;

                    -- phase 3
                    load3 <= load2;
                    stat3 <= stat2;
                    if load2 then
                        sramData <= (others => 'Z');
                    --    data3 <= sramData;
                    else
                        sramData <= emitData;
                    end if;

                    -- phase 4
                    load4 <= load3;
                    -- data4 <= data3;
                    stat4 <= stat3;
                    if load3 then
                        drainData <= sramData;
                    end if;

                    -- phase 5
                    if stat4 then
                        if counter = x"0000000F" then
                            state <= Sending;
                        else
                            counter <= counter + x"00000001";
                        end if;
                        if load4 then
                            dataSet(to_integer(counter(2 downto 0))) <= drainData;
                        end if;
                    end if;

                when Sending =>
                    if byteSent = '1' and byteGo = '0' then
                        if byteState = 3 then
                            if sendCnt = DataNum then
                                state <= Finished;
                            else
                                sendCnt <= sendCnt + 1;
                                sendBuf <= dataSet(sendCnt);
                                byteGo <= '1';
                            end if;
                        else
                            byteGo <= '1';
                        end if;
                    end if;

                    if byteSent = '0' and byteGo = '1' then
                        byteGo <= '0';
                        sendBuf <= sendBuf(23 downto 0) & x"00";
                        if byteState = 0 then
                            byteState <= 3;
                        else
                            byteState <= byteState - 1;
                        end if;
                    end if;

                when Finished =>
                    null;
            end case;
        end if;
    end process;

    sendByte <= sendBuf(31 downto 24);

end test;
