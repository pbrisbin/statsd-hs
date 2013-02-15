# statsd-hs

A Haskell client for [statsd](https://github.com/etsy/statsd/).

## Usage

~~~ { .haskell }
import Network.Statsd

-- Increment == Count 1
-- Decrement == Count (-1)
statsd def $ Increment "gorets"

-- Sending a 1/10th sampling
statsd def { statsdSampleRate 0.1 } $ Increment "gorets"

-- Milliseconds
statsd def $ Timing "glork" 320

-- Timing an action
statsd def $ Time "glork" $ do
    -- Whatever you do here will be timed. I don't claim to understand 
    -- how laziness plays in. I just take two timestamps before and 
    -- after the action then record the difference

-- Gauges
statsd def $ Gauge "gaugor" 333

-- Unique occurrences during flush interval
statsd def $ Set "uniques" 765
~~~
