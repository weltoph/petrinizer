module Solver.SComponent
    (checkSComponentSat)
where

import Data.SBV
import Data.List (partition)
import qualified Data.Map as M

import Util
import PetriNet
import Solver

checkPrePostPlaces :: PetriNet -> SIMap Place -> SIMap Transition ->
        SBool
checkPrePostPlaces net p' t' =
            bAnd $ map checkPrePostPlace $ places net
        where checkPrePostPlace p =
                  let incoming = map (positiveVal t') $ pre net p
                      outgoing = map (positiveVal t') $ post net p
                      pVal = positiveVal p' p
                  in  pVal ==> bAnd incoming &&& bAnd outgoing

checkPrePostTransitions :: PetriNet -> SIMap Place -> SIMap Transition ->
        SBool
checkPrePostTransitions net p' t' =
            bAnd $ map checkPrePostTransition $ transitions net
        where checkPrePostTransition t =
                  let incoming = mval p' $ pre net t
                      outgoing = mval p' $ post net t
                      tVal = positiveVal t' t
                  in  tVal ==> sum incoming .== 1 &&& sum outgoing .== 1

checkSubsetTransitions :: FiringVector ->
        SIMap Transition -> SIMap Transition -> SBool
checkSubsetTransitions x t' y =
            let ySubset = map checkTransition $ elems x
            in  bAnd ySubset &&& sumVal y .< sum (mval t' (elems x))
        where checkTransition t = positiveVal y t ==> positiveVal t' t

checkNotEmpty :: SIMap Transition -> SBool
checkNotEmpty y = (.>0) $ sumVal y

checkClosed :: PetriNet -> FiringVector -> SIMap Place ->
        SIMap Transition -> SBool
checkClosed net x p' y =
            bAnd $ map checkPlaceClosed $ places net
        where checkPlaceClosed p =
                  let pVal = positiveVal p' p
                      postVal = bAnd $ map checkTransition
                                    [(t,t') | t <- pre net p, t' <- post net p,
                                              val x t > 0, val x t' > 0 ]
                  in  pVal ==> postVal
              checkTransition (t,t') = positiveVal y t ==> positiveVal y t'

checkTokens :: PetriNet -> SIMap Place -> SBool
checkTokens net p' =
            sum (map addPlace $ linitials net) .== 1
        where addPlace (p,i) = literal i * val p' p

checkBinary :: SIMap Place -> SIMap Transition ->
        SIMap Transition -> SBool
checkBinary p' t' y =
            checkBins p' &&&
            checkBins t' &&&
            checkBins y
        where checkBins xs = bAnd $ map (\x -> x .== 0 ||| x .== 1) $ vals xs

checkSizeLimit :: SIMap Place -> SIMap Transition -> Maybe (Int, Integer) -> SBool
checkSizeLimit _ _ Nothing = true
checkSizeLimit p' _ (Just (_, size)) = (.< literal size) $ sumVal p'

checkSComponent :: PetriNet -> FiringVector -> Maybe (Int, Integer) -> SIMap Place ->
        SIMap Transition -> SIMap Transition -> SBool
checkSComponent net x sizeLimit p' t' y =
        checkPrePostPlaces net p' t' &&&
        checkPrePostTransitions net p' t' &&&
        checkSubsetTransitions x t' y &&&
        checkNotEmpty y &&&
        checkSizeLimit p' t' sizeLimit &&&
        checkClosed net x p' y &&&
        checkTokens net p' &&&
        checkBinary p' t' y

checkSComponentSat :: PetriNet -> FiringVector -> Maybe (Int, Integer) ->
        ConstraintProblem Integer (Cut, Integer)
checkSComponentSat net x sizeLimit =
        let fired = elems x
            p' = makeVarMap $ places net
            t' = makeVarMap $ transitions net
            y = makeVarMapWith prime fired
        in  ("S-component constraints", "cut",
            getNames p' ++ getNames t' ++ getNames y,
            \fm -> checkSComponent net x sizeLimit (fmap fm p') (fmap fm t') (fmap fm y),
            \fm -> cutFromAssignment net x (fmap fm p') (fmap fm t') (fmap fm y))

cutFromAssignment :: PetriNet -> FiringVector -> IMap Place ->
        IMap Transition -> IMap Transition -> (Cut, Integer)
cutFromAssignment net x p' t' y =
        let ts = filter (\t -> val x t > 0) $ elems $ M.filter (> 0) t'
            (t1, t2) = partition (\t -> val y t > 0) ts
            s1 = filter (\p -> val p' p > 0) $ mpre net t1
            s2 = filter (\p -> val p' p > 0) $ mpre net t2
            size = fromIntegral $ M.size $ M.filter (> 0) p'
        in  (constructCut net x [s1,s2], size)

