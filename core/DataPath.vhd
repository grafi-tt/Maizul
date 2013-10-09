library ieee;
use ieee.std_logic_1164.all;

library cpuex;
use cpuex.types.all;

entity DataPath is
    port (
        clk : in std_logic;

        sramLoad : out std_logic;
        sramStore : out std_logic;

        serialOk : out std_logic;
        serialGo : out std_logic;
        serialRecvData : in std_logic_vector(7 downto 0);
        serialSendData : out std_logic_vector(7 downto 0));
end DataPath;

architecture DataPathImp of DataPath is
    component ALU is
        port (
            enable : in std_logic;
            code : in std_logic_vector(3 downto 0);

            opS : in value;
            opT : in value;

            outLine : out value);
    end component;

    component Mem is
        port (
            clk : in std_logic;

            enable : in std_logic;
            code : in std_logic_vector(2 downto 0);

            base : in value;
            disp : in std_logic(15 downto 0);

            loadLine : in value;
            storeLine : out value);
    end component;

begin
end DataPathImp;
