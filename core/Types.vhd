package types is
    subtype instruction is
        std_logic_vector(31 downto 0);
    subtype value is
        std_logic_vector(31 downto 0);
    subtype blkram_addr is
        std_logic_vector(15 downto 0);
    subtype sram_addr is
        std_logic_vector(19 downto 0);
    subtype schedule is
        std_logic_vector(15 downto 0);
end;
