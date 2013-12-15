library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity Fetch is
    port (
        clk : in std_logic;
        d : in fetch_in_t;
        q : out fetch_out_t);
end Fetch;

architecture twoproc of Fetch is
    component BlkRAM is
        port (
            clk : in std_logic;
            addr : in blkram_addr;
            inst : out instruction_t := (others => '0');
            we : in boolean;
            waddr : in blkram_addr;
            winst : in instruction_t);
    end component;

    component Predict is
        port (
            clk : in std_logic;
            d : in predict_in_t;
            q : in predict_out_t);
    end component;

    signal pc, pci : blkram_addr := (others => '0');
    signal dp : predict_in_t := (
        pc => (others => '0'),
        inst => (others => '0'),
        target => (others => '0'),
        enable => false);
    signal qp : predict_out_t;

    signal inst : instruction_t;

begin
    blkram_map : BlkRAM port map (
        clk => clk,
        addr => pc,
        inst => inst,
        we => d.we,
        waddr => d.waddr,
        winst => d.winst);

    predict_map : Predict port map (
        clk => clk,
        d => dp,
        q => qp);

    sequential : process(clk)
    begin
        if rising_edge(clk) then
            pci <= pc;
        end if;
    end process;

    combinatorial : process(d, qp, pci, inst)
        variable pc_inc : blkram_addr;

    begin
        pc_inc := blkram_addr(unsigned(pci) + 1);
        dp.pc <= pc_inc;
        dp.inst <= inst;
        dp.target <= d.addr;
        dp.enable <= not d.stall;

        q.jump <= not qp.succeed;
        q.pc <= pc_inc;
        q.inst <= inst;
        if d.stall then
            pc <= pci;
        else
            pc <= qp.addr;
        end if;
    end process;

end twoproc;
