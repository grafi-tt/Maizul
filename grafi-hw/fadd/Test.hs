{-# LANGUAGE FlexibleContexts #-}

module HW.FloatAdder.Test where

import Control.Applicative
import Control.Arrow
import Control.Monad

import Data.Word (Word32, Word64)
import Data.Array.ST (newArray, castSTUArray, readArray, MArray, STUArray)
import GHC.ST (runST, ST)

import System.Random
import Test.QuickCheck
import Test.QuickCheck.Gen(unGen)

import HW.FloatAdder

newtype Bits32 = Bits32 { unwrap32 :: [Bool] }
               deriving (Eq)
instance Show Bits32 where
  show = map (\b -> if b then '1' else '0') . unwrap32
instance Arbitrary Bits32 where
  arbitrary = Bits32 <$> suchThat (vector 32) (\xs -> all not xs || any id (take 8 $ tail xs) && any not (take 8 $ tail xs))

newtype Bits24 = Bits24 { unwrap24 :: [Bool] }
               deriving (Eq)
instance Show Bits24 where
  show = map (\b -> if b then '1' else '0') . unwrap24
instance Arbitrary Bits24 where
  arbitrary = Bits24 <$> (vector 24 :: Gen [Bool])

newtype Bits8 = Bits8 { unwrap8 :: [Bool] }
              deriving (Eq)
instance Show Bits8 where
  show = map (\b -> if b then '1' else '0') . unwrap8
instance Arbitrary Bits8 where
  arbitrary = Bits8 <$> (vector 8 :: Gen [Bool])

newtype Bits5 = Bits5 { unwrap5 :: [Bool] }
              deriving (Eq)
instance Show Bits5 where
  show = map (\b -> if b then '1' else '0') . unwrap5
instance Arbitrary Bits5 where
  arbitrary = Bits5 <$> (vector 5 :: Gen [Bool])

-- float conversion is taken from <http://stackoverflow.com/questions/6976684/converting-ieee-754-floating-point-in-haskell-word32-64-to-and-from-haskell-floa>
wordToFloat :: Word32 -> Float
wordToFloat x = runST (cast x)

floatToWord :: Float -> Word32
floatToWord x = runST (cast x)

wordToDouble :: Word64 -> Double
wordToDouble x = runST (cast x)

doubleToWord :: Double -> Word64
doubleToWord x = runST (cast x)

{-# INLINE cast #-}
cast :: (MArray (STUArray s) a (ST s),
         MArray (STUArray s) b (ST s)) => a -> ST s b
cast x = newArray (0 :: Int, 0) x >>= castSTUArray >>= flip readArray 0


toList :: Int -> Int -> [Bool]
toList = toList' []
  where
    toList' xs 0 _ = xs
    toList' xs len 0 = toList' (False:xs) (len-1) 0
    toList' xs len n = toList' ((n`mod`2 == 1):xs) (len-1) (n`div`2)

fromList :: [Bool] -> Int
fromList = foldl (\n b -> n*2 + (if b then 1 else 0)) 0


fakeAdder :: Int -> Bool -> [Bool] -> [Bool] -> (Bool, [Bool])
fakeAdder n cin xs ys = (head &&& tail)
                      $ toList (n+1) (fromList xs + fromList ys + if cin then 1 else 0)


fakeAdder8 :: Bool -> Bits8 -> Bits8 -> (Bool, Bits8)
fakeAdder8 cin (Bits8 xs) (Bits8 ys) = (id *** Bits8) $ fakeAdder 8 cin xs ys

fakeAdder24 :: Bool -> Bits24 -> Bits24 -> (Bool, Bits24)
fakeAdder24 cin (Bits24 xs) (Bits24 ys) = (id *** Bits24) $ fakeAdder 24 cin xs ys

fakeLeftShifter24 :: Bits5 -> Bits24 -> Bits24
fakeLeftShifter24 (Bits5 sft) (Bits24 xs) = Bits24 $ drop n xs ++ replicate n False
  where n = min 24 $ fromList sft

fakeRightShifter24 :: Bool -> Bits5 -> Bits24 -> ShiftResult
fakeRightShifter24 fout (Bits5 sft) (Bits24 xs) =
  SR (take 24 $ drop 8 $ replicate n False ++ take (32-n) xs')
     (head $ drop (32-n) xs')
     (head . tail $ drop (32-n) xs')
     (all not $ tail . tail $ drop (32-n) xs')
  where n = fromList sft
        xs' = replicate 8 False ++ xs ++ [fout, False]

fakeCLZ24 :: Bits24 -> Bits5
fakeCLZ24 = Bits5 . toList 5 . length . takeWhile not . unwrap24

fakefadd :: Bits32 -> Bits32 -> Bits32
fakefadd x y = fromFloat $ (toFloat x) + (toFloat y)
  where toFloat = wordToFloat . fromIntegral . fromList . unwrap32
        fromFloat = Bits32 . killDenormal . toList 32 . fromIntegral . floatToWord
        killDenormal xs = if all not (take 8 $ tail xs) then head xs : replicate 31 False else xs



addExponentTest :: Bool -> Bits8 -> Bits8 -> (Bool, Bits8)
addExponentTest cin (Bits8 xs) (Bits8 ys) = (id *** Bits8) $ addExponent cin xs ys

addFractionTest :: Bool -> Bits24 -> Bits24 -> (Bool, Bits24)
addFractionTest cin (Bits24 xs) (Bits24 ys) = (id *** Bits24) $ addFraction cin xs ys

shiftLeftFractionTest :: Bits5 -> Bits24 -> Bits24
shiftLeftFractionTest (Bits5 sft) (Bits24 xs) = Bits24 $ shiftLeftFraction sft xs

shiftRightFractionTest :: Bool -> Bits5 -> Bits24 -> ShiftResult
shiftRightFractionTest fout (Bits5 sft) (Bits24 xs) = shiftRightFraction fout sft xs

countLeadingZeroTest :: Bits24 -> Bits5
countLeadingZeroTest = Bits5 . countLeadingZero . unwrap24

faddTest :: Bits32 -> Bits32 -> Bits32
faddTest (Bits32 xs) (Bits32 ys) = Bits32 $ fadd xs ys



prop_AddFraction cin xs24 ys24 =
  addFractionTest cin xs24 ys24 == fakeAdder24 cin xs24 ys24

prop_AddExponent cin xs8 ys8 =
  addExponentTest cin xs8 ys8 == fakeAdder8 cin xs8 ys8

prop_ShiftLeftFraction sft xs =
  shiftLeftFractionTest sft xs == fakeLeftShifter24 sft xs

prop_ShiftRightFraction fout sft xs =
  shiftRightFractionTest fout sft xs == fakeRightShifter24 fout sft xs

prop_CountLeadingZero xs =
 countLeadingZeroTest xs == fakeCLZ24 xs

prop_fadd x y =
 faddTest x y == fakefadd x y


generateCases :: Int -> StdGen -> [(Bits32, Bits32, Bits32)]
generateCases n g =
  let (g1, g2) = split g
      input1 = unGen (vector n) g1 42
      input2 = unGen (vector n) g2 42
      output = zipWith fakefadd input1 input2
  in  zip3 input1 input2 output
