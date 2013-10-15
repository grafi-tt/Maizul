library ieee;
use ieee.std_logic_1164.all;
use work.types.all;

entity DataPath is
    port (
        clk : in std_logic;
        halt : in boolean;

        serialOk : buffer std_logic;
        serialGo : buffer std_logic;
        serialRecvData : in std_logic_vector(7 downto 0);
        serialSendData : out std_logic_vector(7 downto 0);
        serialRecved : in std_logic;
        serialSent : in std_logic;

        sramLoad : out std_logic;
        sramStore : out std_logic;
        sramAddr : out sram_addr;
        sramDataLine : inout value_t);
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
            blocking : in boolean;

            tagS : in std_logic_vector(4 downto 0);
            tagT : in std_logic_vector(4 downto 0);
            tagD : in std_logic_vector(4 downto 0);

            delayD : in schedule_t;
            writer : in std_logic;

            valS : out value_t;
            valT : out value_t;

            scheduleS : out schedule_t;
            scheduleT : out schedule_t;

            writeLineA : in value_t;
            writeLineB : in value_t);
    end component;

    component ALU is
        port (
            clk : in std_logic;
            enable : in boolean;
            code : in std_logic_vector(3 downto 0);
            tagD : in tag_t;
            valA : in value_t;
            valB : in value_t;
            emitEnable : out boolean;
            emitTag : out tag_t;
            emitVal : out value_t);
    end component;

    component Branch is
        port (
            clk : in std_logic;

            enable : in boolean;
            code : in std_logic_vector(3 downto 0);

            opA : in value_t;
            opB : in value_t;
            addr : in blkram_addr;

            outLine : out value_t;
            PCLine : out blkram_addr;
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

            putVal : in value_t;
            getLine : out value_t;
            blocking : out boolean);
    end component;

    signal fetched : instruction_t;
    signal pc : blkram_addr;
    signal fetchedPC : blkram_addr;
    signal jump : boolean;
    signal jumpAddr : blkram_addr;
    signal PCLine : blkram_addr;

    signal instruction : instruction_t;

    signal opH : std_logic_vector(1 downto 0);
    signal opL : std_logic_vector(3 downto 0);
    signal opLL : std_logic_vector(2 downto 0);

    signal tagX : tag_t;
    signal tagY : tag_t;
    signal tagZ : tag_t;
    signal imm : std_logic_vector(15 downto 0);

    signal valY : value_t;
    signal valRegY : value_t;
    signal valZ : value_t;
    signal valRegZ : value_t;

    signal enableA : boolean;
    signal enableF : boolean;
    signal enableM : boolean;
    signal enableB : boolean;
    signal enableIO : boolean;

    signal pipeTagA : tag_t;
    signal pipeEnableA : boolean;
    signal emitTagA : tag_t;
    signal emitValA : value_t;

    signal target : blkram_addr;
    signal disp : sram_addr;

    signal stallY : boolean;
    signal fowardY : boolean;

    signal aluLine : value_t;
    signal branchLine : value_t;
    signal ioLine : value_t;
    signal memLine : value_t;
    signal unifiedLine : value_t;

    signal stall : boolean;
    signal blocking : boolean;

begin
    reg_set_map : RegSet port map (
        clk => clk,
        tagS => tagY,
        valS => valY,
        tagT => tagZ,
        valT => valRegZ,
        tagW => tagW,
        lineW => valW,
        tagM => emitTagM,
        modeM => modeM,
        lineM => lineM);
    tagW <= emitTagA when emitEnableA else
            emitTagB when emitEnableB else
            emitTagIO when emitEnableIO else
            (others => '0');
    valW <= emitValA when emitEnableA else
            emitValB when emitEnableB else
            emitValIO when emitEnableIO else
            (others => '0');

    fetch_map : Fetch port map (
        clk => clk,
        stall => stall,
        jump => jump,
        jumpAddr => PCLine,
        pc => pc,
        instruction => fetched);

    alu_map : ALU port map (
        clk => clk,
        enable => enableA,
        code => codeA,
        tagD => tagX,
        valA => valY,
        valB => valZ,
        emitEnable => emitEnableA;
        emitTag => emitTagA;
        emitVal => emitValA);
    enableA <= (opH = "00" or (opH = "01" and opLL = "000")) and (not stall);
    codeA <= instruction(29 downto 26) when op00 else
             instruction(3 downto 0);

    branch_map : Branch port map (
        clk => clk,
        enable => branchEnable,
        code => opL,
        opA => valA,
        opB => valB,
        target => jumpAddr,
        PCLine => PCLine,
        result => jump);
    enableB <= (opH = "11" or (opH = "01" and opLL = "001")) and (not stall);
    target <= blkram_addr(imm);

    io_map : IO port map(
        clk => clk,
        enable => ioEnable,
        code => instruction(5),
        serialOk => serialOk,
        serialGo => serialGo,
        serialRecvData => serialRecvData,
        serialSendData => serialSendData,
        serialRecved => serialRecved,
        serialSent => serialSent,
        putVal => valA,
        getLine => ioLine,
        blocking => blocking);
    enableIO <= (opH = "01" and (opL = "0100" or opL = "1101")) and (not stall);

    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            if not stall then
                instruction <= fetched;
                pc <= fetchedPC;
            end if;

            sramAddr <= sram_addr(unsigned(base) + unsigned(disp));
            sramLoad <= (not mode) and enable;
            sramStore <= mode and enable;

            load1 <= sramLoad;
            load <= load1;

            tagM2 <= tagM3;
            tagM1 <= tagM2;
            tagM <= tagM1;

            pipeValMTmp <= valX;
            emitValMTmp <= pipeValM;

        end if;
    end process;

    sramDataLine <= (others => 'Z') when load == '1' else emitValM;

    opH <= instruction(31 downto 30);
    opL <= instruction(29 downto 26);
    opLL <= instruction(28 downto 26);

    isFP <= opcode(3) = '1';

    tagX <= tag_t(instruction(25 downto 21));
    tagY <= tag_t(instruction(20 downto 16));
    tagZ <= tag_t(instruction(15 downto 10));
    imm <= tag_t(instruction(15 downto 0));

    -- TODO: eliminate copy-and-paste
    valY <= (others => '0') when tagY = "00000" else
            sramDataLine when tagY = tagM and load = '1' else
            valAlu when tagY = tagAlu else
            valRegY;

    valZ <= x"0000" & imm when opcode(0 downto 1) /= "01" or opcode(3 downto 4) /= "00" else
            (others => '0') when tagZ = "00000" else
            sramDataLine when tagZ = tagM and load = '1' else
            valAlu when tagZ = tagAlu else
            valRegZ;

    pipeValM <= (others => '0') when tagM2 = "00000" else
                sramDataLine when tagM2 = tagM and load = '1' else
                valAlu when tagM2 = tagAlu else
                valRegY;

    emitValM <= (others => '0') when tagM1 = "00000" else
                sramDataLine when tagM1 = tagM and load = '1' else
                valAlu when tagM1 = tagAlu else
                valRegY;

    stall <= halt or
             blocking or
             scheduleA(0) /= '0' or
             ((not noTagB) and scheduleB(0) /= '1');

end DataPathImp;
