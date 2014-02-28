library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity IO is
    port (
        clk : in std_logic;
        enable : in boolean;
        code : in std_logic_vector(2 downto 0);
        getTag : in tag_t;
        putVal : in value_t;
        emitTag : out tag_t := "00000";
        emitVal : out value_t := (others => '0');
        u232c_in : out u232c_in_t := ((others => '0'), '0', '0');
        u232c_out : in u232c_out_t;
        emitInstWE : out boolean := false;
        emitInst : out instruction_t := (others => '0');
        emitInstPtr : out blkram_addr := (others => '0'));
end IO;

architecture twoproc of IO is
    subtype cnt_t is unsigned(1 downto 0);
    type buf_t is array(3 downto 0) of std_logic_vector(7 downto 0);

    signal recv_cnt, send_cnt : cnt_t := "00";
    signal recv_buf, send_buf : buf_t := (others => (others => '0'));
    signal inst_ptr_lat : blkram_addr := (others => '0');

    signal code_i : std_logic_vector(2 downto 0) := "000";
    signal enable_i : boolean := false;
    signal getTag_i : tag_t := "00000";
    signal putVal_i : value_t := (others => '0');

    signal recv_cnt_i, send_cnt_i : cnt_t := "00";
    signal recv_buf_i, send_buf_i : buf_t := (others => x"00");
    signal ok, go, recf_i, sent_i, ok_i, go_i : std_logic := '0';

begin
    u232c_in.send_data <= send_buf(to_integer(send_cnt));
    recv_buf(0) <= u232c_out.recv_data;
    u232c_in.ok <= ok;
    u232c_in.go <= go;

    sequential : process(clk)
    begin
        if rising_edge(clk) then
            code_i <= code;
            enable_i <= enable;
            getTag_i <= getTag;
            putVal_i <= putVal;

            recv_cnt_i <= recv_cnt;
            send_cnt_i <= send_cnt;
            recv_buf_i <= recv_buf;
            send_buf_i <= send_buf;

            recf_i <= u232c_out.recf;
            sent_i <= u232c_out.sent;
            ok_i <= ok;
            go_i <= go;

            emitInstWE <= enable and code = "101";
            emitInst <= instruction_t(putVal);
            case code is
                when "100" =>
                    inst_ptr_lat <= blkram_addr(putVal(15 downto 0));
                when "101" =>
                    inst_ptr_lat <= inst_ptr_lat + 1;
                when others => null;
            end case;
        end if;
    end process;
    emitInstPtr <= blkram_addr(inst_ptr_lat);

    combinatorial : process(enable_i, code_i, getTag_i, putVal_i,
                            recv_cnt_i, send_cnt_i, recv_buf_i, send_buf_i,
                            recf_i, sent_i, ok_i, go_i, inst_ptr_lat)
        variable recv_cnt_v, send_cnt_v : cnt_t;

    begin
        send_cnt_v := recv_cnt_i;
        recv_cnt_v := send_cnt_i;

        if enable_i then
            case code_i is
                when "000" | "010" | "110" | "111" =>
                    emitTag <= getTag_i;
                when others =>
                    emitTag <= "00000";
            end case;

            case code_i is
                when "010" =>
                    emitVal <= x"000000" & recv_buf_i(to_integer(recv_cnt_v));
                when "110" =>
                    emitVal <= value_t(x"0000000" & "00" & recv_cnt_v);
                when "111" =>
                    emitVal <= x"0000000" & "00" & std_logic_vector(send_cnt_v);
                when others =>
                    emitVal <= recv_buf_i(3) & recv_buf_i(2) & recv_buf_i(1) & recv_buf_i(0);
            end case;

            case code_i is
                when "000" =>
                    recv_cnt_v := "00";
                when "001" =>
                    send_cnt_v := "00";
                    send_buf(3) <= putVal_i(31 downto 24);
                    send_buf(2) <= putVal_i(23 downto 16);
                    send_buf(1) <= putVal_i(15 downto  8);
                    send_buf(0) <= putVal_i( 7 downto  0);
                when "010" =>
                    if recv_cnt_v /= 0 then
                        recv_cnt_v := recv_cnt_v - 1;
                    end if;
                when "011" =>
                    send_buf(3 downto 1) <= send_buf_i(2 downto 0);
                    send_buf(0) <= putVal_i(7 downto 0);
                    if send_cnt_v /= 3 then
                        send_cnt_v := send_cnt_v + 1;
                    end if;
                when others =>
                    null;
            end case;
        else
            emitTag <= "00000";
            emitVal <= recv_buf_i(3) & recv_buf_i(2) & recv_buf_i(1) & recv_buf_i(0);
        end if;


        if recf_i = '1' and ok_i = '0' then
            ok <= '1';
            if recv_cnt_v /= 3 then
                recv_cnt_v := recv_cnt_v + 1;
                recv_buf(3 downto 1) <= recv_buf_i(2 downto 0);
            end if;
        end if;

        if recf_i = '0' and ok_i = '1' then
            ok <= '0';
        end if;

        if sent_i = '1' and go_i = '0' then
            if send_cnt_v /= 0 then
                go <= '1';
                send_cnt_v := send_cnt_v - 1;
            end if;
        end if;

        if sent_i = '0' and go_i = '1' then
            go <= '0';
        end if;

        recv_cnt <= recv_cnt_v;
        send_cnt <= send_cnt_v;
    end process;

end twoproc;
