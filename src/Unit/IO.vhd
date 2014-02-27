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
        emitTag : out tag_t;
        emitVal : out value_t;
        u232c_in : out u232c_in_t;
        u232c_out : in u232c_in_t;
        emitInstWE : out boolean := false;
        emitInst : out instruction_t := (others => '0');
        emitInstPtr : out blkram_addr := (others => '0'));
end IO;

architecture statemachine of IO is
    subtype cnt_t is unsigned(1 downto 0);
    type buf_t is array(3 downto 0) of value_t;

    signal recv_cnt, send_cnt : cnt_t;
    signal recv_buf, send_buf : buf_t := (others => (others => '0'));
    signal ok, go : std_logic := '0';
    signal inst_ptr : unsigned(15 downto 0) := (others => '0');

begin
    u232c_in.send_data  <= send_buf(0);
    u232c_out.recv_data <= recv_buf(0);
    u232c_in.ok <= ok;
    u232c_in.go <= go;

    exec : process(clk)
        variable recv_cnt_v : cnt_t;
        variable recv_buf_v : buf_t;
        variable send_cnt_v : cnt_t;
        variable send_cnt_v : buf_t;

    begin
        if rising_edge(clk) then
            emitInstWE <= enable and code = "101";
            emitInst <= instruction_t(putVal);
            emitInstPtr <= blkram_addr(inst_ptr);

            recv_cnt_v := recv_cnt;
            recv_buf_v := recv_buf;
            send_cnt_v := recv_cnt;
            send_buf_v := send_buf;

            if u232c_out.recf = '1' and ok = '0' then
                ok <= '1';
                recv_buf_v(3 downto 1) := recv_buf_v(2 downto 0);
                if recv_cnt_v /= 3 then
                    recv_cnt_v := recv_cnt_v + 1;
                end if;
            end if;

            if u232c_out.recf = '0' and ok = '1' then
                ok <= '0';
            end if;

            emit_val := recv_buf(3) & recv_buf(2) & recv_buf(1) & recv_buf(0);
            emit_tag := "00000";

            if enable then
                case code is
                    when "000" =>
                        emit_tag := getTag;
                        recv_cnt_v := 0;

                    when "001" =>
                        send_cnt_v := 0;
                        send_buf_v(0) := putVal(31 downto 24);
                        send_buf_v(1) := putVal(23 downto 16);
                        send_buf_v(2) := putVal(15 downto  8);
                        send_buf_v(3) := putVal( 7 downto  0);

                    when "010" =>
                        emit_tag := getTag;
                        recv_cnt_v := recv_cnt_v - 1;
                        emit := x"000000" & recv_buf_v(recv_cnt);

                    when "011" =>
                        send_buf_v(sent_cnt_v) := putVal(7 downto 0);
                        send_cnt_v := send_cnt_v + 1;

                    when "100" =>
                        inst_ptr <= unsigned(putVal(15 downto 0));

                    when "101" =>
                        inst_ptr <= inst_ptr + 1;

                    when "110" =>
                        emit := x"0000000" & "00" & recv_cnt;
                        emit_tag := getTag;

                    when "111" =>
                        emit := x"0000000" & "00" & send_cnt;
                        emit_tag := getTag;

                    when others => null;
                end case;
            end if;

            if u232c_out.sent = '1' and go = '0' then
                if send_cnt_v /= 0 then
                    go <= '1';
                    send_cnt_v := send_cnt_v - 1;
                    send_buf_v(2 downto 0) := send_buf_v(3 downto 1);
                end if;
            end if;

            if u232c_out.sent = '0' and go = '1' then
                go <= '0';
            end if;

            recv_cnt <= recv_cnt_v;
            recv_buf <= recv_buf_v;
            send_cnt <= send_cnt_v;
            send_buf <= send_buf_v;
        end if;
    end process;

end statemachine;
