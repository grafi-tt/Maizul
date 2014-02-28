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

architecture mock_testbench of TestBench is
    component DataPath is
        port (
            clk : in std_logic;
            u232c_in : out u232c_in_t;
            u232c_out : in u232c_out_t;
            sramLoad : out boolean;
            sramAddr : out sram_addr;
            sramData : inout value_t);
    end component;

    constant CLK_TIME : time := 15 ns;
    signal clk : std_logic;

    constant BLOCK_CYCLE : integer := 31;
    signal recvCnt, sendCnt : integer := BLOCK_CYCLE;

    constant PSEUDORAM_WIDTH : natural := 20;
    constant PSEUDORAM_LENGTH : natural := 1048576;

    signal u232c_in : u232c_in_t := ((others => '0'), '0', '0');
    signal u232c_out : u232c_out_t := ((others => '0'), '0', '1');

    type ram_t is array(0 to PSEUDORAM_LENGTH-1) of integer;
    signal pseudoRam : ram_t := (others => 0);
    signal load : boolean;
    signal load1, load2 : boolean := true;
    signal addr : sram_addr;
    signal addr1, addr2 : sram_addr := (others => '0');
    signal data : value_t := (others => '0');

    signal forwardBuf : value_t := (others => '0');

begin
    clkgen : process
    begin
        clk <= '0';
        wait for CLK_TIME / 2;
        clk <= '1';
        wait for CLK_TIME / 2;
    end process;

    mock : process(clk, u232c_in.ok)
        file stdin : text open read_mode is "testbench.in";
        file stdout : text open write_mode is "testbench.out";
        variable li, lo : line;
        variable recvBuf, sendBuf : std_logic_vector(7 downto 0) := (others => '0');

    begin
        if rising_edge(u232c_in.ok) then
            u232c_out.recf <= '0';
            u232c_out.recv_data <= recvBuf;
            recvCnt <= BLOCK_CYCLE;
        end if;

        if rising_edge(clk) then
            if u232c_out.recf = '0' then
                if recvCnt = 0 then
                    readline(stdin, li);
                    hread(li, recvBuf);
                    u232c_out.recf <= '1';
                else
                    recvCnt <= recvCnt - 1;
                end if;
            end if;

            if u232c_in.go = '1' then
                u232c_out.sent <= '0';
                sendBuf := u232c_in.send_data;
                sendCnt <= BLOCK_CYCLE;
            end if;

            if u232c_out.sent = '0' then
                if sendCnt = 0 then
                    hwrite(lo, sendBuf);
                    writeline(stdout, lo);
                    u232c_out.sent <= '1';
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
                    data <= std_logic_vector(to_signed(pseudoRam(to_integer(unsigned(addr1(PSEUDORAM_WIDTH-1 downto 0)))),32));
                else
                    data <= data;
                end if;
            else
                data <= (others => 'Z');
            end if;

            -- phase 3
            if not load2 then
                pseudoRam(to_integer(unsigned(addr2(PSEUDORAM_WIDTH-1 downto 0)))) <= to_integer(signed(data));
            end if;
        end if;
    end process;

    data_path_map : DataPath port map (
        clk => clk,
        u232c_in => u232c_in,
        u232c_out => u232c_out,
        sramLoad => load,
        sramAddr => addr,
        sramData => data);
end mock_testbench;
