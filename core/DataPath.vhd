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

        sramLoad : out boolean;
        sramStore : out boolean;
        sramAddr : out sram_addr;
        sramData : inout value_t);
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

    signal emitBase, emitDisp : value_t := (others => '0');
    signal load2, load1 : boolean;
    signal load : boolean;
    signal tagM : tag_t := (others => '0');
    signal tagMld : tag_t;
    signal tagM1, tagM2 : tag_t := (others => '0');
    signal valM : value_t := (others => '0');
    signal pipeValMTmp ,emitValMTmp : value_t := (others => '0');
    signal pipeValM ,emitValM : value_t;

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
        lineM => sramData);
    tagW <= emitTagA or emitTagB or emitTagIO;
    valW <= emitValA when emitTagA /= "00000" else
            value_t(x"0000" & emitValB) when emitTagB /= "00000" else
            emitValIO when emitTagIO /= "00000" else
            (others => '0');
    tagMld <= tagM when load else "00000";

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
    valA <= valX when opH = "11" and (not stall) and (not ignore) else
            (others => '0');
    valB <= valY when opH = "11" and (not stall) and (not ignore) else
            (others => '0');
    target <= blkram_addr(imm) when opH = "11" else blkram_addr(imm or valX(15 downto 0));
    immSigned <= value_t(resize(signed(imm), 32));

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

    sramAddr <= sram_addr(unsigned(emitBase(19 downto 0)) + unsigned(emitDisp(19 downto 0)));
    sramData <= (others => 'Z') when load else valM;

    ignoreJ2 <= jump;

    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            if not fetchStall then
                instruction <= fetchedInst;
                pc <= fetchedPC;
            end if;

            if opH = "10" and (not stall) and (not ignore) then
                tagM2 <= tagY;
                load2 <= opL(0) = '0';
                sramLoad <= opL(0) = '0';
                sramStore <= opL(0) = '1';
            else
                tagM2 <= "00000";
                load2 <= false;
                sramLoad <= false;
                sramStore <= false;
            end if;

            emitBase <= "00" & valX(31 downto 2);
            emitDisp <= immSigned;

            load1 <= load2;
            load <= load1;
            tagM1 <= tagM2;
            tagM <= tagM1;

            pipeValMTmp <= valY;
            emitValMTmp <= pipeValM;
            valM <= emitValM;

            ignoreJ1 <= ignoreJ2;

        end if;
    end process;

    opH <= instruction(31 downto 30);
    opL <= instruction(29 downto 26);

    tagX <= tag_t(instruction(25 downto 21));
    tagY <= tag_t(instruction(20 downto 16));
    tagZ <= tag_t(instruction(15 downto 11));
    imm <= instruction(15 downto 0);

    valX <= (others => '0') when tagX = "00000" else
            sramData when tagX = tagM and load else
            emitValA when tagX = emitTagA else
            valRegX;

    valY <= (others => '0') when tagY = "00000" else
            sramData when tagY = tagM and load else
            emitValA when tagY = emitTagA else
            valRegY;

    pipeValM <= (others => '0') when tagM2 = "00000" else
                sramData when tagM2 = tagM and load else
                pipeValMTmp;

    emitValM <= (others => '0') when tagM1 = "00000" else
                sramData when tagM1 = tagM and load else
                emitValMTmp;

    stallX <= tagX /= "00000" and
              ((tagX = tagM2 and load2) or (tagX = tagM1 and load1)) ;
    stallY <= tagY /= "00000" and
              ((tagY = tagM2 and load2) or (tagY = tagM1 and load1)) and
              ((opH = "01" and opL(2 downto 1) = "00") or (opH = "11"));

    stall <= stallX or stallY or blocking;
    ignore <= ignoreJ1 or ignoreJ2;

end DataPathImp;
