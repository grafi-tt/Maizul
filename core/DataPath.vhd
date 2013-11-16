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
            instruction : out instruction_t);
    end component;

    component RegSet is
        port (
            clk : in std_logic;
            tagS : in tag_t;
            valS : out value_t;
            tagT : in tag_t;
            valT : out value_t;
            tagW : in tag_t;
            lineW : in value_t);
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
            code : in std_logic_vector(2 downto 0);
            funct : in std_logic_vector(1 downto 0);
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
            code : in std_logic;
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
            blocking : out boolean);
    end component;

    signal fetchedInst : instruction_t;
    signal pc : blkram_addr := (others => '0');
    signal fetchedPC : blkram_addr;
    signal PCLine : blkram_addr;

    signal instruction : instruction_t := (others => '0');

    signal opH : std_logic_vector(1 downto 0);
    signal opL : std_logic_vector(3 downto 0);

    signal tagX, tagY, tagZ : tag_t;
    signal imm : std_logic_vector(15 downto 0);

    signal valX, valY : value_t;
    signal valRegX, valRegY : value_t;
    signal valFX, valFY : value_t;
    signal valFRegX, valFRegY : value_t;
    signal immSigned : value_t;

    signal tagW : tag_t;
    signal valW : value_t;

    signal tagFW : tag_t;
    signal valFW : value_t;

    signal codeA : std_logic_vector(3 downto 0);
    signal tagD : tag_t;
    signal emitTagA : tag_t;
    signal emitValA : value_t;

    signal codeF : std_logic_vector(2 downto 0);
    signal functF : std_logic_vector(1 downto 0);
    signal tagFD : tag_t;
    signal tagF1, tagF2, emitTagF : tag_t;
    signal emitValF : value_t;

    signal valAP : value_t;
    signal valBP : value_t;

    signal codeB : std_logic_vector(4 downto 0);
    signal tagL : tag_t;
    signal valA : value_t;
    signal valB : value_t;
    signal target : blkram_addr;
    signal emitTagB : tag_t;
    signal emitValB : blkram_addr;
    signal jump : boolean;

    signal addr0 : sram_addr := (others => '0');
    signal load0, load1, load2, load3, emitLoad : boolean := true;
    signal tagM0, tagM1, tagM2, tagM3, emitTagM : tag_t := (others => '0');
    signal tagFM0, tagFM1, tagFM2, tagFM3, emitTagFM : tag_t := (others => '0');
    signal valM0, valM1, valM2, emitValM : value_t := (others => '0');
    signal fwdM_1, fwdM_2 : boolean := false;
    signal tagLd : tag_t;
    signal tagFLd : tag_t;

    signal enableIO : boolean;
    signal emitTagIO : tag_t;
    signal emitValIO : value_t;

    signal ignoreJ2 : boolean;
    signal ignoreJ1 : boolean := false;
    signal gprX, gprY, gprZ : boolean;
    signal fprX, fprY, fprZ : boolean;
    signal stallX, stallY, stallZ : boolean;
    signal stallFX, stallFY, stallFZ : boolean;

    signal fetchStall : boolean;
    signal stall : boolean;
    signal ignore : boolean;
    signal blocking : boolean;

