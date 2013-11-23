library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity DataPath is
    port (
        clk : in std_logic;

        serialOk : out std_logic;
        serialGo : out std_logic;
        serialRecvData : in std_logic_vector(7 downto 0);
        serialSendData : out std_logic_vector(7 downto 0);
        serialRecved : in std_logic;
        serialSent : in std_logic;

        sramLoad : out boolean := true;
        sramAddr : out sram_addr := (others => '0');
        sramData : inout value_t := (others => '0'));
end DataPath;

architecture DataPathImp of DataPath is
    component Fetch is
        port (
            clk : in std_logic;
            stall : in boolean;
            jump : in boolean;
            jumpAddr : in blkram_addr;
            pc : out blkram_addr;
            inst : out instruction_t;
            we : in boolean;
            wpc : in blkram_addr;
            winst : in instruction_t);
    end component;

    component ALU is
        port (
            clk : in std_logic;
            code : in std_logic_vector(3 downto 0);
            tagD : in tag_t;
            valA : in value_t;
            valB : in value_t;
            emitTag : out tag_t;
            emitVal : out value_t);
    end component;

    component FPU is
        port (
            clk : in std_logic;
            code : in std_logic_vector(5 downto 0);
            tagD : in tag_t;
            valA : in value_t;
            valB : in value_t;
            tag1 : buffer tag_t;
            tag2 : buffer tag_t;
            emitTag : out tag_t;
            emitVal : out value_t);
    end component;

    component Branch is
        port (
            clk : in std_logic;
            code : in std_logic_vector(4 downto 0);
            tagL : in tag_t;
            valA : in value_t;
            valB : in value_t;
            link : in blkram_addr;
            target : in blkram_addr;
            emitTag : out tag_t;
            emitLink : out blkram_addr;
            emitTarget : out blkram_addr;
            result : out boolean);
    end component;

    component IO is
        port (
            clk : in std_logic;
            enable : in boolean;
            code : in std_logic_vector(2 downto 0);
            serialOk : out std_logic;
            serialGo : out std_logic;
            serialRecvData : in std_logic_vector(7 downto 0);
            serialSendData : out std_logic_vector(7 downto 0);
            serialRecved : in std_logic;
            serialSent : in std_logic;
            getTag : in tag_t;
            putVal : in value_t;
            emitTag : out tag_t;
            emitVal : out value_t;
            emitInstWE : out boolean;
            emitInst : out instruction_t;
            emitInstPtr : out blkram_addr;
            blocking : out boolean);
    end component;

    type reg_file_t is array(31 downto 0) of value_t;
    signal gpr_file : reg_file_t := (others => (others => '0'));
    signal fpr_file : reg_file_t := (others => (others => '0'));
    attribute RAM_STYLE : string;
    attribute RAM_STYLE of gpr_file : signal is "distributed";
    attribute RAM_STYLE of fpr_file : signal is "distributed";

    signal fetched_inst : instruction_t;
    signal fetched_pc : blkram_addr;
    signal inst : instruction_t := (others => '0');
    signal pc : blkram_addr := (others => '0');
    signal enable_inst_w : boolean;
    signal inst_ptr_w : blkram_addr;
    signal inst_w : instruction_t;

    signal PCLine : blkram_addr := (others => '0');
    signal stall_fetch : boolean := false;

    signal code_alu : std_logic_vector(3 downto 0) := (others => '0');
    signal tag_alu_d : tag_t := (others => '0');
    signal emit_tag_alu : tag_t;
    signal emit_val_alu : value_t;

    signal code_fpu : std_logic_vector(5 downto 0) := (others => '0');
    signal tag_fpu_d : tag_t := (others => '0');
    signal pipe1_tag_fpu, pipe2_tag_fpu, emit_tag_fpu : tag_t;
    signal emit_val_fpu : value_t;

    signal val_alu_fpu_a, val_alu_fpu_b : value_t := (others => '0');

    signal code_bra : std_logic_vector(4 downto 0) := "00000";
    signal tag_bra_l : tag_t := (others => '0');
    signal val_bra_a : value_t := (others => '0'); -- jmp to addr 0 once
    signal val_bra_b : value_t := (others => '0');
    signal val_bra_l : blkram_addr := (others => '0');
    signal val_bra_t : blkram_addr := (others => '0');
    signal emit_tag_bra : tag_t;
    signal emit_val_bra : blkram_addr;

    signal code_io : std_logic_vector(2 downto 0) := "000";
    signal enable_io : boolean := false;
    signal tag_spc_y : tag_t := (others => '0');
    signal val_spc_x : value_t := (others => '0');

    signal emit_tag_spc : tag_t;
    signal emit_val_spc : value_t;
    signal blocking : boolean;

    signal jump1 : boolean;
    signal jump2 : boolean := false;

    signal addr0 : sram_addr := (others => '0');
    signal load0, load1, load2, load3 : boolean := true;
    signal tagM0, tagM1, tagM2, tagM3, emitTagLoad : tag_t := (others => '0');
    signal tagFM0, tagFM1, tagFM2, tagFM3, emitTagFLoad : tag_t := (others => '0');
    signal valM0, valM1, valM2, emitValM : value_t := (others => '0');
    signal fwdM_1, fwdM_2 : boolean := false;

    signal tag_gpr_w_sig : tag_t;
    signal val_gpr_w_sig : value_t;
    signal tag_fpr_w_sig : tag_t;
    signal val_fpr_w_sig : value_t;

