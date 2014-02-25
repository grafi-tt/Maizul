module Heredoc (
  heredoc
) where

import Data.Char (isSpace)
import Language.Haskell.TH.Quote
import Language.Haskell.TH.Syntax

data HeredocOpt = Default | Indent Char

heredoc :: QuasiQuoter
heredoc = QuasiQuoter
  { quoteExp = return . LitE . StringL . readHeredoc
  , quotePat = return . LitP . StringL . readHeredoc
  , quoteType = error "here document appears in the context of types"
  , quoteDec = error "here document appears in the context of delarations."
  }

readHeredoc :: String -> String
readHeredoc = runFormat . lines
  where
    runFormat (opt:ls) = format (readOpt opt) ls
    runFormat [] = error "no newline character for here document"

readOpt :: String -> HeredocOpt
readOpt optStr = case filter (not . isSpace) optStr of
  "s" -> Indent ' '
  "t" -> Indent '\t'
  ""  -> Default
  _   -> error "invalid option for here document"

format :: HeredocOpt -> [String] -> String
format Default  = unlines
format (Indent c) = unlines . trim c

trim :: Char -> [String] -> [String]
trim c [] = []
trim c ls =
  let cnt = minimum . map (length . takeWhile (== c)) . filter (not . null) $ ls
  in  chomp . map (drop cnt) $ ls
    where
      chomp ls | null (last ls) = init ls
               | otherwise = ls
