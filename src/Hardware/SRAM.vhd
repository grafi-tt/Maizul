library ieee;
use ieee.std_logic_1164.all;

entity SRAM is
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
end SRAM;

architecture structural of SRAM is
begin
    clkPin1 <= clk;
    clkPin2 <= clk;
    addrPin <= addr;
    xStorePin <= '1' when load else '0';
    xMaskPin <= "0000";
    dataPin <= data;
    xEnablePin1 <= '0';
    enablePin2 <= '1';
    xEnablePin3 <= '0';
    xOutEnablePin <= '0';
    xClkEnablePin <= '0';
    advancePin <= '0';
    xLinearOrderPin <= '1';
    sleepPin <= '0';
    xFlowThruPin <= '1';

end structural;
