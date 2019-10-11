{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE TypeApplications #-}
module Main (main) where

import System.Environment
import TreeSitter.Unmarshal
import TreeSitter.Python.AST
import TreeSitter.Python
import Source.Range
import Source.Span
import Data.ByteString.Char8
import Data.ByteString (pack, readFile, ByteString)
import System.IO (FilePath)
import Options.Applicative hiding (style)
import Data.Semigroup ((<>))

data SemanticAST = SemanticAST
  { sourceFilePath      :: Maybe FilePath
  , sourceString        :: Maybe Prelude.String
  , format              :: Format
  } deriving (Read)

parseAST :: Parser SemanticAST
parseAST = SemanticAST
      <$> option auto
          ( long "sourcefile"
         <> metavar "FILEPATH"
         <> help "Specify filepath containing source code to parse" )
      <*> option auto
          ( long "sourceString"
         <> metavar "STRING"
         <> help "Specify source input to parse"
          )
      <*> option auto
          ( long "format"
         <> help "Specify desired output: show, json, sexpression" )

main :: IO ()
main = generateAST =<< execParser opts

generateAST :: SemanticAST -> IO ()
generateAST (SemanticAST filePath sourceString _) = do
  case filePath of
    Just filePath -> do
      bytestring <- Data.ByteString.readFile filePath
      print =<< parseByteString @TreeSitter.Python.AST.Module @(Range, Span) tree_sitter_python bytestring
    Nothing -> do
      case sourceString of
        Just sourceString -> do
          bytestring <- Data.ByteString.Char8.pack . Prelude.head <$> getArgs
          print =<< parseByteString @TreeSitter.Python.AST.Module @(Range, Span) tree_sitter_python bytestring
        Nothing -> print "please provide a file path or source string to parse"

opts :: ParserInfo SemanticAST
opts = info (parseAST <**> helper)
  ( fullDesc
 <> progDesc "Parse source code and produce an AST"
 <> header "semantic-ast is a package used to parse source code" )

-- TODO: Define formats for json, sexpression, etc.
data Format = Show
  deriving (Read)

data Input
  = FileInput FilePath
  | StdInput
  deriving (Read)

input :: Parser Input
input = fileInput <|> stdInput

-- pass in a file as an argument and parse its contents
fileInput :: Parser Input
fileInput = FileInput <$> strOption
  (  long "file"
  <> short 'f'
  <> metavar "FILENAME"
  <> help "Input file" )

-- Read from stdin
stdInput :: Parser Input
stdInput = flag' StdInput
  (  long "stdin"
  <> help "Read from stdin" )
