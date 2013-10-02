module HW.FloatAdder where

-- 整数の加算器自体はKogge-Stone Adderで実装

data PG = PG
  { propagate :: Bool
  , generate :: Bool
  } deriving (Show, Eq)

data ShiftResult = SR
  { shifted :: [Bool]
  , fstOut :: Bool
  , sndOut :: Bool
  , tailNil :: Bool
  } deriving (Show, Eq)

addHalf :: Bool -> Bool -> PG
addHalf x y = PG (x /= y) (x && y)

addFull :: Bool -> Bool -> Bool -> PG
addFull x y z = PG  (x /= (y /= z)) ((x && y) || (y && z) || (z && x))

mergePG :: PG -> PG -> PG
mergePG (PG p g) (PG q h) = PG (p && q) ((p && h) || g)


addExponent :: Bool -> [Bool] -> [Bool] -> (Bool, [Bool])
addExponent cin [x0,x1,x2,x3,x4,x5,x6,x7]
                [y0,y1,y2,y3,y4,y5,y6,y7]
  = (cout, s)
  where
    pg00 = addHalf x0 y0
    pg11 = addHalf x1 y1
    pg22 = addHalf x2 y2
    pg33 = addHalf x3 y3
    pg44 = addHalf x4 y4
    pg55 = addHalf x5 y5
    pg66 = addHalf x6 y6
    pg77 = addFull x7 y7 cin

    pg01 = mergePG pg00 pg11
    pg12 = mergePG pg11 pg22
    pg23 = mergePG pg22 pg33
    pg34 = mergePG pg33 pg44
    pg45 = mergePG pg44 pg55
    pg56 = mergePG pg55 pg66
    pg67 = mergePG pg66 pg77

    pg03 = mergePG pg01 pg23
    pg14 = mergePG pg12 pg34
    pg25 = mergePG pg23 pg45
    pg36 = mergePG pg34 pg56
    pg47 = mergePG pg45 pg67
    pg57 = mergePG pg56 pg77

    pg07 = mergePG pg03 pg47
    pg17 = mergePG pg14 pg57
    pg27 = mergePG pg25 pg67
    pg37 = mergePG pg36 pg77

    cout = generate pg07
    s0 = propagate pg00 /= generate pg17
    s1 = propagate pg11 /= generate pg27
    s2 = propagate pg22 /= generate pg37
    s3 = propagate pg33 /= generate pg47
    s4 = propagate pg44 /= generate pg57
    s5 = propagate pg55 /= generate pg67
    s6 = propagate pg66 /= generate pg77
    s7 = propagate pg77

    s = [s0, s1, s2, s3,s4,s5,s6,s7]


shiftLeft n xs = drop n xs ++ replicate n False


shiftLeftFraction :: [Bool] -> [Bool] -> [Bool]
shiftLeftFraction [k0,k1,k2,k3,k4] xs
  = xs01234
  where
    xs0 = if k0 then shiftLeft 16 xs else xs
    xs01 = if k1 then shiftLeft 8 xs0 else xs0
    xs012 = if k2 then shiftLeft 4 xs01 else xs01
    xs0123 = if k3 then shiftLeft 2 xs012 else xs012
    xs01234 = if k4 then shiftLeft 1 xs0123 else xs0123

