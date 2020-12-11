# Streaming Stats

![Ruby](https://github.com/willf/streaming_stats/workflows/Ruby/badge.svg) [![Gem Version](https://badge.fury.io/rb/streaming_stats.svg)](https://badge.fury.io/rb/streaming_stats)

StreamingStats is a Ruby class that takes streaming numeric data
and return descriptive statistics with minimal overhead.
A stream with n entries will only require about log2(n) storage.
The main update function is `insert`, and the object can
return:

- n (number of values inserted)
- sum
- mean
- stddev
- variance
- quantile (i.e. percentile)
- min
- max

Note that quantiles are approximate.

```irb
require 'streaming_stats'
> gk = StreamingStats.new(epsilon: 0.01)
> 10000.times {gk.insert rand}
=> 10000
> gk.n
=> 10000
> gk.sum
=> 4985.484627445102
> gk.mean
=> 0.4985484627445139
> gk.stddev
=> 0.288236161831176
> gk.variance
=> 0.08308008498716787
> gk.min
=> 0.0001414880872682156
> gk.max
=> 0.9999396732975679
> gk.quantile 0.1
=> 0.08869274826771956
> gk.quantile 0.5
=> 0.4944707523857559
> gk.quantile 0.9
=> 0.9004683944698589
> gk.quantile 0.999
=> 0.9999396732975679
gk.compression_ratio
=> 0.9927
```

The basic stats (n, sum, mean, variance, stddev) are from 
my very first Gist: https://gist.github.com/willf/187846.

The approximate quartile method is a port of [streaming-percentiles-js](https://github.com/sengelha/streaming-percentiles-js).

 How to calculate streaming percentiles is discussed in Steven Englehardt's series, [Calculating Percentiles on Streaming Data](https://www.stevenengelhardt.com/series/calculating-percentiles-on-streaming-data/).