begin
    -- fetch
    fetch_map : Fetch port map (
        clk => clk,
        stall => stall_fetch,
        jump => jump1,
        jumpAddr => PCLine,
        pc => fetched_pc,
        inst => fetched_inst,
        we => enable_inst_w,
        wpc => inst_ptr_w,
        winst => inst_w);

    sequential : process(clk)
    begin
        if rising_edge(clk) then
            if not stall_fetch then
                inst <= fetched_inst;
                pc <= fetched_pc;
            end if;

            gpr_file(to_integer(unsigned(tag_gpr_w_sig))) <= val_gpr_w_sig;
            fpr_file(to_integer(unsigned(tag_fpr_w_sig))) <= val_fpr_w_sig;

            jump2 <= jump1;
        end if;
    end process;

    combinatorial : process(inst,
                            emit_tag_alu, emit_val_alu,
                            pipe1_tag_fpu, pipe2_tag_fpu, emit_tag_fpu, emit_val_fpu,
                            emit_tag_bra, emit_val_bra, PCLine, jump1,
                            emit_tag_spc, emit_val_spc, blocking,
                            tagM1, tagM2, tagM3, emitTagLoad, tagFM1, tagFM2, tagFM3, emitTagFLoad, emitValM)
        variable tag_gpr_w : tag_t;
        variable val_gpr_w : value_t;
        variable tag_fpr_w : tag_t;
        variable val_fpr_w : value_t;

        variable opcode : std_logic_vector(5 downto 0);
        variable tag_x, tag_y, tag_z : tag_t;
        variable imm : unsigned(15 downto 0);

        variable is_alu_imm, is_alu_gpr, is_alu_fpr : boolean;
        variable is_fpu_gpr, is_fpu_fpr : boolean;
        variable is_mem_gpr_ld, is_mem_gpr_st, is_mem_fpr_ld, is_mem_fpr_st : boolean;
        variable is_spc, is_jmp, is_bra_gpr, is_bra_fpr : boolean;

        variable val_gpr_x, val_gpr_y, imm_signed, val_gpr_fwd_x, val_gpr_fwd_y : value_t;
        variable val_fpr_x, val_fpr_y, val_fpr_fwd_x, val_fpr_fwd_y : value_t;

        variable stall_raw_gpr_x, stall_raw_gpr_y, stall_waw_gpr_y, stall_waw_gpr_z : boolean;
        variable stall_raw_fpr_x, stall_raw_fpr_y, stall_mst_fpr_y, stall_waw_fpr_z : boolean;

        variable stall, ignore : boolean;

    begin
        tag_gpr_w := emit_tag_alu or emit_tag_bra or emit_tag_spc or emitTagLoad;
        if emit_tag_alu /= "00000" then
            val_gpr_w := emit_val_alu;
        elsif emit_tag_bra /= "00000" then
            val_gpr_w := value_t(x"0000" & emit_val_bra);
        elsif emit_tag_spc /= "00000" then
            val_gpr_w := emit_val_spc;
        elsif emitTagLoad /= "00000" then
            val_gpr_w := emitValM;
        else
            val_gpr_w := (others => '0');
        end if;

        tag_fpr_w := emit_tag_fpu or emitTagFLoad;
        if emit_tag_fpu /= "00000" then
            val_fpr_w := emit_val_fpu;
        elsif emitTagFLoad /= "00000" then
            val_fpr_w := emitValM;
        else
            val_fpr_w := (others => '0');
        end if;

        tag_gpr_w_sig <= tag_gpr_w;
        tag_fpr_w_sig <= tag_fpr_w;
        val_gpr_w_sig <= val_gpr_w;
        val_fpr_w_sig <= val_fpr_w;

        opcode := inst(31 downto 26);
        tag_x := tag_t(inst(25 downto 21));
        tag_y := tag_t(inst(20 downto 16));
        tag_z := tag_t(inst(15 downto 11));
        imm := unsigned(inst(15 downto 0));

        is_alu_imm := opcode(5 downto 4) = "00";
        is_alu_gpr := opcode = "010000";
        is_alu_fpr := opcode = "010001";

        is_fpu_gpr := opcode = "011000";
        is_fpu_fpr := opcode = "011001";

        is_mem_gpr_ld := opcode = "010010";
        is_mem_gpr_st := opcode = "010011";
        is_mem_fpr_ld := opcode = "011010";
        is_mem_fpr_st := opcode = "011011";

        is_spc := opcode(5 downto 2) = "0101" and opcode(1 downto 0) = "11";
        is_jmp := opcode(5 downto 2) = "0101" and opcode(1 downto 0) /= "11";
        is_bra_gpr := opcode(5 downto 4) = "10";
        is_bra_fpr := opcode(5 downto 4) = "11";

        val_gpr_x := gpr_file(to_integer(unsigned(tag_x)));
        val_gpr_y := gpr_file(to_integer(unsigned(tag_y)));
        imm_signed := value_t(resize(signed(imm), 32));
        if tag_x = tag_gpr_w then
            val_gpr_fwd_x := val_gpr_w;
        else
            val_gpr_fwd_x := val_gpr_x;
        end if;
        if tag_y = tag_gpr_w then
            val_gpr_fwd_y := val_gpr_w;
        else
            val_gpr_fwd_y := val_gpr_y;
        end if;

        val_fpr_x := fpr_file(to_integer(unsigned(tag_x)));
        val_fpr_y := fpr_file(to_integer(unsigned(tag_y)));
        if tag_x = tag_fpr_w then
            val_fpr_fwd_x := val_fpr_w;
        else
            val_fpr_fwd_x := val_fpr_x;
        end if;
        if tag_y = tag_fpr_w then
            val_fpr_fwd_y := val_fpr_w;
        else
            val_fpr_fwd_y := val_fpr_y;
        end if;

        stall_raw_gpr_x := tag_x /= "00000" and
                           not (is_alu_fpr or is_fpu_fpr or is_bra_fpr) and
                           ( (load1 and tag_x = tagM1) or
                             (load2 and tag_x = tagM2) or
                             (load3 and tag_x = tagM3));
        stall_raw_gpr_y := tag_y /= "00000" and
                           (is_alu_gpr or is_fpu_gpr or is_bra_gpr) and
                           ( (load1 and tag_y = tagM1) or
                             (load2 and tag_y = tagM2) or
                             (load3 and tag_y = tagM3));
        stall_waw_gpr_y := tag_y /= "00000" and
                           (is_alu_imm or is_spc or is_jmp) and
                           ( (load1 and tag_y = tagM1) or
                             (load2 and tag_y = tagM2) or
                             (load3 and tagM3 /= "00000"));
        stall_waw_gpr_z := tag_z /= "00000" and
                           is_alu_gpr and
                           ( (load1 and tag_z = tagM1) or
                             (load2 and tag_z = tagM2) or
                             (load3 and tagM3 /= "00000"));
        stall_raw_fpr_x := tag_x /= "00000" and
                           (is_alu_fpr or is_fpu_fpr or is_bra_fpr) and
                           ( (tag_x = pipe1_tag_fpu) or
                             (tag_x = pipe2_tag_fpu) or
                             (load1 and tag_x = tagFM1) or
                             (load2 and tag_x = tagFM2) or
                             (load3 and tag_x = tagFM3));
        stall_raw_fpr_y := tag_y /= "00000" and
                           (is_alu_fpr or is_fpu_fpr or is_bra_fpr) and
                           ( (tag_y = pipe1_tag_fpu) or
                             (tag_y = pipe2_tag_fpu) or
                             (load1 and tag_y = tagFM1) or
                             (load2 and tag_y = tagFM2) or
                             (load3 and tag_y = tagFM3));
        stall_mst_fpr_y := tag_y /= "00000" and
                           (is_mem_fpr_st) and
                           ( (tag_y = pipe1_tag_fpu) or
                             (tag_y = pipe2_tag_fpu));
        stall_waw_fpr_z := tag_z /= "00000" and
                           (is_fpu_gpr or is_fpu_fpr) and
                           ( (load1 and tagFM1 /= "00000"));

        stall := stall_raw_gpr_x or stall_raw_gpr_y or stall_waw_gpr_y or stall_waw_gpr_z or
                 stall_raw_fpr_x or stall_raw_fpr_y or stall_mst_fpr_y or stall_waw_fpr_z or
                 blocking;
        ignore := jump2 or jump1;
        stall_fetch <= not ignore and stall;

        if is_alu_imm then
            code_alu <= opcode(3 downto 0);
        else
            code_alu <= inst(3 downto 0);
        end if;
        if ignore or stall then
            tag_alu_d <= "00000";
        elsif is_alu_imm then
            tag_alu_d <= tag_y;
        elsif is_alu_gpr or is_alu_fpr then
            tag_alu_d <= tag_z;
        else
            tag_alu_d <= "00000";
        end if;

        code_fpu <= inst(5 downto 0);
        if ignore or stall then
            tag_fpu_d <= "00000";
        elsif is_fpu_gpr or is_fpu_fpr then
            tag_fpu_d <= tag_z;
        else
            tag_fpu_d <= "00000";
        end if;

        if is_alu_imm then
            val_alu_fpu_a <= val_gpr_fwd_x;
            val_alu_fpu_b <= imm_signed;
        elsif opcode(0) = '0' then
            val_alu_fpu_a <= val_gpr_fwd_x;
            val_alu_fpu_b <= val_gpr_fwd_y;
        else
            val_alu_fpu_a <= val_fpr_fwd_x;
            val_alu_fpu_b <= val_fpr_fwd_y;
        end if;

        if ignore or stall then
            code_bra <= "00000";
            tag_bra_l <= "00000";
            if opcode(4) = '0' then
                val_bra_a <= '1' & val_gpr_fwd_x(30 downto 0);
                val_bra_b <= '0' & val_gpr_fwd_y(30 downto 0);
            else
                val_bra_a <= '1' & val_fpr_fwd_x(30 downto 0);
                val_bra_b <= '0' & val_fpr_fwd_y(30 downto 0);
            end if;
            val_bra_t <= blkram_addr(imm);
        else
            if is_bra_gpr or is_bra_fpr then
                code_bra <= opcode(4 downto 0);
                tag_bra_l <= "00000";
                if opcode(4) = '0' then
                    val_bra_a <= val_gpr_fwd_x;
                    val_bra_b <= val_gpr_fwd_y;
                else
                    val_bra_a <= val_fpr_fwd_x;
                    val_bra_b <= val_fpr_fwd_y;
                end if;
                val_bra_t <= blkram_addr(imm);
            else
                if is_jmp then
                    code_bra <= "00010";
                    tag_bra_l <= tag_y;
                else
                    code_bra <= "00000";
                    tag_bra_l <= "00000";
                end if;
                if opcode(4) = '0' then
                    val_bra_a <= '1' & val_gpr_fwd_x(30 downto 0);
                    val_bra_b <= '0' & val_gpr_fwd_y(30 downto 0);
                else
                    val_bra_a <= '1' & val_fpr_fwd_x(30 downto 0);
                    val_bra_b <= '0' & val_fpr_fwd_y(30 downto 0);
                end if;
                val_bra_t <= blkram_addr(imm or unsigned(val_gpr_fwd_x(15 downto 0)));
            end if;
        end if;
        val_bra_l <= pc;

        code_io <= inst(2 downto 0);
        enable_io <= not (ignore or stall) and is_spc;
        tag_spc_y <= tag_y;
        val_spc_x <= val_gpr_fwd_x;

        if ignore or stall then
            load0 <= true;
            tagM0 <= "00000";
            tagFM0 <= "00000";
        else
            load0 <= not (is_mem_gpr_st or is_mem_fpr_st);
            if is_mem_gpr_st or is_mem_gpr_ld then
                tagM0 <= tag_y;
            else
                tagM0 <= "00000";
            end if;
            if is_mem_fpr_st or is_mem_fpr_ld then
                tagFM0 <= tag_y;
            else
                tagFM0 <= "00000";
            end if;
        end if;
        if opcode(3) = '0' then
            valM0 <= val_gpr_fwd_y;
        else
            valM0 <= val_fpr_fwd_y;
        end if;
        addr0 <= sram_addr(unsigned(val_gpr_fwd_x(19 downto 0)) + unsigned(imm_signed(19 downto 0)));

    end process;

    alu_map : ALU port map (
        clk => clk,
        code => code_alu,
        tagD => tag_alu_d,
        valA => val_alu_fpu_a,
        valB => val_alu_fpu_b,
        emitTag => emit_tag_alu,
        emitVal => emit_val_alu);

    fpu_map : FPU port map (
        clk => clk,
        code => code_fpu,
        tagD => tag_fpu_d,
        valA => val_alu_fpu_a,
        valB => val_alu_fpu_b,
        tag1 => pipe1_tag_fpu,
        tag2 => pipe2_tag_fpu,
        emitTag => emit_tag_fpu,
        emitVal => emit_val_fpu);

    branch_map : Branch port map (
        clk => clk,
        code => code_bra,
        tagL => tag_bra_l,
        valA => val_bra_a,
        valB => val_bra_b,
        link => val_bra_l,
        target => val_bra_t,
        emitTag => emit_tag_bra,
        emitLink => emit_val_bra,
        emitTarget => PCLine,
        result => jump1);

    io_map : IO port map (
        clk => clk,
        enable => enable_io,
        code => code_io,
        serialOk => serialOk,
        serialGo => serialGo,
        serialRecvData => serialRecvData,
        serialSendData => serialSendData,
        serialRecved => serialRecved,
        serialSent => serialSent,
        getTag => tag_spc_y,
        putVal => val_spc_x,
        emitTag => emit_tag_spc,
        emitVal => emit_val_spc,
        emitInstWE => enable_inst_w,
        emitInst => inst_w,
        emitInstPtr => inst_ptr_w,
        blocking => blocking);

    do_sram : process(clk)
    begin
        if rising_edge(clk) then
            -- phase 1
            load1 <= load0;
            tagM1 <= tagM0;
            tagFM1 <= tagFM0;
            valM1 <= valM0;
            sramLoad <= load0;
            sramAddr <= addr0;

            -- phase 2
            load2 <= load1;
            tagM2 <= tagM1;
            tagFM2 <= tagFM1;
            if (tagM1 /= "00000" and tagM1 = emitTagLoad) or (tagFM1 /= "00000" and tagFM1 = emitTagFLoad) then
                valM2 <= emitValM;
            else
                valM2 <= valM1;
            end if;
            fwdM_2 <= load3 and ((tagM1 /= "00000" and tagM1 = tagM3) or (tagFM1 /= "00000" and tagFM1 = tagFM3));
            fwdM_1 <= load2 and ((tagM1 /= "00000" and tagM1 = tagM2) or (tagFM1 /= "00000" and tagFM1 = tagFM2));

            -- phase 3
            load3 <= load2;
            tagM3 <= tagM2;
            tagFM3 <= tagFM2;
            if load2 then
                sramData <= (others => 'Z');
            else
                if fwdM_1 then
                    sramData <= sramData;
                elsif fwdM_2 then
                    sramData <= emitValM;
                else
                    sramData <= valM2;
                end if;
            end if;

            -- phase 4
            if load3 then
                emitTagLoad <= tagM3;
                emitTagFLoad <= tagFM3;
            else
                emitTagLoad <= "00000";
                emitTagFLoad <= "00000";
            end if;
            emitValM <= sramData;

        end if;
    end process;

end DataPathImp;