shiftRightFraction :: Bool -> [Bool] -> [Bool] -> ShiftResult
shiftRightFraction fout [k0,k1,k2,k3,k4]
                   [x008,x009,x010,x011,x012,x013,x014,x015,x016,x017,x018,x019,x020,x021,x022,x023,x024,x025,x026,x027,x028,x029,x030,x031]
  = sr5
  where
    sr1 = if k0 then
            SR [False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,False,x008,x009,x010,x011,x012,x013,x014,x015]
               x016 x017
               $ (((not x018 && not x019)) && ((not x020 && not x021) && (not x022 && not x023)))
               &&(((not x024 && not x025) && (not x026 && not x027)) && ((not x028 && not x029) && (not x030 && not x031)))
          else
            SR [x008,x009,x010,x011,x012,x013,x014,x015,x016,x017,x018,x019,x020,x021,x022,x023,x024,x025,x026,x027,x028,x029,x030,x031]
               fout False True
    [x108,x109,x110,x111,x112,x113,x114,x115,x116,x117,x118,x119,x120,x121,x122,x123,x124,x125,x126,x127,x128,x129,x130,x131] = shifted sr1

    sr2 = if k1 then
            SR [False,False,False,False,False,False,False,False,x108,x109,x110,x111,x112,x113,x114,x115,x116,x117,x118,x119,x120,x121,x122,x123]
               x124 x125
               $ (((not (fstOut sr1) && not (sndOut sr1)) && (not x126 && not x127)) && ((not x128 && not x129) && (not x130 && not x131))) && tailNil sr1
          else
            sr1
    [x208,x209,x210,x211,x212,x213,x214,x215,x216,x217,x218,x219,x220,x221,x222,x223,x224,x225,x226,x227,x228,x229,x230,x231] = shifted sr2

    sr3 = if k2 then
            SR [False,False,False,False,x208,x209,x210,x211,x212,x213,x214,x215,x216,x217,x218,x219,x220,x221,x222,x223,x224,x225,x226,x227]
               x228 x229
               $ ((not (fstOut sr2) && not (sndOut sr2)) && (not x230 && not x231)) && tailNil sr2
          else
            sr2
    [x308,x309,x310,x311,x312,x313,x314,x315,x316,x317,x318,x319,x320,x321,x322,x323,x324,x325,x326,x327,x328,x329,x330,x331] = shifted sr3

    sr4 = if k3 then
            SR [False,False,x308,x309,x310,x311,x312,x313,x314,x315,x316,x317,x318,x319,x320,x321,x322,x323,x324,x325,x326,x327,x328,x329]
               x330 x331
               $ (not (fstOut sr3) && not (sndOut sr3)) && tailNil sr3
          else
            sr3
    [x408,x409,x410,x411,x412,x413,x414,x415,x416,x417,x418,x419,x420,x421,x422,x423,x424,x425,x426,x427,x428,x429,x430,x431] = shifted sr4

    sr5 = if k4 then
            SR [False,x408,x409,x410,x411,x412,x413,x414,x415,x416,x417,x418,x419,x420,x421,x422,x423,x424,x425,x426,x427,x428,x429,x430]
               x431 (fstOut sr4)
               $ not (sndOut sr4) && tailNil sr4
          else
            sr4

