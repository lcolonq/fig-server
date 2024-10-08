module Fig.Emulator.GB.Component.RAM
  ( compWRAM
  ) where

import Fig.Prelude

import qualified Data.Vector as V
import qualified Data.Vector.Mutable as MV
import Data.Word (Word8)

import Fig.Emulator.GB.Bus

newtype RAMError = RAMError Text
  deriving Show
instance Exception RAMError
instance Pretty RAMError where
  pretty (RAMError b) = mconcat
    [ "internal RAM error: "
    , b
    ]

compWRAM :: Addr -> Int -> Component
compWRAM start size = Component
  { compState = V.replicate size 0 :: V.Vector Word8
  , compMatches = \a ->
      a >= start && a <= end
  , compUpdate = \s _ -> {-# SCC "ComponentWRAMUpdate" #-} pure s
  , compWrite = \s ad v -> {-# SCC "ComponentWRAMWrite" #-} do
      let offset = fromIntegral . unAddr $ ad - start
      pure $ V.modify (\ms -> MV.write ms offset v) s
  , compRead = \s ad -> {-# SCC "ComponentWRAMRead" #-} do
      let offset = fromIntegral . unAddr $ ad - start
      case s V.!? offset of
        Nothing -> throwM . RAMError $ mconcat
          [ "address ", pretty ad, " out of bounds"
          ]
        Just v -> pure v
  }
  where
    end = start + Addr (fromIntegral (size - 1))
