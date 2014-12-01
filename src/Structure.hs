module Structure
    (Structure(..),
     checkStructure,
     checkParallelT)
where

import PetriNet
import Data.List (intersect,sort)

data Structure = FreeChoice | Parallel | FinalPlace

instance Show Structure where
        show FreeChoice = "free choice"
        show Parallel = "parallel"
        show FinalPlace = "final place"

checkStructure :: PetriNet -> Structure -> Bool
checkStructure net FreeChoice =
            all freeChoiceCond [(p,s) | p <- places net, s <- places net]
        where freeChoiceCond (p,s) =
                  let ppost = sort $ post net p
                      spost = sort $ post net s
                  in null (ppost `intersect` spost) || ppost == spost
checkStructure net Parallel =
            any (checkParallelT net) (transitions net)
checkStructure net FinalPlace =
                length (filter finalPlace (places net)) == 1
            where finalPlace p = null (post net p) &&
                      all (\t -> length (post net t) == 1) (pre net p)

checkParallelT :: PetriNet -> String -> Bool
checkParallelT net t =
                  any postComp [(p,s) | p <- post net t, s <- post net t]
        where postComp (p,s) =
                  let ppost = sort $ post net p
                      spost = sort $ post net s
                  in  p /= s &&
                      not (null ppost) && not (null spost) && ppost /= spost &&
                      any (\u -> length (pre net u) == 1) ppost &&
                      any (\u -> length (pre net u) == 1) spost
