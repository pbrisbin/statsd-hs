-------------------------------------------------------------------------------
-- |
-- Module     :  Network.Statsd
-- Copyright  :  (c) Patrick Brisbin 2010
-- License    :  as-is
-- Maintainer :  pbrisbin@gmail.com
-- Stability  :  unstable
-- Portability:  unportable
--
-- Haskell client for https://github.com/etsy/statsd/
--
-- >
-- > statsd def $ Increment "gorets"
-- >
-- > statsd def { statsdSampleRate 0.1 } $ Increment "gorets"
-- >
-- > statsd def $ Timing "glork" 320
-- >
-- > statsd def $ Time "glork" $ do
-- >     -- ...
-- >     -- ...
-- >     -- ...
-- >
-- > statsd def $ Gauge "gaugor" 333
-- >
-- > statsd def $ Set "uniques" 765
-- >
--
-------------------------------------------------------------------------------
module Network.Statsd
    ( Action(..)
    , StatsdConf(..)
    , Default(..)
    , statsd
    ) where


import Control.Monad
import Data.Default
import Data.Time.Clock
import Network.Socket hiding (send)
import System.Random


data Action = Increment String
            | Decrement String
            | Count String Int
            | Timing String Double
            | Time String (IO ())
            | Gauge String Double
            | Set String Int


data StatsdConf = StatsdConf
    { statsdHost       :: String
    , statsdPort       :: PortNumber
    , statsdSampleRate :: Float
    }


instance Default StatsdConf where
    def = StatsdConf "127.0.0.1" 8125 1


statsd :: StatsdConf -> Action -> IO ()
statsd (StatsdConf h p sr) a = do
    msg <- build a

    x <- getStdRandom $ randomR (0,1)

    unless (sr < 1 && x > sr) $
        send h p $ msg ++ if sr < 1 then "|@" ++ show sr else ""


build :: Action -> IO String
build (Increment k) = build $ Count k 1
build (Decrement k) = build $ Count k (-1)
build (Count k c)   = return $ k ++ ":" ++ show c  ++ "|c"
build (Timing k ms) = return $ k ++ ":" ++ show ms ++ "|ms"
build (Gauge k g)   = return $ k ++ ":" ++ show g  ++ "|g"
build (Set k s)     = return $ k ++ ":" ++ show s  ++ "|s"
build (Time k a)    = do
    t1 <- getCurrentTime; a
    t2 <- getCurrentTime

    build $ Timing k (diff t1 t2 * 1000)

    where
        -- seconds
        diff :: UTCTime -> UTCTime -> Double
        diff t = realToFrac . diffUTCTime t

send :: String -> PortNumber -> String -> IO ()
send h p msg = do
    s <- socket AF_INET Datagram defaultProtocol
    a <- inet_addr h
    _ <- sendTo s msg (SockAddrInet p a)

    return ()
