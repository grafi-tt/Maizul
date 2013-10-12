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
        sramStoreLine : out value_t;
        sramLoadLine : in value_t);
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

            opS : in value_t;
            opT : in value_t;

            outLine : out value_t);
    end component;

    component Mem is
        port (
            clk : in std_logic;

            enable : in boolean;
            code : in std_logic_vector(3 downto 0);

            base : in sram_addr;
            disp : in sram_addr;

            storeValue : in value_t;
            outLine : out value_t;

            loadLine : in value_t;
            storeLine : out value_t);
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

    signal instruction : instruction_t;
    signal fetched : instruction_t;
    signal pc : blkram_addr;
    signal fetchedPC : blkram_addr;
    signal jump : boolean;
    signal jumpAddr : blkram_addr;
    signal PCLine : blkram_addr;

    signal opcode : std_logic_vector(5 downto 0);
    signal opFunction : std_logic_vector(6 downto 0);
    signal delay : std_logic_vector(7 downto 0);
    signal writer : std_logic;

    signal aluCode : std_logic_vector(3 downto 0);

    signal isOp : boolean;
    signal isMem : boolean;
    signal isBranch : boolean;
    signal isJumpOrSpecial : boolean;
    signal isFP : boolean;
    signal isSpecial : boolean;

    signal aluEnable : boolean;
    signal fpuEnable : boolean;
    signal memEnable : boolean;
    signal branchEnable : boolean;
    signal ioEnable : boolean;

    signal tagA : std_logic_vector(4 downto 0);
    signal tagB : std_logic_vector(4 downto 0);
    signal tagC : std_logic_vector(4 downto 0);
    signal noTagB : boolean;

    signal displacement : blkram_addr;
    signal sramDisplacement : sram_addr;

    signal valA : value_t;
    signal valB : value_t;
    signal valBReg : value_t;
    signal valBShortImm : value_t;
    signal valBLongImm : value_t;

    signal scheduleA : schedule_t;
    signal scheduleB : schedule_t;

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
        blocking => blocking,
        tagS => tagA,
        tagT => tagB,
        tagD => tagC,
        delayD => delay,
        writer => writer,
        valS => valA,
        valT => valBReg,
        scheduleS => scheduleA,
        scheduleT => scheduleB,
        writeLineA => unifiedLine,
        writeLineB => memLine);
    unifiedLine <= aluLine or branchLine or ioLine;

    fetch_map : Fetch port map (
        clk => clk,
        stall => stall,
        jump => jump,
        jumpAddr => PCLine,
        pc => pc,
        instruction => fetched);

    alu_map : ALU port map (
        clk => clk,
        enable => aluEnable,
        code => aluCode,
        opS => valA,
        opT => valB,
        outLine => aluLine);
    aluCode <= opcode(1 downto 0) & opFunction(1 downto 0);
    aluEnable <= isOp and (not isFP) and (not stall);

    mem_map : Mem port map (
        clk => clk,
        enable => memEnable,
        code => opcode(3 downto 0),
        base => sram_addr(valBReg(19 downto 0)),
        disp => sramDisplacement,
        storeValue => valA,
        outLine => memLine,
        loadLine => sramLoadLine,
        storeLine => sramStoreLine);
    memEnable <= isMem and (not stall);

    branch_map : Branch port map (
        clk => clk,
        enable => branchEnable,
        code => opcode(3 downto 0),
        opA => valA,
        opB => valB,
        addr => jumpAddr,
        PCLine => PCLine,
        result => jump);
    branchEnable <= (isBranch or (isJumpOrSpecial and (not isSpecial))) and (not stall);

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
    ioEnable <= isJumpOrSpecial and isSpecial and (not stall);

    every_clock_do : process(clk)
    begin
        if rising_edge(clk) then
            if not stall then
                instruction <= fetched;
                pc <= fetchedPC;
            end if;
        end if;
    end process;

    opcode <= instruction(31 downto 26);
    isOp <= opcode(5 downto 4) = "00";
    isMem <= opcode(5 downto 4) = "01";
    isBranch <= opcode(5 downto 4) = "10";
    isJumpOrSpecial <= opcode(5 downto 4) = "11";
    isFP <= opcode(3) = '1';
    isSpecial <= opcode(2) = '1';
    writer <= '1' when isMem else '0';

    tagA <= instruction(25 downto 21);
    tagB <= instruction(20 downto 16);
    tagC <= "11111" when isJumpOrSpecial else
            instruction(4 downto 0);

    displacement <= blkram_addr(instruction(15 downto 0));
    sramDisplacement <= sram_addr("0000" & instruction(15 downto 0));

    valB <= valBLongImm when opcode(2) = '1' else
            valBShortImm when instruction(12) = '1' else
            valBReg;

    delay <= "00000001" when isOp and (not isFP) else
             "00000111" when isMem else
             "00000000";

    noTagB <= (isOp and (opCode(2) ='1' or instruction(12) = '1')) or isJumpOrSpecial;

    stall <= halt or
             blocking or
             scheduleA(0) /= '0' or
             ((not noTagB) and scheduleB(0) /= '1');

    jumpAddr <= blkram_addr(valA(15 downto 0) or std_logic_vector(displacement)) when isJumpOrSpecial else
                displacement;

end DataPathImp;
