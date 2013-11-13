library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

entity TBCommon is
    port (
        clk : buffer std_logic;
        a : out std_logic_vector(31 downto 0);
        b : out std_logic_vector(31 downto 0);
        d : in  std_logic_vector(31 downto 0));
end TBCommon;

architecture FileBench of TBCommon is
    signal delay1, delay2 : boolean := false;

begin
    main : process(clk)
        file testdata_in  : text open read_mode  is "testdata.in";
        file testdata_out : text open write_mode is "testdata.out";
        variable li, lo : line;
        variable at, bt, ct : std_logic_vector(31 downto 0);

    begin
        if rising_edge(clk) then
            if endfile(testdata) then
                delay1 <= false;
            else
                readline(testdata_in, li);
                read(li, at);
                read(li, bt);
                a <= at;
                b <= bt;
                delay1 <= true;
            end if;

            delay2 <= delay1;

            if delay2 then
                ct := c;
                write(lo, ct);
                writeline(testdata_out, lo);
            end if;
    end process;

    clkgen : process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

end FileBench;
