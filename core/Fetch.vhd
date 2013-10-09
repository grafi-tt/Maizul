library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Fetch is
    port (
        clk : in std_logic;

        jump : in std_logic;
        jumpAddr : in std_logic_vector(15 downto 0);
    );
end Fetch;

architecture Implementation of Fetch is
    signal pc : std_logic_vector(15 downto 0);
    signal pcInc : std_logic;

begin
    begin
        if rising_edge(clk) then
            pcInc <= pc + 1;
        end if;

        pc <= pcInc when jump == '0'
              jumpAddr when others;

    end process;

end Implementation;
