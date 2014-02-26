library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use work.types.all;


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

architecture structural of Top is
    component U232CRecv is
        generic (
            -- 9600bps
            --WTIME : std_logic_vector(15 downto 0) := x"1B17");
            -- 115200bps
            wTime : std_logic_vector(15 downto 0) := x"0255");
        port (
            clk : in std_logic;
            ok : in std_logic;
            rxPin : in std_logic;
            data : out std_logic_vector (7 downto 0);
            recved : out std_logic);
    end component;

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

    component SRAM is
        port (
            clk : in std_logic;
            load : in boolean;
            addr : in std_logic_vector(19 downto 0);
            data : inout std_logic_vector(31 downto 0);

            clkPin1 : out std_logic;
            clkPin2 : out std_logic;
            xStorePin : out std_logic;
            xMaskPin : out std_logic_vector(3 downto 0);
            addrPin : out std_logic_vector(19 downto 0);
            dataPin : inout std_logic_vector(31 downto 0);

            xEnablePin1 : out std_logic;
            enablePin2 : out std_logic;
            xEnablePin3 : out std_logic;
            xOutEnablePin : out std_logic;
            xClkEnablePin : out std_logic;
            advancePin : out std_logic;
            xLinearOrderPin : out std_logic;
            sleepPin : out std_logic;
            xFlowThruPin : out std_logic);
    end component;

    component DataPath is
        port (
            clk : in std_logic;
            serialOk : out std_logic;
            serialGo : out std_logic;
            serialRecvData : in std_logic_vector(7 downto 0);
            serialSendData : out std_logic_vector(7 downto 0);
            serialRecved : in std_logic;
            serialSent : in std_logic;
            sramLoad : out boolean;
            sramAddr : out sram_addr;
            sramData : inout value_t);
    end component;

    signal clk, clkio, iclk : std_logic;

    signal ok, go : std_logic;
    signal recved, sent : std_logic;
    signal recvData : std_logic_vector(7 downto 0);
    signal sendData : std_logic_vector(7 downto 0);

    signal load : boolean;
    signal addr : sram_addr := (others => '0');
    signal dataLine : value_t;

begin
    ib : IBUFG port map (i => MCLK1, o => iclk);
    bg : BUFG port map (i => iclk, o => clk);
    bg2 : BUFG port map (i => iclk, o => clkio);

    u232c_recv_map : U232CRecv port map (
        clk => clk,
        ok => ok,
        data => recvData,
        rxPin => RS_RX,
        recved => recved);

    u232c_send_map : U232CSend port map (
        clk => clk,
        go => go,
        data => sendData,
        txPin => RS_TX,
        sent => sent);

    sram_map : SRAM port map (
        clk => clkio,
        load => load,
        addr => std_logic_vector(addr),
        data => dataLine,

        clkPin1 => ZCLKMA(0),
        clkPin2 => ZCLKMA(1),
        xStorePin => XWA,
        xMaskPin => XZBE,
        addrPin => ZA,
        dataPin => ZD,
        xEnablePin1 => XE1,
        enablePin2 => E2A,
        xEnablePin3 => XE3,
        xOutEnablePin => XGA,
        xClkEnablePin => XZCKE,
        advancePin => ADVA,
        xLinearOrderPin => XLBO,
        sleepPin => ZZA,
        xFlowThruPin => XFT);

    data_path_map : DataPath port map (
        clk => clkio,
        serialOk => ok,
        serialGo => go,
        serialRecvData => recvData,
        serialSendData => sendData,
        serialRecved => recved,
        serialSent => sent,
        sramLoad => load,
        sramAddr => addr,
        sramData => dataLine);

end structural;