addFraction :: Bool -> [Bool] -> [Bool] -> (Bool, [Bool])
addFraction cin [x08,x09,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31]
                [y08,y09,y10,y11,y12,y13,y14,y15,y16,y17,y18,y19,y20,y21,y22,y23,y24,y25,y26,y27,y28,y29,y30,y31]
  = (cout, [s08,s09,s10,s11,s12,s13,s14,s15,s16,s17,s18,s19,s20,s21,s22,s23,s24,s25,s26,s27,s28,s29,s30,s31])
  where
    pg0808 = addHalf x08 y08
    pg0909 = addHalf x09 y09
    pg1010 = addHalf x10 y10
    pg1111 = addHalf x11 y11
    pg1212 = addHalf x12 y12
    pg1313 = addHalf x13 y13
    pg1414 = addHalf x14 y14
    pg1515 = addHalf x15 y15
    pg1616 = addHalf x16 y16
    pg1717 = addHalf x17 y17
    pg1818 = addHalf x18 y18
    pg1919 = addHalf x19 y19
    pg2020 = addHalf x20 y20
    pg2121 = addHalf x21 y21
    pg2222 = addHalf x22 y22
    pg2323 = addHalf x23 y23
    pg2424 = addHalf x24 y24
    pg2525 = addHalf x25 y25
    pg2626 = addHalf x26 y26
    pg2727 = addHalf x27 y27
    pg2828 = addHalf x28 y28
    pg2929 = addHalf x29 y29
    pg3030 = addHalf x30 y30
    pg3131 = addFull x31 y31 cin

    pg0809 = mergePG pg0808 pg0909
    pg0910 = mergePG pg0909 pg1010
    pg1011 = mergePG pg1010 pg1111
    pg1112 = mergePG pg1111 pg1212
    pg1213 = mergePG pg1212 pg1313
    pg1314 = mergePG pg1313 pg1414
    pg1415 = mergePG pg1414 pg1515
    pg1516 = mergePG pg1515 pg1616
    pg1617 = mergePG pg1616 pg1717
    pg1718 = mergePG pg1717 pg1818
    pg1819 = mergePG pg1818 pg1919
    pg1920 = mergePG pg1919 pg2020
    pg2021 = mergePG pg2020 pg2121
    pg2122 = mergePG pg2121 pg2222
    pg2223 = mergePG pg2222 pg2323
    pg2324 = mergePG pg2323 pg2424
    pg2425 = mergePG pg2424 pg2525
    pg2526 = mergePG pg2525 pg2626
    pg2627 = mergePG pg2626 pg2727
    pg2728 = mergePG pg2727 pg2828
    pg2829 = mergePG pg2828 pg2929
    pg2930 = mergePG pg2929 pg3030
    pg3031 = mergePG pg3030 pg3131

    pg0811 = mergePG pg0809 pg1011
    pg0912 = mergePG pg0910 pg1112
    pg1013 = mergePG pg1011 pg1213
    pg1114 = mergePG pg1112 pg1314
    pg1215 = mergePG pg1213 pg1415
    pg1316 = mergePG pg1314 pg1516
    pg1417 = mergePG pg1415 pg1617
    pg1518 = mergePG pg1516 pg1718
    pg1619 = mergePG pg1617 pg1819
    pg1720 = mergePG pg1718 pg1920
    pg1821 = mergePG pg1819 pg2021
    pg1922 = mergePG pg1920 pg2122
    pg2023 = mergePG pg2021 pg2223
    pg2124 = mergePG pg2122 pg2324
    pg2225 = mergePG pg2223 pg2425
    pg2326 = mergePG pg2324 pg2526
    pg2427 = mergePG pg2425 pg2627
    pg2528 = mergePG pg2526 pg2728
    pg2629 = mergePG pg2627 pg2829
    pg2730 = mergePG pg2728 pg2930
    pg2831 = mergePG pg2829 pg3031
    pg2931 = mergePG pg2930 pg3131

    pg0815 = mergePG pg0811 pg1215
    pg0916 = mergePG pg0912 pg1316
    pg1017 = mergePG pg1013 pg1417
    pg1118 = mergePG pg1114 pg1518
    pg1219 = mergePG pg1215 pg1619
    pg1320 = mergePG pg1316 pg1720
    pg1421 = mergePG pg1417 pg1821
    pg1522 = mergePG pg1518 pg1922
    pg1623 = mergePG pg1619 pg2023
    pg1724 = mergePG pg1720 pg2124
    pg1825 = mergePG pg1821 pg2225
    pg1926 = mergePG pg1922 pg2326
    pg2027 = mergePG pg2023 pg2427
    pg2128 = mergePG pg2124 pg2528
    pg2229 = mergePG pg2225 pg2629
    pg2330 = mergePG pg2326 pg2730
    pg2431 = mergePG pg2427 pg2831
    pg2531 = mergePG pg2528 pg2931
    pg2631 = mergePG pg2629 pg3031
    pg2731 = mergePG pg2730 pg3131

    pg0823 = mergePG pg0815 pg1623
    pg0924 = mergePG pg0916 pg1724
    pg1025 = mergePG pg1017 pg1825
    pg1126 = mergePG pg1118 pg1926
    pg1227 = mergePG pg1219 pg2027
    pg1328 = mergePG pg1320 pg2128
    pg1429 = mergePG pg1421 pg2229
    pg1530 = mergePG pg1522 pg2330
    pg1631 = mergePG pg1623 pg2431
    pg1731 = mergePG pg1724 pg2531
    pg1831 = mergePG pg1825 pg2631
    pg1931 = mergePG pg1926 pg2731
    pg2031 = mergePG pg2027 pg2831
    pg2131 = mergePG pg2128 pg2931
    pg2231 = mergePG pg2229 pg3031
    pg2331 = mergePG pg2330 pg3131

    pg0831 = mergePG pg0823 pg2431
    pg0931 = mergePG pg0924 pg2531
    pg1031 = mergePG pg1025 pg2631
    pg1131 = mergePG pg1126 pg2731
    pg1231 = mergePG pg1227 pg2831
    pg1331 = mergePG pg1328 pg2931
    pg1431 = mergePG pg1429 pg3031
    pg1531 = mergePG pg1530 pg3131

    cout = generate pg0831
    s08 = propagate pg0808 /= generate pg0931
    s09 = propagate pg0909 /= generate pg1031
    s10 = propagate pg1010 /= generate pg1131
    s11 = propagate pg1111 /= generate pg1231
    s12 = propagate pg1212 /= generate pg1331
    s13 = propagate pg1313 /= generate pg1431
    s14 = propagate pg1414 /= generate pg1531
    s15 = propagate pg1515 /= generate pg1631
    s16 = propagate pg1616 /= generate pg1731
    s17 = propagate pg1717 /= generate pg1831
    s18 = propagate pg1818 /= generate pg1931
    s19 = propagate pg1919 /= generate pg2031
    s20 = propagate pg2020 /= generate pg2131
    s21 = propagate pg2121 /= generate pg2231
    s22 = propagate pg2222 /= generate pg2331
    s23 = propagate pg2323 /= generate pg2431
    s24 = propagate pg2424 /= generate pg2531
    s25 = propagate pg2525 /= generate pg2631
    s26 = propagate pg2626 /= generate pg2731
    s27 = propagate pg2727 /= generate pg2831
    s28 = propagate pg2828 /= generate pg2931
    s29 = propagate pg2929 /= generate pg3031
    s30 = propagate pg3030 /= generate pg3131
    s31 = propagate pg3131

