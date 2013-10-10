library ieee;
use ieee.std_logic_1164.all;

library cpuex;
use cpuex.types.all;

entity DataPath is
    port (
        clk : in std_logic;
        halt : in boolean;

        fetched : in instruction;

        sramLoad : out std_logic;
        sramStore : out std_logic;

        serialOk : out std_logic;
        serialGo : out std_logic;
        serialRecvData : in std_logic_vector(7 downto 0);
        serialSendData : out std_logic_vector(7 downto 0));
end DataPath;

architecture DataPathImp of DataPath is
    component Fetch is
        port (
            clk : in std_logic;

            jump : in boolean;
            jumpAddr : in blkram_addr

            instruction : out instruction);
    end component;

    component RegSet is
        port (
            clk : in std_logic;

            tagS : in std_logic_vector(4 downto 0);
            tagT : in std_logic_vector(4 downto 0);
            tagD : in std_logic_vector(4 downto 0);

            delayD : in schedule;

            valS : out value;
            valT : out value;

            scheduleS : out schedule;
            scheduleT : out schedule;
            scheduleD : out schedule;

            writtenLine : in value;
            storeLine : out value);
    end component;

    component ALU is
        port (
            enable : in std_logic;
            code : in std_logic_vector(3 downto 0);

            opS : in value;
            opT : in value;

            outLine : out value);
    end component;

    component Mem is
        port (
            clk : in std_logic;

            enable : in std_logic;
            code : in std_logic_vector(2 downto 0);

            base : in value;
            disp : in std_logic(15 downto 0);

            loadLine : in value;
            storeLine : out value);
    end component;

    component Branch is
        port (
            clk : in std_logic;

            enable : in std_logic;
            code : in std_logic_vector(3 downto 0);

            opA : in value;
            opB : in value;
            addr : in sram_addr;

            PCLine : out blkram_addr;
            result : out std_logic);
    end component;

    signal instruction : instruction;
    signal jump : boolean;
    signal jumpAddr : blkram_addr;
    signal PCLine : blkram_addr;

    signal isOp : boolean;
    signal isMem : boolean;
    signal isBranch : boolean;
    signal isJumpOrSpecial : boolean;
    signal isFP : boolean;

    signal opcode : std_logic_vector(5 downto 0);
    signal opFunction : std_logic_vector(6 downto 0);
    signal delayTmp : std_logic_vector(7 downto 0);
    signal delay : std_logic_vector(7 downto 0);

    signal tagA : std_logic_vector(5 downto 0);
    signal tagB : std_logic_vector(5 downto 0);
    signal tagC : std_logic_vector(5 downto 0);
    signal noTagB : boolean;

    signal valA : value;
    signal valB : value;
    signal valBReg : value;
    signal valBShortImm : value;
    signal valBLongImm : value;

    signal scheduleA : schedule;
    signal scheduleB : schedule;
    signal scheduleC : schedule;

    signal writeLine;
    signal storeLine;

begin
    regSet : RegSet port map (
        clk => clk,
        tagS => tagA,
        tagT => tagB,
        tagD => tagC
        delayD => delay;
        valS => valA,
        valT => valBReg,
        scheduleS => scheduleA,
        scheduleT => scheduleB,
        scheduleD => scheduleC,
        writtenLine => writeLine,
        storeLine => storeLine);

    fetch : Fetch port map (
        clk => clk,
        jump => jump,
        jumpAddr => PCLine,
        instruction => instruction);

    alu : ALU port map (
        clk => clk,
        enable => isOp and (not isFP) and (not stall),
        code => opcode(1 downto 0) & opFunction(1 downto 0),
        opS => valA,
        opT => valB,
        outLine => writeLine);

    mem : Mem port map (
        clk => clk,
        enable => isMem and (not stall),
        code => opcode(3 downto 0) & opFunction(1 downto 0);

                      )

    branch : Branch port map (
        clk => clk,
        enable => isBranch,
        code => opcode(3 downto 0),
        opA => valA,
        opT => valB,
        addr => jumpAddr,
        PCLine => PCLine,
        result => jump);

    everyClock : process(clk)
    begin
        if rising_edge(clk) then
            if not stall then
                instruction <= fetched;
            end if;
        end if;
    end process;

    opcode <= instruction(31 dwonto 26);
    isOp <= opcode(5 downto 4) = "00";
    isMem <= opcode(5 downto 4) = "01";
    isBranch <= opcode(5 downto 4) = "10";
    isJumpOrSpecial <= opcode(5 downto 4) = "11";
    isFP <= opcode(3) = '1';

    tagA <= instruction(25 downto 21);
    tagB <= instruction(20 downto 16);
    tagC <= "11111" when isJumpOrSpecial else
            instruction(4 downto 0);

    -- using shifter is better?
    with opFunction(6 downto 4) select
        delayTmp <= "00000001" when "000",
                 <= "00000010" when "001",
                 <= "00000100" when "010",
                 <= "00001000" when "011",
                 <= "00010000" when "100",
                 <= "00100000" when "101",
                 <= "01000000" when "110",
                 <= "10000000" when "111";

    delay <= delayTmp when isOp else
             "00000100" when isMem else
             "00000000";

    noTagB <= (isOp and (opCode(2) ='1' or instruction(12) = '1')) or isJumpOrSpecial;

    stall <= halt or
             scheduleS /= 0 or
             ((not noTagB) and scheduleT /= 0) or
             (delay and scheduleD) /= 0;

    jumpAddr <= valA(15 downto 0) or instruction(15 downto 0) when isJumpOrSpecial else
                valA(15 downto 0);

end DataPathImp;
