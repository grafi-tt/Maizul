{-# LANGUAGE QuasiQuotes #-}

import Heredoc
import Control.Monad (forM_)
import Data.Char (intToDigit)
import Numeric (showIntAtBase)

import Control.Applicative

main = do
  dat <- lines <$> getContents

  putStr [heredoc|s
    library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.types.all;

    entity BlkRAM is
        port (
            clk : in std_logic;
            addr : in blkram_addr;
            inst : out instruction_t := (others => '0');
            we : in boolean;
            waddr : in blkram_addr;
            winst : in instruction_t);
    end entity;

    architecture instance of BlkRAM is
        type blkram_t is array (0 to 1023) of instruction_t;
        signal RAM : blkram_t := (
    |]

  let imm = showIntAtBase 2 intToDigit (1024 - length dat) ""
  putStrLn $ "        0 => \"0101000000000000" ++ replicate (16 - length imm) '0' ++ imm ++ "\","
  forM_ (zip dat [1024 - length dat ..]) (\(d, i) -> putStr $ "        " ++ show i ++ " => \"" ++ d ++ "\",\n")
  putStr "        others => (others => '0')"

  putStr [heredoc|s
    );
        attribute ram_style : string;
        attribute ram_style of RAM : signal is "block";

    begin
        everyClock : process(clk)
        begin
            if (rising_edge(clk)) then
                inst <= RAM(to_integer(unsigned(addr(9 downto 0))));
                if we then
                    RAM(to_integer(unsigned(waddr(9 downto 0)))) <= winst;
                end if;
            end if;
        end process;

    end instance;
    |]
