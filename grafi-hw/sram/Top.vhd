library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity Top is
    port (
        MCLK1 : in  std_logic;

        --RS_RX : in  std_logic;
        RS_TX : out std_logic;

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

architecture TopImp of Top is
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

    component Rand128To32 is
        port (
            clk : in std_logic;
            set : in std_logic;
            data : in std_logic_vector(127 downto 0);
            rand : out std_logic_vector(31 downto 0);
            state : buffer std_logic_vector(127 downto 0));
    end component;

    signal clk, iclk : std_logic;
    signal state : integer range 0 to 8 := 8;

    signal set : std_logic := '0';
    signal genData : std_logic_vector(127 downto 0) := x"054913331F123BB5159A55E5075BCD15";
    signal rand : std_logic_vector(31 downto 0);
    signal genState : std_logic_vector(127 downto 0);

    signal go : std_logic := '0';
    signal sent : std_logic;
    signal sendData : std_logic_vector(7 downto 0);

    signal load : std_logic;
    signal store : std_logic;
    signal addr : std_logic_vector (19 downto 0) := (others => '0');
    signal storeData : std_logic_vector(31 downto 0);
    signal loadData  : std_logic_vector(31 downto 0);

    signal load1 : std_logic;
    signal load2 : std_logic;
    signal err : boolean;

begin
    ib : IBUFG port map (i => MCLK1, o => iclk);
    bg : BUFG port map (i => iclk, o => clk);

    gen : Rand128To32 port map (
        clk => clk,
        set => set,
        data => genData,
        rand => rand,
        state => genState);

    send : U232CSend port map (
        clk => clk,
        go => go,
        data => sendData,
        txPin => RS_TX,
        sent => sent);

    ram : SRAM port map (
        clk => clk,
        load => load,
        store => store,
        addr => addr,
        storeData => storeData,
        loadData => loadData,

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

    storeData <= rand;

    -- work
    --storeData <= rand when (state = 7 or state = 6 or state = 5) else x"12345678";

    -- not work
    --storeData <= rand when state = 7 else x"12345678";

    store <= '1' when state = 7 else '0';
    load <= '1' when state = 3 else '0';

    every_clock_do : process(clk)
    begin
        if (rising_edge(clk)) then
            case state is
                when 8 => -- init generator
                    if set = '0' then
                        set <= '1';
                    else
                        set <= '0';
                        state <= 7;
                    end if;

                when 7 => -- store rand
                    addr <= addr + 1;
                    if addr = "11111111111111111111" then
                        state <= 6;
                    end if;

                when 6 => -- nop
                    state <= 5;
                when 5 => -- nop
                    state <= 4;

                when 4 => -- rewind generator
                    if set = '0' then
                        set <= '1';
                    else
                        set <= '0';
                        genData <= genState;
                        err <= false;
                        state <= 3;
                    end if;

                when 3 => -- load rand
                    addr <= addr + 1;
                    if addr = "11111111111111111111" then
                        state <= 2;
                    end if;

                when 2 => -- nop
                    state <= 1;
                when 1 => -- nop
                    state <= 0;

                when 0 => -- output result
                    if sent = '1' and go = '0' then
                        if err then
                            sendData <= x"31";
                        else
                            sendData <= x"30";
                        end if;
                        go <= '1';
                    end if;
                    if sent = '0' and go = '1' then
                        go <= '0';
                        state <= 8;
                    end if;

            end case;

            load1 <= load;
            load2 <= load1;
            if load2 = '1' then
                err <= err or (loadData /= rand);
            end if;
        end if;
    end process;
end TopImp;
