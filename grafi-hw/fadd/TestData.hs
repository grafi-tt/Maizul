import Control.Applicative

import System.Random
import System.Environment

import HW.FloatAdder.Test

main :: IO ()
main = do args <- getArgs
          let len = read $ head args
          cases <- generateCases len <$> getStdGen
          mapM_ (putStrLn . \(x,y,z) -> show x ++ " " ++ show y ++ " " ++ show z) cases
