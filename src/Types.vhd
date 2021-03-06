library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is
    subtype instruction_t is
        std_logic_vector(31 downto 0);
    subtype value_t is
        std_logic_vector(31 downto 0);
    subtype tag_t is
        std_logic_vector(4 downto 0);
    subtype blkram_addr is
        unsigned(15 downto 0);
    subtype sram_addr is
        unsigned(19 downto 0);

    type blkram_write_t is record
        enable : boolean;
        addr : blkram_addr;
        inst : instruction_t;
    end record;

    type branch_in_t is record
        code : std_logic_vector(2 downto 0);
        tag_l : tag_t;
        val_a : value_t;
        val_b : value_t;
        val_l : blkram_addr;
        val_t : blkram_addr;
    end record;

    type branch_out_t is record
        emit_tag : tag_t;
        emit_link : blkram_addr;
        emit_target : blkram_addr;
    end record;

    type fetch_in_t is record
        enable_fetch : boolean;
        enable_addr : boolean;
        addr : blkram_addr;
        w : blkram_write_t;
    end record;

    type fetch_out_t is record
        jump : boolean;
        pc : blkram_addr;
        inst : instruction_t;
    end record;

    type predict_in_t is record
        pc : blkram_addr;
        inst : instruction_t;
        target : blkram_addr;
        enable_fetch : boolean;
        enable_target : boolean;
    end record;

    type predict_out_t is record
        addr : blkram_addr;
        succeed : boolean;
    end record;

    type u232c_in_t is record
        send_data : std_logic_vector(7 downto 0);
        ok : std_logic;
        go : std_logic;
    end record;

    type u232c_out_t is record
        recv_data : std_logic_vector(7 downto 0);
        recf : std_logic;
        sent : std_logic;
    end record;
end;
