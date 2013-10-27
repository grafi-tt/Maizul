library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity DataPath is
    port (
        clk : in std_logic;

        serialOk : buffer std_logic;
        serialGo : buffer std_logic;
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
            lineW : in value_t;
            tagM : in tag_t;
            lineM : inout value_t);
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

    component Branch is
        port (
            clk : in std_logic;
            code : in std_logic_vector(3 downto 0);
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
            serialOk : buffer std_logic;
            serialGo : buffer std_logic;
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

    signal tagX : tag_t;
    signal tagY : tag_t;
    signal tagZ : tag_t;
    signal imm : std_logic_vector(15 downto 0);

    signal valX : value_t;
    signal valRegX : value_t;
    signal valY : value_t;
    signal valRegY : value_t;
    signal immSigned : value_t;

    signal tagW : tag_t;
    signal valW : value_t;

    signal codeA : std_logic_vector(3 downto 0);
    signal tagD : tag_t;
    signal valBI : value_t;
    signal emitTagA : tag_t;
    signal emitValA : value_t;

    signal codeB : std_logic_vector(3 downto 0);
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
    signal valM0, valM1, valM2, valM3, emitValM : value_t := (others => '0');
    signal fwdM_1, fwdM_2 : boolean := false;
    signal tagMld : tag_t;

    signal enableIO : boolean;
    signal emitTagIO : tag_t;
    signal emitValIO : value_t;

    signal ignoreJ2 : boolean;
    signal ignoreJ1 : boolean := false;
    signal stallX : boolean;
    signal stallY : boolean;

    signal fetchStall : boolean;
    signal stall : boolean;
    signal ignore : boolean;
    signal blocking : boolean;

begin
    reg_set_map : RegSet port map (
        clk => clk,
        tagS => tagX,
        valS => valRegX,
        tagT => tagY,
        valT => valRegY,
        tagW => tagW,
        lineW => valW,
        tagM => tagMld,
        lineM => emitValM);
    tagW <= emitTagA or emitTagB or emitTagIO;
    valW <= emitValA when emitTagA /= "00000" else
            value_t(x"0000" & emitValB) when emitTagB /= "00000" else
            emitValIO when emitTagIO /= "00000" else
            (others => '0');
    tagMld <= emitTagM when emitLoad else "00000";

    fetch_map : Fetch port map (
        clk => clk,
        stall => fetchStall,
        jump => jump,
        jumpAddr => PCLine,
        pc => fetchedPC,
        instruction => fetchedInst);
    fetchStall <= stall and (not ignore);

    alu_map : ALU port map (
        clk => clk,
        code => codeA,
        tagD => tagD,
        valA => valX,
        valB => valBI,
        emitTag => emitTagA,
        emitVal => emitValA);
    tagD <= "00000" when (stall or ignore) else
            tagY when opH = "00" else
            tagZ when (opH = "01" and opL(3 downto 1) = "000") else
            "00000";
    valBI <= immSigned when opH = "00" else valY;
    codeA <= opL when opH = "00" else instruction(3 downto 0);

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
    codeB <= "0001" when stall or ignore else -- always false
             opL when opH = "11" else
             "0000" when (opH = "01" and opL(3 downto 2) = "01") else -- always true
             "0001"; -- always false
    tagL <= tagY when (opH = "01" and opL(3 downto 2) = "01") and (not stall) and (not ignore) else
            "00000";
    valA <= valX when opH = "11" and (not stall) and (not ignore) else (others => '0');
    valB <= valY when opH = "11" and (not stall) and (not ignore) else (others => '0');
    target <= blkram_addr(imm) when opH = "11" else blkram_addr(imm or valX(15 downto 0));



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
    enableIO <= opH = "01" and (opL = "0010" or opL = "1011") and (not stall) and (not ignore);

    ignoreJ2 <= jump;

    -- phase 0
    load0 <= opL(0) = '0' when opH = "10" and (not stall) and (not ignore) else true;
    tagM0 <= tagY         when opH = "10" and (not stall) and (not ignore) else "00000";
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
            valM1 <= valM0;
            sramLoad <= load0;
            sramAddr <= addr0;

            -- phase 2
            load2 <= load1;
            tagM2 <= tagM1;
            if emitLoad and tagM1 /= "00000" and tagM1 = emitTagM then
                valM2 <= emitValM;
            else
                valM2 <= valM1;
            end if;
            fwdM_2 <= load3 and tagM1 /= "00000" and tagM1 = tagM3;
            fwdM_1 <= load2 and tagM1 /= "00000" and tagM1 = tagM2;

            -- phase 3
            load3 <= load2;
            tagM3 <= tagM2;
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

    stallX <= tagX /= "00000" and
              ( (load1 and tagX = tagM1) or
                (load2 and tagX = tagM2) or
                (load3 and tagX = tagM3));
    stallY <= tagY /= "00000" and
              ((opH = "01" and opL(2 downto 1) = "00") or (opH = "11")) and
              ( (load1 and tagY = tagM1) or
                (load2 and tagY = tagM2) or
                (load3 and tagY = tagM3));

    stall <= stallX or stallY or blocking;
    ignore <= ignoreJ1 or ignoreJ2;

end DataPathImp;
