{-# Language ImplicitParams #-}
module Fig.Emulator.GB where

import Fig.Prelude
import Prelude (fromIntegral)

import System.IO (withFile, IOMode (WriteMode))

import Control.Lens ((.=), use)
import Control.Monad (when)
import Control.Monad.State (StateT(..))

import qualified SDL

import Fig.Emulator.GB.CPU
import Fig.Emulator.GB.CPU.Instruction
import Fig.Emulator.GB.Bus (Bus(..), Addr(..))
import Fig.Emulator.GB.Component.RAM
import Fig.Emulator.GB.Component.ROM
import Fig.Emulator.GB.Component.Video
import Fig.Emulator.GB.Component.Joystick
import Fig.Emulator.GB.Component.Serial

cpuDMG :: (MonadIO m, MonadThrow m) => ByteString -> Framebuffer -> CPU m
cpuDMG rom fb = CPU
  { _lastPC = 0x0
  , _lastIns = Nop
  , _running = True
  , _regs = initialRegs
  , _bus = Bus
    [ compROM rom
    , compWRAM 0xc000 $ 8 * 1024
    , compVideo fb
    , compJoystick
    , compSerial
    , compWRAM 0xff80 0x7e -- HRAM
    ]
  }

testRun :: forall m. (MonadIO m, MonadThrow m) => ByteString -> m ()
testRun rom = do
  SDL.initializeAll
  window <- SDL.createWindow "taking" SDL.defaultWindow
  fb <- initializeFramebuffer
  let cpu = cpuDMG rom fb
  let
    loop :: forall m'. Emulating m' => Int -> m' ()
    loop cycle = do
      events <- SDL.pollEvents
      forM_ events \ev ->
        case SDL.eventPayload ev of
          SDL.QuitEvent -> running .= False
          _else -> pure ()
      pc <- use $ regs . regPC
      ins <- decode
      when (pc == 0x2817) do
        log $ mconcat
          [ pretty $ Addr pc
          , ": ", tshow ins
          ]
      step ins
      -- logCPUState
      when (rem cycle 70224 == 0) do
        ws <- SDL.getWindowSurface window
        SDL.surfaceFillRect ws Nothing $ SDL.V4 0x00 0x00 0x00 0xff
        void $
          SDL.surfaceBlitScaled
          (fbSurface fb)
          Nothing
          ws
          (Just $ SDL.Rectangle
           (SDL.P $ SDL.V2 0 0)
           (SDL.V2
            (fromIntegral screenWidth * 8)
            (fromIntegral screenHeight * 8)))
        SDL.updateWindowSurface window
      r <- use running
      when r . loop $ cycle + 1
  liftIO $ withFile "log.txt" WriteMode \h -> do
    let ?log = h
    void $ flip runStateT cpu do
      -- logCPUState
      loop 0