countLeadingZero :: [Bool] -> [Bool]
countLeadingZero [x01,x02,x03,x04,x05,x06,x07,x08,x09,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,x21,x22,x23,x24]
  = cnt0124
  where
    cnt0101 = if x01 then [False,False,False,False,False] else [False,False,False,False,True ]
    cnt0202 = if x02 then [False,False,False,False,True ] else [False,False,False,True ,False]
    cnt0303 = if x03 then [False,False,False,True ,False] else [False,False,False,True ,True ]
    cnt0404 = if x04 then [False,False,False,True ,True ] else [False,False,True ,False,False]
    cnt0505 = if x05 then [False,False,True ,False,False] else [False,False,True ,False,True ]
    cnt0606 = if x06 then [False,False,True ,False,True ] else [False,False,True ,True ,False]
    cnt0707 = if x07 then [False,False,True ,True ,False] else [False,False,True ,True ,True ]
    cnt0808 = if x08 then [False,False,True ,True ,True ] else [False,True ,False,False,False]
    cnt0909 = if x09 then [False,True ,False,False,False] else [False,True ,False,False,True ]
    cnt1010 = if x10 then [False,True ,False,False,True ] else [False,True ,False,True ,False]
    cnt1111 = if x11 then [False,True ,False,True ,False] else [False,True ,False,True ,True ]
    cnt1212 = if x12 then [False,True ,False,True ,True ] else [False,True ,True ,False,False]
    cnt1313 = if x13 then [False,True ,True ,False,False] else [False,True ,True ,False,True ]
    cnt1414 = if x14 then [False,True ,True ,False,True ] else [False,True ,True ,True ,False]
    cnt1515 = if x15 then [False,True ,True ,True ,False] else [False,True ,True ,True ,True ]
    cnt1616 = if x16 then [False,True ,True ,True ,True ] else [True ,False,False,False,False]
    cnt1717 = if x17 then [True ,False,False,False,False] else [True ,False,False,False,True ]
    cnt1818 = if x18 then [True ,False,False,False,True ] else [True ,False,False,True ,False]
    cnt1919 = if x19 then [True ,False,False,True ,False] else [True ,False,False,True ,True ]
    cnt2020 = if x20 then [True ,False,False,True ,True ] else [True ,False,True ,False,False]
    cnt2121 = if x21 then [True ,False,True ,False,False] else [True ,False,True ,False,True ]
    cnt2222 = if x22 then [True ,False,True ,False,True ] else [True ,False,True ,True ,False]
    cnt2323 = if x23 then [True ,False,True ,True ,False] else [True ,False,True ,True ,True ]
    cnt2424 = if x24 then [True ,False,True ,True ,True ] else [True ,True ,False,False,False]

    cnt0102 = if (cnt0101 !! 4) then cnt0202 else cnt0101
    cnt0304 = if (cnt0303 !! 4) then cnt0404 else cnt0303
    cnt0506 = if (cnt0505 !! 4) then cnt0606 else cnt0505
    cnt0708 = if (cnt0707 !! 4) then cnt0808 else cnt0707
    cnt0910 = if (cnt0909 !! 4) then cnt1010 else cnt0909
    cnt1112 = if (cnt1111 !! 4) then cnt1212 else cnt1111
    cnt1314 = if (cnt1313 !! 4) then cnt1414 else cnt1313
    cnt1516 = if (cnt1515 !! 4) then cnt1616 else cnt1515
    cnt1718 = if (cnt1717 !! 4) then cnt1818 else cnt1717
    cnt1920 = if (cnt1919 !! 4) then cnt2020 else cnt1919
    cnt2122 = if (cnt2121 !! 4) then cnt2222 else cnt2121
    cnt2324 = if (cnt2323 !! 4) then cnt2424 else cnt2323

    cnt0104 = if (cnt0102 !! 3) then cnt0304 else cnt0102
    cnt0508 = if (cnt0506 !! 3) then cnt0708 else cnt0506
    cnt0912 = if (cnt0910 !! 3) then cnt1112 else cnt0910
    cnt1316 = if (cnt1314 !! 3) then cnt1516 else cnt1314
    cnt1720 = if (cnt1718 !! 3) then cnt1920 else cnt1718
    cnt2124 = if (cnt2122 !! 3) then cnt2324 else cnt2122

    cnt0108 = if (cnt0104 !! 2) then cnt0508 else cnt0104
    cnt0916 = if (cnt0912 !! 2) then cnt1316 else cnt0912
    cnt1724 = if (cnt1720 !! 2) then cnt2124 else cnt1720

    cnt0116 = if (cnt0108 !! 1) then cnt0916 else cnt0108

    cnt0124 = if (cnt0116 !! 0) then cnt1724 else cnt0116

