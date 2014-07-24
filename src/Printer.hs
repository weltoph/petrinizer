module Printer
    (validateId,intercalate)
where

import Data.Char
import Data.ByteString.Builder
import Data.Monoid

validateId :: String -> String
validateId "" = "_"
validateId (x:xs) = (if isAlpha x then x else '_') :
        map (\c -> if isAlphaNum c then c else '_') xs


intercalate :: Builder -> [Builder] -> Builder
intercalate _ [] = mempty
intercalate sep (x:xs) = x <> go xs
      where go = foldr (\y -> (<>) (sep <> y)) mempty

