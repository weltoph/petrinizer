{-# LANGUAGE TypeSynonymInstances, FlexibleInstances #-}

module Solver
    (checkSat,checkSatInt,MModelS,MModelI,MModelB,
     MModel(..),mVal,mValues,mElemsWith,mElemSum,CModel(..))
where

import Z3.Monad
import qualified Data.Map as M
import Control.Monad

newtype MModel a = MModel { getMap :: M.Map String a }

instance Show a => Show (MModel a) where
        show = show . M.toList . getMap

type MModelS = MModel AST
type MModelI = MModel Integer
type MModelB = MModel Bool

class Z3Type a where
        mkConcrete :: a -> Z3 AST
        getConcrete :: AST -> Z3 a

instance Z3Type Integer where
        mkConcrete = mkInt
        getConcrete = getInt

mVal :: MModel a -> String -> a
mVal m x = M.findWithDefault (error ("key not found: " ++ x)) x (getMap m)

mValues :: MModel a -> [a]
mValues m = M.elems $ getMap m

mElemsWith :: (a -> Bool) -> MModel a -> [String]
mElemsWith f m = M.keys $ M.filter f $ getMap m

mElemSum :: (Num a) => MModel a -> [String] -> a
mElemSum m xs = sum $ map (mVal m) xs

--class SMModel a where
--        mElem :: MModel a -> String -> Z3 AST
--        mNotElem :: MModel a -> String -> Z3 AST
--        mNotElem m x = mkNot =<< mElem m x
class CModel a where
        cElem :: MModel a -> String -> Bool
        cNotElem :: MModel a -> String -> Bool
        cNotElem m x = not $ cElem m x

--instance SMModel AST where
--        mElem m x = (mVal m x `mkGt`) =<< mkInt 0
--        mNotElem m x = mkEq (mVal m x) =<< mkInt 0
--instance SMModel AST where
--        mElem = mVal
--        mNotElem m x = mkNot $ mVal m x
instance CModel Integer where
        cElem m x = mVal m x > 0
        cNotElem m x = mVal m x == 0
instance CModel Bool where
        cElem = mVal
        cNotElem m x = not $ mVal m x

checkSat :: Z3Type a => Z3 Sort -> ([String], MModel AST -> Z3 ()) ->
        Z3 (Maybe (MModel a))
checkSat mkSort (vars, constraint) = do
        sort <- mkSort
        syms <- mapM (mkStringSymbol >=> flip mkConst sort) vars
        let smodel = MModel $ M.fromList $ vars `zip` syms
        constraint smodel
        result <- getModel
        case result of
            (Unsat, Nothing) -> return Nothing
            (Sat, Just m) -> do
                ms <- evalT m syms
                case ms of
                    Just xs -> do
                        vals <- mapM getConcrete xs
                        let cmodel = MModel $ M.fromList $ vars `zip` vals
                        return $ Just cmodel
                    Nothing -> error "Prover returned incomplete model"
            (Undef, _) -> error "Prover returned unknown"
            (Unsat, Just _) -> error "Prover returned unsat but a model"
            (Sat, Nothing) -> error "Prover returned sat but no model"

checkSatInt :: ([String], MModel AST -> Z3 ()) -> IO (Maybe (MModel Integer))
checkSatInt problem = evalZ3 $ checkSat mkIntSort problem