isMaxExponent :: [Bool] -> Bool
isMaxExponent [e0,e1,e2,e3,e4,e5,e6,e7]
  = ((e0 && e1) && (e2 && e3)) && ((e4 && e5) && (e6 && e7))

isNonZeroExponent :: [Bool] -> Bool
isNonZeroExponent [e0,e1,e2,e3,e4,e5,e6,e7]
  = ((e0 || e1) || (e2 || e3)) || ((e4 || e5) || (e6 || e7))

splitFloat :: [Bool] -> (Bool, [Bool], [Bool])
splitFloat f = (head f, take 8 $ tail f, True : drop 8 (tail f))

mergeFloat :: (Bool, [Bool], [Bool]) -> [Bool]
mergeFloat (sgn, exp, frc) = sgn : (exp ++ tail frc)

addFloat :: (Bool, [Bool], [Bool]) -> (Bool, [Bool], [Bool]) -> (Bool, [Bool], [Bool])
addFloat (sgn1, exp1, frc1) (sgn2, exp2, frc2) =
  if sgn1 == sgn2 then
    let (carry, frcOut) = addFraction roundUp frcUnifSup frcUnifInf
        (_, frcOutUp) = addFraction (frcUnifSup !! 23 && frcUnifInf !! 23 || (frcUnifSup !! 23 || frcUnifInf !! 23) && (((fstOut sr || sndOut sr) || not (tailNil sr)) || frcUnifSup !! 22 /= frcUnifInf !! 22))
                                    (False : take 23 frcUnifSup) (False : take 23 frcUnifInf)
        (ovf, expOut) = addExponent carry expUnif (replicate 8 False)
    in  if carry then
          if isMaxExponent expOut || ovf then
            (sgn1, replicate 8 True, True : replicate 23 False)
          else
            (sgn1, expOut, frcOutUp)
        else
          (sgn1, expOut, frcOut)
  else
    let (frcIreg, sgnOut, isBase) =
          if eqExp then
            let (pos1, frcTmp1) = addFraction (not roundUp) frcUnifSup (map not frcUnifInf)
                (pos2, frcTmp2) = addFraction (not roundUp) (map not frcUnifSup) frcUnifInf
            in  (if pos1 then frcTmp1 else frcTmp2, pos1 && sgn1 || pos2 && sgn2, True)

          else
            let (_, frcOutBase) = addFraction (not roundUp) frcUnifSup (map not frcUnifInf)
                (_, frcOutDown) = addFraction (not (sndOut sr && (not (tailNil sr) || fstOut sr))) (tail frcUnifSup ++ [False]) (tail (map not frcUnifInf) ++ [not $ fstOut sr])
            in (if head frcOutBase then frcOutBase else frcOutDown, sgnSup, head frcOutBase)

        clz = countLeadingZero frcIreg
        (posExp, expOut) = addExponent isBase expUnif $ replicate 3 True ++ (map not clz)
        frcOut = shiftLeftFraction clz frcIreg

    in  if posExp && isNonZeroExponent expOut then
          (sgnOut, expOut, frcOut)
        else
          (sgnOut, replicate 8 False, replicate 24 False)
  where
    (posSft, s0:s1:s2:s) = addExponent True exp1 (map not exp2)
    valid = (posSft && not s0 && not s1 && not s2) || (not posSft && s0 && s1 && s2)
    s' = if valid then s else replicate 5 posSft
    eqExp = (posSft && valid) && (((not (s!!0) && not (s!!1)) && (not (s!!2) && not (s!!3))) && not (s!!4))

    (sgnSup, sgnInf, expUnif, frcUnifSup, sr) =
      if posSft then
         (sgn1, sgn2, exp1, frc1, shiftRightFraction False s' frc2)
      else
         (sgn2, sgn1, exp2, frc2, shiftRightFraction (frc1 !! 23) (map not s') $ False : take 23 frc1)

    frcUnifInf = shifted sr
    roundUp = fstOut sr && ((sndOut sr || not (tailNil sr)) || frcUnifSup !! 23 /= frcUnifInf !! 23)

fadd :: [Bool] -> [Bool] -> [Bool]
fadd x y = mergeFloat $ addFloat (splitFloat x) (splitFloat y)
