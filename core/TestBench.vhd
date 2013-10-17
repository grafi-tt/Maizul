library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
use work.types.all;

entity TestBench is
end TestBench;

-- TODO move pseudo SRAM controller and U232C controller into separate file

architecture PseudoConnection of TestBench is
    constant CLK_TIME : time := 15 ns;
    signal clk : std_logic;

    constant BLOCK_CYCLE : integer := 1023;
    file stdin : text open read_mode is "testbench.in";
    file stdout : text open write_mode is "testbench.out";
    signal li, lo : line;
    signal recvBuf, sendBuf : std_logic_vector(7 downto 0);
    signal recvCnt, sendCnt : integer := BLOCK_CYCLE;
    signal ok, go : std_logic;
    signal recvData, sendData : std_logic_vector(7 downto 0);
    signal recved, sent : std_logic;

    type ram_t is array(1023 downto 0) of value_t;
    signal pseudoRam : ram_t;
    signal load1, store1 : boolean;
    signal load, store : boolean;
    signal addr : sram_addr := (others => '0');
    signal data : value_t;

begin
    clkGen : process
    begin
        clk <= '0';
        wait for clk / 2;
        clk <= '1';
        wait for clk / 2;
    end process clkGen;

    everyClock : process
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
                    readline(li, stdin);
                    recved <= '1';
                else
                    recvCnt <= recvCnt - 1;
                end if;
            end if;

            if (go = '1') then
                sent <= '0';
                sendBuf <= sendData;
                sendCnt <= BLOCK_CYCLE;
            end if;

            if (sent = '0') then
                if (sendCnt = 0) then
                    hwrite(lo, sendBuf);
                    writeline(lo, stdout);
                    sent <= '1';
                else
                    blkcnt <= blkcnt - 1;
                end if;
            end if;

            assert(not (load and store)) report "store and load is specified same type" severity failure;
            load1 <= load;
            store1 <= store;
            if load1 then
                data <= pseudoRam(integer(addr));
            end if;
            if store1 then
                pseudoRam(integer(addr)) <= data;
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
        sramStore => store,
        sramAddr => addr,
        sramData => data);
end PseudoConnection;