begin
    gpr_map : RegSet port map (
        clk => clk,
        tagS => tagX,
        valS => valRegX,
        tagT => tagY,
        valT => valRegY,
        tagW => tagW,
        lineW => valW);
    tagW <= emitTagA or emitTagB or emitTagIO or tagLd;
    valW <= emitValA when emitTagA /= "00000" else
            value_t(x"0000" & emitValB) when emitTagB /= "00000" else
            emitValIO when emitTagIO /= "00000" else
            emitValM when tagLd /= "00000" else
            (others => '0');
    tagLd <= emitTagM when emitLoad else "00000";

    fpr_map : RegSet port map (
        clk => clk,
        tagS => tagX,
        valS => valFRegX,
        tagT => tagY,
        valT => valFRegY,
        tagW => tagFW,
        lineW => valFW);
    tagFW <= emitTagF or tagFld;
    valFW <= emitValF when emitTagF /= "00000" else
             emitValM when tagFld /= "00000" else
             (others => '0');
    tagFld <= emitTagFM when emitLoad else "00000";

    fetch_map : Fetch port map (
        clk => clk,
        stall => fetchStall,
        jump => jump,
        jumpAddr => PCLine,
        pc => fetchedPC,
        instruction => fetchedInst);
    fetchStall <= stall and not ignore;

    alu_map : ALU port map (
        clk => clk,
        code => codeA,
        tagD => tagD,
        valA => valAP,
        valB => valBP,
        emitTag => emitTagA,
        emitVal => emitValA);
    tagD <= "00000" when stall or ignore else
            tagY when opH = "00" else
            tagZ when (opH = "01" and opL(3 downto 1) = "000") else
            "00000";
    codeA <= opL when opH = "00" else instruction(3 downto 0);

    fpu_map : FPU port map (
        clk => clk,
        code => codeF,
        funct => functF,
        tagD => tagFD,
        valA => valAP,
        valB => valBP,
        tag1 => tagF1,
        tag2 => tagF2,
        emitTag => emitTagF,
        emitVal => emitValF);
    tagFD <= tagZ when (opH = "01" and opL(3 downto 1) = "100") and not stall and not ignore else
             "00000";
    codeF <= instruction(2 downto 0);
    functF <= instruction(5 downto 4);

    valAP <= valX when opH = "00" or opL(0) = '0' else valFX;
    valBP <= immSigned when opH = "00" else valY when opL(0) = '0' else valFY;

    branch_map : Branch port map (
        clk => clk,
        code => codeB,
        tagL => tagL,
        valA => valA,
        valB => valB,
        link => pc,
        target => target,
        emitTag => emitTagB,
        emitLink => emitValB,
        emitTarget => PCLine,
        result => jump);
    codeB <= "00001" when stall or ignore else -- always false
             opH(0) & opL when opH(1) = '1' else
             "00000" when (opH = "01" and opL(3 downto 2) = "01" and opL(1 downto 0) /= "11") else -- always true
             "00001"; -- always false
    tagL <= tagY when (opH = "01" and opL(3 downto 2) = "01" and opL(1 downto 0) /= "11") and not stall and not ignore else
            "00000";
    valA <= (others => '0') when stall or ignore else
            valX when opH = "10" else
            valFX when opH = "11" else
            (others => '0');
    valB <= (others => '0') when stall or ignore else
            valY when opH = "10" else
            valFY when opH = "11" else
            (others => '0');
    target <= blkram_addr(imm) when opH(1) = '1' else blkram_addr(imm or valX(15 downto 0));



    io_map : IO port map (
        clk => clk,
        enable => enableIO,
        code => imm(0),
        serialOk => serialOk,
        serialGo => serialGo,
        serialRecvData => serialRecvData,
        serialSendData => serialSendData,
        serialRecved => serialRecved,
        serialSent => serialSent,
        getTag => tagY,
        putVal => valX,
        emitTag => emitTagIO,
        emitVal => emitValIO,
        blocking => blocking);
    enableIO <= opH = "01" and opL = "0111" and not stall and not ignore;

    ignoreJ2 <= jump;

    -- phase 0
    load0 <= opL(0) = '0' when opH = "01" and opL(2 downto 1) = "01"  and not stall and not ignore else true;
    tagM0 <= tagY         when opH = "01" and opL(3 downto 1) = "001" and not stall and not ignore else "00000";
    tagFM0 <= tagY        when opH = "01" and opL(3 downto 1) = "101" and not stall and not ignore else "00000";
    valM0 <= valY;
    addr0 <= sram_addr(unsigned(valX(19 downto 0)) + unsigned(immSigned(19 downto 0)));

    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            if not fetchStall then
                instruction <= fetchedInst;
                pc <= fetchedPC;
            end if;

            ignoreJ1 <= ignoreJ2;

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
            if emitLoad and ((tagM1 /= "00000" and tagM1 = emitTagM) or (tagFM1 /= "00000" and tagFM1 = emitTagFM)) then
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
                if not fwdM_1 then
                    if fwdM_2 then
                        sramData <= emitValM;
                    else
                        sramData <= valM2;
                    end if;
                end if;
            end if;

            -- phase 4
            emitLoad <= load3;
            emitTagM <= tagM3;
            emitTagFM <= tagFM3;
            emitValM <= sramData;

        end if;
    end process;

    opH <= instruction(31 downto 30);
    opL <= instruction(29 downto 26);

    tagX <= tag_t(instruction(25 downto 21));
    tagY <= tag_t(instruction(20 downto 16));
    tagZ <= tag_t(instruction(15 downto 11));
    imm <= instruction(15 downto 0);
    immSigned <= value_t(resize(signed(imm), 32));

    gprX <= opH = "00" or (opH = "01" and opL(2 downto 0) /= "001") or opH = "10";
    gprY <= opH = "00" or (opH = "01" and (opL(2 downto 0) /= "001" and opL(3 downto 1) /= "101")) or opH = "10";
    gprZ <= opH = "01" and opL(3 downto 1) = "000";

    fprX <= (opH = "01" and opL(2 downto 0) = "001") or opH = "11";
    fprY <= (opH = "01" and (opL(2 downto 0) = "001" or opL(3 downto 1) = "101")) or opH = "11";
    fprZ <= opH = "01" and opL(3 downto 1) = "100";

    valX <= (others => '0') when tagX = "00000" else
            emitValA when tagX = emitTagA else
            value_t(x"0000" & emitValB) when tagX = emitTagB else
            emitValM when emitLoad and tagX = emitTagM else
            valRegX;

    valY <= (others => '0') when tagY = "00000" else
            emitValA when tagY = emitTagA else
            value_t(x"0000" & emitValB) when tagY = emitTagB else
            emitValM when emitLoad and tagY = emitTagM else
            valRegY;

    valFX <= (others => '0') when tagX = "00000" else
             emitValF when tagX = emitTagF else
             emitValM when emitLoad and tagX = emitTagFM else
             valFRegX;

    valFY <= (others => '0') when tagY = "00000" else
             emitValF when tagY = emitTagF else
             emitValM when emitLoad and tagY = emitTagFM else
             valFRegY;

    stallX <= gprX and tagX /= "00000" and
              ( (load1 and tagX = tagM1) or
                (load2 and tagX = tagM2) or
                (load3 and tagX = tagM3));
    stallY <= gprY and tagY /= "00000" and
              ( (load1 and tagY = tagM1) or
                (load2 and tagY = tagM2) or
                (load3 and tagY = tagM3));
    stallZ <= gprZ and tagZ /= "00000" and
              ( (load1 and tagZ = tagM1) or
                (load2 and tagZ = tagM2) or
                (load3 and tagM3 /= "00000"));

    stallFX <= fprX and tagX /= "00000" and
               ( (tagX = tagF1) or
                 (tagX = tagF2) or
                 (load1 and tagX = tagFM1) or
                 (load2 and tagX = tagFM2) or
                 (load3 and tagX = tagFM3));
    stallFY <= fprY and tagY /= "00000" and
               ( (tagY = tagF1) or
                 (tagY = tagF2) or
                 (load1 and tagY = tagFM1) or
                 (load2 and tagY = tagFM2) or
                 (load3 and tagY = tagFM3));
    stallFZ <= fprZ and tagZ /= "00000" and
               ( (load1 and tagFM1 /= "00000"));

    stall <= stallX or stallY or stallZ or stallFX or stallFY or stallFZ or blocking;
    ignore <= ignoreJ1 or ignoreJ2;

end DataPathImp;
