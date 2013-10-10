library ieee;
use ieee.std_logic_1164.all;

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

-- TODO separate hardware connection and statemachine into diferrent architectures
architecture StateMachine of Top is
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
            load : in std_logic;
            store : in std_logic;
            addr : in std_logic_vector (19 downto 0);
            storeData : in std_logic_vector (31 downto 0);
            loadData : out std_logic_vector (31 downto 0);

            clkPin1 : out std_logic;
            clkPin2 : out std_logic;
            xStorePin : out std_logic;
            xMaskPin : out std_logic_vector (3 downto 0);
            addrPin : out std_logic_vector (19 downto 0);
            dataPin : inout std_logic_vector (31 downto 0);

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

    signal clk, iclk : std_logic;
    signal halt : boolean;

    type state is (Hai, Run, Bye);
    signal state : state;

begin
    ib : IBUFG port map (i => MCLK1, o => iclk);
    bg : BUFG port map (i => iclk, o => clk);

    recv : U232CRecv port map (
        clk => clk,
        ok => ok,
        data => recvData,
        rxPin => RS_RX,
        recved => recved);

    send : U232CSend port map (
        clk => clk,
        go => go,
        data => sendData,
        txPin => RS_TX,
        sent => sent);

    sram : SRAM port map (
        clk => clk,
        load => load,
        store => store,
        addr => addr,
        storeData => storeLine,
        loadData => loadLine,

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

    every_clock_do : process(clk)
    begin
        if (rising_edge(clk)) then
            case state is
                when Hai => -- waiting signal
                    if (recved = '1' and ok = '0') then
                        ok <= '1';
                        with haiState select
                            waitData <= "0x48" when 2,
                                        "0x61" when 1,
                                        "0x69" when others;
                        with haiState select
                            haiState <= 1 when 2,
                                        0 when 1,
                                        2 when 0;
                    end if;

                    if (recved = '0' and ok = '1') then
                        ok <= '0';
                        if waitData /= recvData then
                            haiState <= 2;
                        elsif byeState = 0 then
                            state <= 1;
                            halt <= true;
                        end if;
                    end if;

                when Run => -- CPU running
                    if halt = false then
                        state <= '0';
                    end if;

                when Bye => -- telling bye
                    if sent = '1' and go = '0' then
                        go <= '1';
                        with byeState select
                            sendData <= "0x42" when 2,
                                        "0x79" when 1,
                                        "0x65" when others;
                        with byeState select
                            byeState <= 1 when 2,
                                        0 when 1,
                                        2 when 0;

                    end if;

                    if sent = '0' and go = '1' then
                        go <= '0';
                        if byeState = 0 then
                            state <= 2;
                        end if;
                    end if;
            end case;
        end if;
    end process;
end TopImp;
