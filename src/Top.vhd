library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use work.types.all;


entity Top is
    port (
        -- Clock
        MCLK1 : in std_logic;
        XRST : in std_logic;

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
    component DCM1
    port(
        CLKIN_IN : in std_logic;
        RST_IN : in std_logic;
        CLKFX_OUT : out std_logic;
        CLKIN_IBUFG_OUT : out std_logic;
        CLK0_OUT : out std_logic);
    end component;

    component U232CRecv is
        generic (
            -- 9600bps
            -- wTime : std_logic_vector(15 downto 0) := x"1B17"
            -- 115200bps, 66MHz (perfectly works)
            -- wTime : std_logic_vector(15 downto 0) := x"0255"
            -- 115200bps, 72MHz
            -- wTime : std_logic_vector(15 downto 0) := x"028b"
            -- 115200bps, 84MHz
            -- wTime : std_logic_vector(15 downto 0) := x"02f7"
            -- 115200bps, 99MHz
            wTime : std_logic_vector(15 downto 0) := x"037f"
        );
        port (
            clk : in std_logic;
            ok : in std_logic;
            rx_pin : in std_logic;
            data : out std_logic_vector (7 downto 0);
            recf : out std_logic);
    end component;

    component U232CSend is
        generic (
            -- 9600bps
            -- wTime : std_logic_vector(15 downto 0) := x"1ADB"
            -- 115200bps, 66MHz (perfectly works)
            -- wTime : std_logic_vector(15 downto 0) := x"0240"
            -- 115200bps, 72MHz
            -- wTime : std_logic_vector(15 downto 0) := x"0274"
            -- 115200bps, 84MHz
            -- wTime : std_logic_vector(15 downto 0) := x"02dd"
            -- 115200bps, 99MHz
            wTime : std_logic_vector(15 downto 0) := x"0360"
        );
        port (
            clk : in std_logic;
            go : in std_logic;
            data : in std_logic_vector (7 downto 0);
            tx_pin : out std_logic;
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
            u232c_in : out u232c_in_t;
            u232c_out : in u232c_out_t;
            sramLoad : out boolean;
            sramAddr : out sram_addr;
            sramData : inout value_t);
    end component;

    signal clkfx, clk0, iclk : std_logic;

    signal u232c_in : u232c_in_t;
    signal u232c_out : u232c_out_t;

    signal load : boolean;
    signal addr : sram_addr := (others => '0');
    signal dataLine : value_t;

begin
    dcm_map : DCM1 port map (
        CLKIN_IN => MCLK1,
        RST_IN => not XRST,
        CLKFX_OUT => clkfx,
        CLKIN_IBUFG_OUT => iclk,
        CLK0_OUT => clk0);

    u232c_recv_map : U232CRecv port map (
        clk => clkfx,
        ok => u232c_in.ok,
        data => u232c_out.recv_data,
        rx_pin => RS_RX,
        recf => u232c_out.recf);

    u232c_send_map : U232CSend port map (
        clk => clkfx,
        go => u232c_in.go,
        data => u232c_in.send_data,
        tx_pin => RS_TX,
        sent => u232c_out.sent);

    sram_map : SRAM port map (
        clk => clkfx,
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
        clk => clkfx,
        u232c_in => u232c_in,
        u232c_out => u232c_out,
        sramLoad => load,
        sramAddr => addr,
        sramData => dataLine);

end structural;
