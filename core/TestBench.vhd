library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
use work.types.all;

entity TestBench is
end TestBench;

-- TODO move pseudo SRAM controller and U232C controller into separate file

architecture PseudoConnection of TestBench is
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

    constant CLK_TIME : time := 15 ns;
    signal clk : std_logic;

    constant BLOCK_CYCLE : integer := 31;
    signal recvCnt, sendCnt : integer := BLOCK_CYCLE;

    constant PSEUDORAM_WIDTH : natural := 10;
    constant PSEUDORAM_LENGTH : natural := 1024;

    signal ok, go : std_logic;
    signal recvData, sendData : std_logic_vector(7 downto 0) := (others => '0');
    signal recved : std_logic := '0';
    signal sent : std_logic := '1';

    type ram_t is array(0 to PSEUDORAM_LENGTH-1) of value_t;
    signal pseudoRam : ram_t := (others => (others => '0'));
    signal load : boolean;
    signal load1, load2 : boolean := true;
    signal addr : sram_addr;
    signal addr1, addr2 : sram_addr := (others => '0');
    signal data : value_t := (others => '0');

    signal forwardBuf : value_t := (others => '0');

begin
    clkGen : process
    begin
        clk <= '0';
        wait for CLK_TIME / 2;
        clk <= '1';
        wait for CLK_TIME / 2;
    end process;

    everyClock : process(clk)
        file stdin : text open read_mode is "testbench.in";
        file stdout : text open write_mode is "testbench.out";
        variable li, lo : line;
        variable recvBuf, sendBuf : std_logic_vector(7 downto 0) := (others => '0');

    begin
        if rising_edge(clk) then
            if (ok = '1') then
                recved <= '0';
                recvData <= recvBuf;
                recvCnt <= BLOCK_CYCLE;
            end if;

            if (recved = '0') then
                if (recvCnt = 0) then
                    hread(li, recvBuf);
                    readline(stdin, li);
                    recved <= '1';
                else
                    recvCnt <= recvCnt - 1;
                end if;
            end if;

            if (go = '1') then
                sent <= '0';
                sendBuf := sendData;
                sendCnt <= BLOCK_CYCLE;
            end if;

            if (sent = '0') then
                if (sendCnt = 0) then
                    hwrite(lo, sendBuf);
                    writeline(stdout, lo);
                    sent <= '1';
                else
                    sendCnt <= sendCnt - 1;
                end if;
            end if;

            -- phase 1
            load1 <= load;
            addr1 <= addr;

            -- phase 2
            addr2 <= addr1;
            load2 <= load1;
            if load1 then
                if not (addr1 = addr2 and (not load2)) then
                    data <= pseudoRam(to_integer(unsigned(addr1(PSEUDORAM_WIDTH-1 downto 0))));
                end if;
            else
                data <= (others => 'Z');
            end if;

            -- phase 3
            if not load2 then
                pseudoRam(to_integer(unsigned(addr2(PSEUDORAM_WIDTH-1 downto 0)))) <= data;
            end if;
        end if;
    end process;

    data_path_map : DataPath port map (
        clk => clk,
        serialOk => ok,
        serialGo => go,
        serialRecvData => recvData,
        serialSendData => sendData,
        serialRecved => recved,
        serialSent => sent,
        sramLoad => load,
        sramAddr => addr,
        sramData => data);
end PseudoConnection;
