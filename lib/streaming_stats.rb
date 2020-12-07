# frozen_string_literal: true

require 'ostruct'

# Public: StreamingStats class
# StreamingStats is a Ruby class that takes streaming numeric data
# and return descriptive statistics with minimal overhead.
# A stream with n entries will only require about log2(n) storage.
# The main update function is `insert`, and the object can
# return
# - n (number of values inserted)
# - sum
# - mean
# - stddev
# - variance
# - quantile (i.e. percentile)
# - min
# - max
# The sum, mean, stddev, variance functions are calculated more or less
# as in the technical description here: https://www.johndcook.com/blog/standard_deviation/
#
# The quantile method is a Ruby port of https://github.com/sengelha/streaming-percentiles-js
# The variable names, etc. of the quantile method are adopted from that project
#
# The compression size can be estimated with the method compression_size
#
# require 'streaming_stats'
# > gk = StreamingStats.new(epsilon: 0.01); 10000.times {gk.insert rand}
# => 10000
# > gk.n
# => 10000
# > gk.sum
# => 4985.484627445102
# > gk.mean
# => 0.4985484627445139
# > gk.stddev
# => 0.288236161831176
# > gk.variance
# => 0.08308008498716787
# > gk.min
# => 0.0001414880872682156
# > gk.max
# => 0.9999396732975679
# > gk.quantile 0.1
# => 0.08869274826771956
# > gk.quantile 0.5
# => 0.4944707523857559
# > gk.quantile 0.9
# => 0.9004683944698589
# > gk.quantile 0.999
# => 0.9999396732975679
# gk.compression_ratio
# => 0.9927
class StreamingStats
  GK_MAX_BAND = 999_999
  attr_reader :epsilon, :n, :mean, :sum

  # epsilon - "epsilon is allowable error. As epsilon becomes smaller,
  # the accuracy of the approximation improves, but the class
  # consumes more memory" see https://www.stevenengelhardt.com/series/calculating-percentiles-on-streaming-data/
  def initialize(epsilon: 0.1)
    @n = 0
    @mean = 0.0
    @m2 = 0.0
    @sum = 0.0

    @epsilon = epsilon
    @one_over_2e = 1 / (2 * epsilon)
    @S = []
  end

  # Public: Returns the compression list
  # For debugging only
  def s
    @S
  end

  # Public: inserts a value from a stream, updating the state
  #
  # value - The Numeric to be inserted
  #
  # Examples
  #
  #   insert(100)
  #   => 100
  #
  # Returns the Numeric inserted
  def insert(value)
    ## Basic stats accumulators
    @n += 1
    @sum += value
    delta = value - @mean
    @mean += (delta / @n)
    @m2 += (delta * (value - @mean))
    ## quantile work
    _compress if (@n % @one_over_2e).zero?
    _do_insert value
    value
  end

  # Public: Returns the variance of the streamed data. Initialized to 0.0
  #
  # Examples
  #
  #   variance
  #   => 1.02
  #
  # Returns the variance
  def variance
    return 0 if @n <= 1

    @m2 / @n
  end

  # Public: Returns the standard deviation of the streamed data. Initialized to 0.0
  #
  # Examples
  #
  #   variance
  #   => 1.02
  #
  # Returns the standard deviation
  def stddev
    Math.sqrt(variance)
  end

  # Public: Returns the approximate quantile (percentile) at phi
  #
  # phi - A Numeric between 0.0 and 1.0, inclusive
  #
  # Examples
  #
  #   quantile(0.5)
  #   => 5.01
  #
  # Returns the approximate quantile
  def quantile(phi)
    throw ArgumentError.new("#{phi} must be between 0.0 and 1.0 inclusive") unless phi.between?(0.0, 1.0)
    en = @epsilon * @n
    r = (phi * @n).ceil
    rmin = 0
    (0..@S.size - 1).each do |i|
      rmin += @S[i].g
      rmax = rmin + @S[i].delta
      return @S[i].v if r - rmin <= en && rmax - r <= en
    end
    throw 'Unknown error'
  end

  # Public: Returns the minimum value so far inserted
  #
  # Examples
  #
  #   max
  #   => 500.0
  #
  # Returns the minimum value
  def min
    @S[0].v
  end

  # Public: Returns the maximum value so far inserted
  #
  # Examples
  #
  #   max
  #   => 500.0
  #
  # Returns the maximum value
  def max
    @S.last.v
  end

  # Public: Returns the compression ratio achieved
  #
  # Examples
  #
  #   compression_ration
  #   => 99.1
  #
  # Returns the ompression ratio achieved
  def compression_ratio
    1.0 - (1.0 * @S.size / @n)
  end

  # Private: Compresses the number of values stored
  def _compress
    two_epsilon_n = 2 * @epsilon * @n
    bands = StreamingStats._construct_band_lookup(two_epsilon_n)
    # We must always keep the first and last nodes as these
    # are global min/max
    i = @S.length - 2
    while i >= 1
      if bands[@S[i].delta] <= bands[@S[i + 1].delta]
        start_indx = i
        g_i_star = @S[i].g
        while start_indx >= 2 && (bands[@S[start_indx - 1].delta] < bands[@S[i].delta])
          start_indx -= 1
          g_i_star += @S[start_indx].g
        end
        if (g_i_star + @S[i + 1].g + @S[i + 1].delta) < two_epsilon_n
          # The below is a delete_tuples([start_indx, i]) operation
          merged = OpenStruct.new(
            v: @S[i + 1].v,
            g: g_i_star + @S[i + 1].g,
            delta: @S[i + 1].delta
          )
          splice!(@S, start_indx, 2 + (i - start_indx), merged)
          i = start_indx
        end
      end
      i -= 1
    end
  end

  # Private: Constructs a band lookup
  def self._construct_band_lookup(two_epsilon_n)
    bands = Array.new(two_epsilon_n + 1)
    bands[0] = GK_MAX_BAND
    bands[two_epsilon_n] = 0 # when float?
    p = two_epsilon_n.floor
    (1..Math.log2(two_epsilon_n).ceil).each do |alpha|
      two_alpha_minus_1 = 2**(alpha - 1)
      two_alpha = 2**alpha
      lower = [p - two_alpha - (p % two_alpha), 0].max
      upper = p - two_alpha_minus_1 - (p % two_alpha_minus_1)
      ((lower + 1)..upper).each do |i|
        bands[i] = alpha
      end
    end
    bands
  end

  # Private: Actually does a new insertion into S
  def _do_insert(v)
    i = _find_insertion_index(v)
    delta = _determine_delta(i)
    tuple = OpenStruct.new(v: v, g: 1, delta: delta)
    splice!(@S, i, 0, tuple)
    @S
  end

  # Private: Find where to insert
  def _find_insertion_index(value)
    i = 0
    i += 1 while i < @S.size && value >= @S[i].v
    i
  end

  # Private: Determine delta
  def _determine_delta(i)
    return 0 if @n < @one_over_2e
    return 0 if i.zero? || i == @S.size

    (2 * @epsilon * @n).floor - 1
  end
end
