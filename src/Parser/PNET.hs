module Parser.PNET
    (parseContent)
where

import Control.Applicative ((<*),(*>),(<*>),(<$>))
import Text.Parsec
import Text.Parsec.Language (LanguageDef, emptyDef)
import qualified Text.Parsec.Token as Token

import Parser
import PetriNet (PetriNet,makePetriNet)
import Property

languageDef :: LanguageDef ()
languageDef =
        emptyDef {
                 Token.commentStart    = "/*",
                 Token.commentEnd      = "*/",
                 Token.commentLine     = "//",
                 Token.identStart      = letter <|> char '_',
                 Token.identLetter     = alphaNum <|> char '_',
                 Token.reservedNames   = ["true", "false"],
                 Token.reservedOpNames = ["->", "<", "<=", "=", ">=", ">",
                                          "+", "-", "*", "&&", "||", "!"]
                 }

lexer :: Token.TokenParser ()
lexer = Token.makeTokenParser languageDef

identifier :: Parser String
identifier = Token.identifier lexer -- parses an identifier
stringLiteral :: Parser String
stringLiteral = Token.stringLiteral lexer -- parses a string literal
reserved :: String -> Parser ()
reserved   = Token.reserved   lexer -- parses a reserved name
reservedOp :: String -> Parser ()
reservedOp = Token.reservedOp lexer -- parses an operator
brackets :: Parser a -> Parser a
brackets   = Token.brackets   lexer -- parses p surrounded by brackets
braces :: Parser a -> Parser a
braces     = Token.braces     lexer -- parses p surrounded by braces
parens :: Parser a -> Parser a
parens     = Token.parens     lexer -- parses p surrounded by parenthesis
natural :: Parser Integer
natural    = Token.natural    lexer -- parses a natural number
integer :: Parser Integer
integer    = Token.integer    lexer -- parses an integer
comma :: Parser String
comma      = Token.comma       lexer -- parses a comma
whiteSpace :: Parser ()
whiteSpace = Token.whiteSpace lexer -- parses whitespace


optionalCommaSep :: Parser a -> Parser [a]
optionalCommaSep p = many (p <* optional comma)

singleOrList :: Parser a -> Parser [a]
singleOrList p = braces (optionalCommaSep p) <|> (:[]) <$> p

numberOption :: Parser Integer
numberOption = option 1 (brackets natural)

ident :: Parser String
ident = (identifier <|> stringLiteral) <?> "identifier"

identList :: Parser [String]
identList = singleOrList ident

places :: Parser [String]
places = reserved "places" *> identList

transitions :: Parser [String]
transitions = reserved "transitions" *> identList

initial :: Parser [(String,Integer)]
initial = reserved "initial" *> singleOrList (do
            n <- ident
            i <- numberOption
            return (n,i)
          )

arc :: Parser [(String,String,Integer)]
arc = do
        lhs <- identList
        rhsList <- many1 (do
                reservedOp "->"
                w <- numberOption
                ids <- identList
                return (ids,w)
            )
        return $ fst $ foldl makeArc ([],lhs) rhsList
      where
        makeArc (as,lhs) (rhs,w) = ([(l,r,w) | l <- lhs, r <- rhs] ++ as, rhs)

arcs :: Parser [(String,String,Integer)]
arcs = do
        reserved "arcs"
        as <- singleOrList arc
        return $ concat as

data Statement = Places [String] | Transitions [String] |
                 Arcs [(String,String,Integer)] | Initial [(String,Integer)]

statement :: Parser Statement
statement = Places <$> places <|>
            Transitions <$> transitions <|>
            Arcs <$> arcs <|>
            Initial <$> initial

petriNet :: Parser PetriNet
petriNet = do
            reserved "petri"
            reserved "net"
            name <- option "" ident
            statements <- braces (many statement)
            let (p,t,a,i) = foldl splitStatement ([],[],[],[]) statements
            return $ makePetriNet name p t a i
        where
            splitStatement (ps,ts,as,is) stmnt = case stmnt of
                  Places p -> (p ++ ps,ts,as,is)
                  Transitions t -> (ps,t ++ ts,as,is)
                  Arcs a -> (ps,ts,a ++ as,is)
                  Initial i -> (ps,ts,as,i ++ is)

preFactor :: Parser Integer
preFactor = (reservedOp "-" *> return (-1)) <|>
            (reservedOp "+" *> return 1)

linAtom :: Integer -> Parser LinAtom
linAtom fac = ( integer >>= \lhs ->
                option (Const (fac*lhs)) $ Var (fac*lhs) <$> (reservedOp "*" *> ident)
              ) <|> Var fac <$> ident

term :: Parser Term
term = Term <$> ((:) <$> (option 1 preFactor >>= linAtom) <*>
                         many (preFactor >>= linAtom))

parseOp :: Parser Op
parseOp = (reservedOp "<" *> return Lt) <|>
          (reservedOp "<=" *> return Le) <|>
          (reservedOp "=" *> return Eq) <|>
          (reservedOp ">" *> return Gt) <|>
          (reservedOp ">=" *> return Ge)

linIneq :: Parser Formula
linIneq = do
        lhs <- term
        op <- parseOp
        rhs <- term
        return (Atom (LinIneq lhs op rhs))

atom :: Parser Formula
atom = (reserved "true" *> return FTrue) <|>
       (reserved "false" *> return FFalse) <|>
       linIneq

parensForm :: Parser Formula
parensForm = atom <|> parens formula

negation :: Parser Formula
negation = (Neg <$> (reservedOp "!" *> negation)) <|> parensForm

conjunction :: Parser Formula
conjunction = do
        lhs <- negation
        option lhs ((lhs :&:) <$> (reservedOp "&&" *> conjunction))

disjunction :: Parser Formula
disjunction = do
        lhs <- conjunction
        option lhs ((lhs :|:) <$> (reservedOp "||" *> disjunction))

formula :: Parser Formula
formula = disjunction

propertyType :: Parser PropertyType
propertyType =
        (reserved "safety" *> return Safety) <|>
        (reserved "liveness" *> return Liveness)

property :: Parser Property
property = do
        pt <- propertyType
        reserved "property"
        name <- option "" ident
        form <- braces formula
        return Property { pname=name, ptype=pt, pformula=form }

parseContent :: Parser (PetriNet,[Property])
parseContent = do
        whiteSpace
        net <- petriNet
        properties <- many property
        eof
        return (net, properties)