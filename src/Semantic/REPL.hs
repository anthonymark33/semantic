{-# LANGUAGE GADTs, KindSignatures, LambdaCase, TypeOperators #-}
module Semantic.REPL () where

import Control.Abstract
import Control.Monad.IO.Class

data REPL (m :: * -> *) result where
  Prompt :: REPL m String
  Output :: String -> REPL m ()

prompt :: (Effectful m, Member REPL effects) => m effects String
prompt = send Prompt

output :: (Effectful m, Member REPL effects) => String -> m effects ()
output s = send (Output s)


instance PureEffect REPL
instance Effect REPL where
  handleState state handler (Request Prompt k) = Request Prompt (handler . (<$ state) . k)
  handleState state handler (Request (Output s) k) = Request (Output s) (handler . (<$ state) . k)


runREPL :: (Effectful m, MonadIO (m effects), PureEffects effects) => m (REPL ': effects) a -> m effects a
runREPL = interpret $ \case
  Prompt -> liftIO $ do
    putStr "repl: "
    getLine
  Output s -> liftIO (putStrLn s)
