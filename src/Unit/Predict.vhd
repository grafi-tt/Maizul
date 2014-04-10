library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

-- prediction counter
-- 10 00 <-fail-|-success-> 01  11

entity Predict is
    port (
        clk : in std_logic;
        d : in predict_in_t;
        q : out predict_out_t);
end Predict;

architecture twoproc of Predict is
    attribute ram_style : string;

    constant gshare_wid : natural := 9;
    type gshare_ram_t is array(0 to (2**gshare_wid)-1) of std_logic_vector(1 downto 0);
    signal gshare_ram : gshare_ram_t := (others => (others => '0'));
    attribute ram_style of gshare_ram : signal is "distributed";

    signal gshare_we : boolean;
    signal gshare_wkey : std_logic_vector(gshare_wid-1 downto 0) := (others => '0');
    signal gshare_wval : std_logic_vector(1 downto 0) := "00";
    type cont_t is record
        gshared : boolean;
        gshared_key : std_logic_vector(gshare_wid-1 downto 0);
        gshared_val : std_logic_vector(1 downto 0);
    end record;
    signal cont : cont_t;

    constant hist_len : natural := 4;
    signal hist : std_logic_vector(hist_len-1 downto 0) := (others => '0');
    signal hist_wval : std_logic;

    constant stack_wid : natural := 6;
    type stack_ram_t is array(0 to (2**stack_wid)-1) of blkram_addr;
    signal stack_ram : stack_ram_t := (others => (others => '0'));
    attribute ram_style of stack_ram : signal is "distributed";

    signal stack_top, stack_top_next, stack_top_back : unsigned(stack_wid-1 downto 0) := (others => '0');
    signal stack_topp, stack_topp_next, stack_topp_back : unsigned(stack_wid-1 downto 0) := (others => '1');
    signal stack_push : boolean := false;

    constant buf_len : natural := 2;
    type buf_t      is array(buf_len-1 downto 0) of blkram_addr;
    type cont_buf_t is array(buf_len-1 downto 0) of cont_t;
    signal buf      : buf_t      := (others => (others => '0'));
    signal cont_buf : cont_buf_t := (others => (false, (others => '0'), "00"));

    signal addr : blkram_addr;
    signal imm_addr : blkram_addr;
    signal stack_addr : blkram_addr;

begin
    imm_addr <= blkram_addr(d.inst(15 downto 0));
    stack_addr <= stack_ram(to_integer(stack_topp));
    q.addr <= addr;

    sequential : process(clk)
    begin
        if rising_edge(clk) then
            if d.enable_fetch then
                buf <= addr & buf(buf_len-1 downto 1);
                cont_buf <= cont & cont_buf(buf_len-1 downto 1);
                stack_top <= stack_top_next;
                stack_topp <= stack_topp_next;
                stack_top_back <= stack_top;
                stack_topp_back <= stack_topp;

                if gshare_we then
                    hist <= hist_wval & hist(hist_len-1 downto 1);
                    gshare_ram(to_integer(unsigned(gshare_wkey))) <= gshare_wval;
                end if;

                if stack_push then
                    stack_ram(to_integer(stack_top)) <= d.pc;
                end if;

            end if;
        end if;
    end process;

    combinatorial : process(d, imm_addr, stack_addr, gshare_ram, stack_top, stack_topp, buf(0), cont_buf(0), stack_top_back, stack_topp_back)
        variable upper : std_logic_vector(hist_len-1 downto 0);
        variable lower : std_logic_vector(gshare_wid-hist_len-1 downto 0);
        variable gshare : boolean;
        variable gshare_key : std_logic_vector(gshare_wid-1 downto 0);
        variable gshare_val : std_logic_vector(1 downto 0);

        variable cont_head : cont_t;
        variable succeed : boolean;

        variable stack_top_next_v, stack_topp_next_v : unsigned(stack_wid-1 downto 0);
        variable stack_push_v : boolean;

    begin
        succeed := buf(0) = d.target or not d.enable_target;
        q.succeed <= succeed;

        upper := std_logic_vector(imm_addr(gshare_wid-1 downto gshare_wid-hist_len));
        lower := std_logic_vector(imm_addr(gshare_wid-hist_len-1 downto 0));
        gshare_key := (upper xor hist) & lower;
        gshare_val := gshare_ram(to_integer(unsigned(gshare_key)));

        gshare := false;
        stack_top_next_v := stack_top;
        stack_topp_next_v := stack_topp;
        stack_push_v := false;

        if succeed then
            if d.inst(31) = '1' then
                case d.inst(30 downto 29) is
                    when "00" | "01" => -- gshare (TODO: use 01 for loop prediction?)
                        gshare := true;
                        if gshare_val(0) = '0' then
                            addr <= d.pc;
                        else
                            addr <= imm_addr;
                        end if;
                    when "10" => -- static no jump
                        addr <= d.pc;
                    when "11" => -- static jump
                        addr <= imm_addr;
                    when others => null;
                end case;

            elsif d.inst(30 downto 28) = "101" then
                case d.inst(27 downto 26) is
                    when "00" => -- imm jump
                        addr <= imm_addr;
                    when "01" => -- call
                        addr <= imm_addr;
                        stack_push_v := true;
                        stack_top_next_v := stack_top + 1;
                        stack_topp_next_v := stack_topp + 1;
                    when "10" => -- ret
                        addr <= stack_addr;
                        stack_top_next_v := stack_top - 1;
                        stack_topp_next_v := stack_topp - 1;
                    when "11" => -- not jump
                        addr <= d.pc;
                    when others => null;
                end case;

            else
                addr <= d.pc;
            end if;

        else
            stack_top_next_v := stack_top_back;
            stack_topp_next_v := stack_topp_back;
            addr <= d.target;
        end if;

        stack_top_next <= stack_top_next_v;
        stack_topp_next <= stack_topp_next_v;
        stack_push <= stack_push_v;

        cont <= (gshared => gshare, gshared_key => gshare_key, gshared_val => gshare_val);

        cont_head := cont_buf(0);
        if succeed then
            case cont_head.gshared_val is
                when "10" =>
                    gshare_wval <= "10";
                    hist_wval <= '0';
                when "00" =>
                    gshare_wval <= "10";
                    hist_wval <= '0';
                when "01" =>
                    gshare_wval <= "11";
                    hist_wval <= '1';
                when "11" =>
                    gshare_wval <= "11";
                    hist_wval <= '1';
                when others => assert false;
            end case;
        else
            case cont_head.gshared_val is
                when "10" =>
                    gshare_wval <= "00";
                    hist_wval <= '1';
                when "00" =>
                    gshare_wval <= "01";
                    hist_wval <= '1';
                when "01" =>
                    gshare_wval <= "00";
                    hist_wval <= '0';
                when "11" =>
                    gshare_wval <= "01";
                    hist_wval <= '0';
                when others => assert false;
            end case;
        end if;

        gshare_we <= d.enable_target and cont_head.gshared;
        gshare_wkey <= cont_head.gshared_key;
    end process;

end twoproc;
