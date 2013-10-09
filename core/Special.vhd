library ieee;
use ieee.std_logic_1164.all;

library cpuex;
use cpuex.types.all;

entity Special is
    port (
        clk : in std_logic;

        serialOk : out std_logic;
        serialGo : out std_logic;
        serialRecvData : in std_logic_vector(7 downto 0);
        serialSendData : out std_logic_vector(7 downto 0));
begin
end Special;
