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
            w : in blkram_write_t);
    end entity;

    architecture behavioral of BlkRAM is
        type blkram_t is array (0 to 16383) of instruction_t;
        signal RAM : blkram_t := (
    |]

  let imm = showIntAtBase 2 intToDigit (16384 - length dat) ""
  putStrLn $ "        0 => \"0101000000000000" ++ replicate (16 - length imm) '0' ++ imm ++ "\","
  forM_ (zip dat [16384 - length dat ..]) (\(d, i) -> putStr $ "        " ++ show i ++ " => \"" ++ d ++ "\",\n")
  putStr "        others => (others => '0')"

  putStr [heredoc|s
    );
        attribute ram_style : string;
        attribute ram_style of RAM : signal is "block";

    begin
        blk : process(clk)
        begin
            if rising_edge(clk) then
                inst <= RAM(to_integer(unsigned(addr(13 downto 0))));
                if w.enable then
                    RAM(to_integer(unsigned(w.addr(13 downto 0)))) <= w.inst;
                end if;
            end if;
        end process;

    end behavioral;
    |]
