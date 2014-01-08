library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity Predict is
    port (
        clk : in std_logic;
        d : in predict_in_t;
        q : out predict_out_t);
end Predict;

architecture twoproc of Predict is
    attribute ram_style : string;

    constant gshare_wid : natural := 14;
    type gshare_ram_t is array(0 to (2**gshare_wid)-1) of std_logic_vector(1 downto 0);
    signal gshare_ram : gshare_ram_t := (others => (others => '0'));
    attribute ram_style of gshare_ram : signal is "block";
    signal gshare_we : boolean;
    signal gshare_key, gshare_wkey : unsigned(gshare_wid-1 downto 0) := (others => '0');
    signal gshare_val : std_logic_vector(1 downto 0) := "00";
    signal gshare_wval : std_logic_vector(1 downto 0) := (others => '0');
    constant hist_len : natural := 8;
    signal hist : std_logic_vector(hist_len-1 downto 0) := (others => '0');
    signal hist_wval : std_logic;

    constant stack_wid : natural := 11;
    type stack_ram_t is array(0 to (2**stack_wid)-1) of blkram_addr;
    signal stack_ram : stack_ram_t := (others => (others => '0'));
    attribute ram_style of stack_ram : signal is "block";
    signal stack_top : unsigned(stack_wid-1 downto 0) := (others => '0');
    signal stack_pred : unsigned(stack_wid-1 downto 0);
    signal stack_push, stack_pop : boolean := false;
    signal stack_addr : blkram_addr := (others => '0');
    signal stack_waddr : blkram_addr := (others => '0');

    signal we : boolean := false;
    signal addr : blkram_addr;
    signal cont : std_logic_vector(2 downto 0);

    constant buf_len : natural := 2;
    type buf_t is array(buf_len-1 downto 0) of blkram_addr;
    signal buf : buf_t := (others => (others => '0'));
    type cont_buf_t is array(buf_len-1 downto 0) of std_logic_vector(2 downto 0);
    signal cont_buf : cont_buf_t := (others => (others => '0'));
    type key_buf_t is array(buf_len-1 downto 0) of unsigned(gshare_wid-1 downto 0);
    signal key_buf : key_buf_t := (others => (others => '0'));

begin
    sequential : process(clk)
    begin
        if rising_edge(clk) then
            gshare_val <= gshare_ram(to_integer(gshare_key));
            stack_addr <= stack_ram(to_integer(stack_pred));

            if we then
                buf <= addr & buf(buf_len-1 downto 1);
                key_buf <= gshare_key & key_buf(buf_len-1 downto 1);
                cont_buf <= cont & cont_buf(buf_len-1 downto 1);
            end if;

            if gshare_we then
                hist <= hist_wval & hist(hist_len-1 downto 1);
                gshare_ram(to_integer(gshare_wkey)) <= gshare_wval;
            end if;

            if stack_push then
                stack_ram(to_integer(stack_top)) <= stack_waddr;
                stack_top <= stack_top + 1;
            end if;

            if stack_pop then
                stack_top <= stack_top - 1;
            end if;
        end if;
    end process;

    predict : process(d, addr, gshare_val, stack_addr, stack_top)
        variable imm_addr : blkram_addr;
        variable upper : std_logic_vector(hist_len-1 downto 0);
        variable lower : std_logic_vector(gshare_wid-hist_len-1 downto 0);
        variable comb : std_logic_vector(gshare_wid-1 downto 0);

    begin
        imm_addr := blkram_addr(d.inst(15 downto 0));
        cont <= "100";

        if d.inst(31) = '1' then
            case d.inst(30 downto 29) is
                when "00" | "01" => -- gshare (TODO: use 01 for loop prediction?)
                    cont <= '0' & gshare_val;
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
                    cont <= "101";
                    addr <= imm_addr;
                when "10" => -- ret
                    cont <= "110";
                    addr <= stack_addr;
                when "11" => -- not jump
                    addr <= d.pc;
                when others => null;
            end case;

        else
            addr <= d.pc;
        end if;

        upper := std_logic_vector(addr(gshare_wid-1 downto gshare_wid-hist_len));
        lower := std_logic_vector(addr(gshare_wid-hist_len-1 downto 0));
        comb := (upper xor hist) & lower;
        gshare_key <= unsigned(comb);
        stack_pred <= stack_top - 1;
    end process;

    confirm : process(d, buf, cont_buf, key_buf, addr)
        variable cont_head : std_logic_vector(2 downto 0);
        variable succeed : boolean;

    begin
        -- return
        q.succeed <= buf(0) = d.target;

        -- write back
        cont_head := cont_buf(0);
        succeed := buf(0) = d.target or d.enable_target;

        if succeed then
            case cont_head(1 downto 0) is
                when "00" =>
                    gshare_wval <= "10";
                when "01" =>
                    gshare_wval <= "11";
                when "10" =>
                    gshare_wval <= "10";
                when "11" =>
                    gshare_wval <= "11";
                when others => assert false;
            end case;
        else
            case cont_head(1 downto 0) is
                when "00" =>
                    gshare_wval <= "01";
                when "01" =>
                    gshare_wval <= "00";
                when "10" =>
                    gshare_wval <= "00";
                when "11" =>
                    gshare_wval <= "01";
                when others => assert false;
            end case;
        end if;

        if succeed then
            hist_wval <= '1';
            q.addr <= addr;
        else
            hist_wval <= '0';
            q.addr <= d.target;
        end if;

        we <= d.enable_fetch;
        gshare_we <= d.enable_target and cont_head(2) = '0';
        stack_push <= d.enable_target and cont_head = "101";
        stack_pop <= d.enable_target and cont_head = "110";
        stack_waddr <= buf(0);
        gshare_wkey <= key_buf(0);
    end process;

end twoproc;
