# frozen_string_literal: true

require 'ostruct'

class StreamingStats
  GK_MAX_BAND = 999_999
  attr_reader :epsilon, :n, :mean, :sum

  def initialize(epsilon: 0.1)
    @n = 0
    @mean = 0.0
    @m2 = 0.0
    @sum = 0.0

    @epsilon = epsilon
    @one_over_2e = 1 / (2 * epsilon)
    @S = []
  end

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

  def variance
    return 0 if @n <= 1

    @m2 / @n
  end

  def stddev
    Math.sqrt(variance)
  end

  def quantile(phi)
    en = @epsilon * @n
    r = (phi * @n).ceil
    rmin = 0
    (0..@S.size).each do |i|
      rmin += @S[i].g
      rmax = rmin + @S[i].delta
      return @S[i].v if r - rmin <= en && rmax - r <= en
    end
    throw "Couldn't resolve quantile"
  end

  def compression_ratio
    1.0 - (1.0 * @S.size / @n)
  end

  # quantile(phi) {
  #   var en = this.epsilon * this.n;
  #   var r = Math.ceil(phi * this.n);
  #   var rmin = 0;
  #   for (var i = 0; i < this.S.length; ++i) {
  #     rmin += this.S[i].g;
  #     var rmax = rmin + this.S[i].delta;
  #     if (r - rmin <= en && rmax - r <= en)
  #       return this.S[i].v;
  #   }
  #   throw "Could not resolve quantile";
  # }

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

  # _compress() {
  #   var two_epsilon_n = 2 * this.epsilon * this.n;
  #   var bands = GK._construct_band_lookup(two_epsilon_n);
  #   // We must always keep the first & last nodes as those
  #   // are global min/max
  #   for (var i = this.S.length - 2; i >= 1; --i) {
  #     if (bands[this.S[i].delta] <= bands[this.S[i+1].delta]) {
  #       var start_indx = i;
  #       var g_i_star = this.S[i].g;
  #       while (start_indx >= 2 && bands[this.S[start_indx-1].delta] < bands[this.S[i].delta]) {
  #         --start_indx;
  #         g_i_star += this.S[start_indx].g;
  #       }
  #       if ((g_i_star + this.S[i+1].g + this.S[i+1].delta) < two_epsilon_n) {
  #         // The below is a delete_tuples([start_indx, i]) operation
  #         var merged = {v: this.S[i+1].v, g: g_i_star + this.S[i+1].g, delta: this.S[i+1].delta};
  #         this.S.splice(start_indx, 2 + (i - start_indx), merged);
  #         i = start_indx;
  #       }
  #     }
  #   }
  # }

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

  # static _construct_band_lookup(two_epsilon_n) {
  #   var bands = Array(two_epsilon_n + 1);
  #   bands[0] = GK_MAX_BAND; // delta = 0 is its own band
  #   bands[two_epsilon_n] = 0; // delta = two_epsilon_n is band 0 by definition

  #   var p = Math.floor(two_epsilon_n);
  #   for (var alpha = 1; alpha <= Math.ceil(Math.log2(two_epsilon_n)); ++alpha) {
  #       var two_alpha_minus_1 = Math.pow(2, alpha-1);
  #       var two_alpha = Math.pow(2, alpha);
  #       var lower = p - two_alpha - (p % two_alpha);
  #       if (lower < 0)
  #           lower = 0;
  #       var upper = p - two_alpha_minus_1 - (p % two_alpha_minus_1);
  #       for (var i = lower + 1; i <= upper; ++i) {
  #           bands[i] = alpha;
  #       }
  #   }

  #   return bands;
  # }

  # _do_insert(v) {
  #   var i = this._find_insertion_index(v);
  #   var delta = this._determine_delta(i);
  #   var tuple = {v: v, g: 1, delta: delta};
  #   this.S.splice(i, 0, tuple);
  # }

  def _do_insert(v)
    i = _find_insertion_index(v)
    delta = _determine_delta(i)
    tuple = OpenStruct.new(v: v, g: 1, delta: delta)
    splice!(@S, i, 0, tuple)
    @S
  end

  # _find_insertion_index(v) {
  #   var i = 0;
  #   while (i < this.S.length && v >= this.S[i].v)
  #     ++i;
  #   return i;
  # }

  def _find_insertion_index(value)
    i = 0
    i += 1 while i < @S.size && value >= @S[i].v
    i
  end

  # _determine_delta(i) {
  #   if (this.n < this.one_over_2e)
  #     return 0;
  #   else if (i == 0 || i == this.S.length)
  #     return 0;
  #   else
  #     return Math.floor(2 * this.epsilon * this.n) - 1;
  # }

  def _determine_delta(i)
    return 0 if @n < @one_over_2e
    return 0 if i.zero? || i == @S.size

    (2 * @epsilon * @n).floor - 1
  end
end
