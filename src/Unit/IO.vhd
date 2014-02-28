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
        blocking : out boolean := false; -- workaround for compatibability
        emitTag : out tag_t := "00000";
        emitVal : out value_t := (others => '0');
        u232c_in : out u232c_in_t := ((others => '0'), '0', '0');
        u232c_out : in u232c_out_t;
        emit_instw : out blkram_write_t := (false, (others => '0'), (others => '0')));
end IO;

architecture behavioral of IO is
    subtype cnt_t is unsigned(1 downto 0);
    type buf_t is array(3 downto 0) of std_logic_vector(7 downto 0);

    signal recv_cnt, send_cnt : cnt_t := "00";
    signal recv_buf, send_buf : buf_t := (others => (others => '0'));
    signal inst_ptr_lat : blkram_addr := (others => '0');

    signal code_i : std_logic_vector(2 downto 0) := "000";
    signal enable_i : boolean := false;
    signal getTag_i : tag_t := "00000";
    signal putVal_i : value_t := (others => '0');

    signal ok, go : std_logic := '0';

    signal blocking_i : boolean := false;

begin
    u232c_in.ok <= ok;
    u232c_in.go <= go;

    blocking <= blocking_i;
    sequential : process(clk)
        variable code_v : std_logic_vector(2 downto 0);
        variable enable_v : boolean;
        variable getTag_v : tag_t;
        variable putVal_v : value_t;

        variable recv_cnt_v, send_cnt_v : cnt_t;
        variable blocking_v : boolean;

    begin
        if rising_edge(clk) then
            emit_instw.enable <= enable and code = "101";
            emit_instw.addr <= inst_ptr_lat;
            emit_instw.inst <= instruction_t(putVal);
            if enable then
                case code is
                    when "100" =>
                        inst_ptr_lat <= blkram_addr(putVal(15 downto 0));
                    when "101" =>
                        inst_ptr_lat <= inst_ptr_lat + 1;
                    when others => null;
                end case;
            end if;

            if blocking_i then
                code_v := code_i;
                enable_v := enable_i;
                getTag_v := getTag_i;
                putVal_v := putVal_i;
            else
                code_v := code;
                enable_v := enable;
                getTag_v := getTag;
                putVal_v := putVal;
            end if;
            code_i <= code_v;
            enable_i <= enable_v;
            getTag_i <= getTag_v;
            putVal_i <= putVal_v;

            if u232c_out.recf = '1' and ok = '0' and recv_cnt /= 3 then
                ok <= '1';
                recv_buf(3 downto 1) <= recv_buf(2 downto 0);
                recv_buf(0) <= u232c_out.recv_data;
            end if;

            if u232c_out.recf = '0' and ok = '1' then
                ok <= '0';
            end if;

            if u232c_out.sent = '1' and go = '0' and send_cnt /= 0 then
                go <= '1';
                send_cnt_v := send_cnt - 1;
            else
                send_cnt_v := send_cnt;
            end if;
            u232c_in.send_data <= send_buf(to_integer(send_cnt - 1));

            if u232c_out.sent = '0' and go = '1' then
                go <= '0';
            end if;

            blocking_v := false;
            recv_cnt_v := recv_cnt;
            if enable_v then
                case code_v is
                    when "000" => assert(false);
                    when "001" => assert(false);
                    when others => null;
                end case;

                case code_v is
                    when "110" | "111" =>
                        emitTag <= getTag_v;
                    when "010" =>
                        if recv_cnt /= 0 then
                            emitTag <= getTag_v;
                        else
                            emitTag <= "00000";
                        end if;
                    when others =>
                        emitTag <= "00000";
                end case;

                case code_v is
                    when "010" =>
                        if recv_cnt = 0 then
                            blocking_v := true;
                        else
                            recv_cnt_v := recv_cnt - 1;
                        end if;
                    when "011" =>
                        if send_cnt_v = 3 then
                            blocking_v := true;
                        else
                            send_buf(0) <= putVal_v(7 downto 0);
                            send_buf(3 downto 1) <= send_buf(2 downto 0);
                            send_cnt_v := send_cnt_v + 1;
                        end if;
                    when others => null;
                end case;

                case code_v is
                    when "110" =>
                        emitVal <= x"0000000" & "00" & std_logic_vector(recv_cnt);
                    when "111" =>
                        emitVal <= x"0000000" & "00" & std_logic_vector(send_cnt);
                    when others =>
                        emitVal <= x"000000" & recv_buf(to_integer(recv_cnt - 1));
                end case;

            else
                emitTag <= "00000";
                emitVal <= recv_buf(3) & recv_buf(2) & recv_buf(1) & recv_buf(0);
            end if;

            if u232c_out.recf = '1' and ok = '0' and recv_cnt /= 3 then
                recv_cnt_v := recv_cnt_v + 1;
            else
                recv_cnt_v := recv_cnt_v;
            end if;

            recv_cnt <= recv_cnt_v;
            send_cnt <= send_cnt_v;
            blocking_i <= blocking_v;
        end if;
    end process;

end behavioral;
