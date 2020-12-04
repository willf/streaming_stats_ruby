# frozen_string_literal: true

class StreamingStats
  attr_reader :epsilon, :count, :mean
  def initialize(epsilon: 0.1)
    @epsilon = epsilon
    @count = 0
    @mean = 0.0
    @m2 = 0.0
    @sum = 0.0
  end

  def insert(value)
    @count += 1
    delta = value - @mean 
    @mean = @mean + (delta/@count)
    @m2 = @m2 + (delta * (value-@mean))
  end

  def variance
    return 0 if @count <= 1
    @m2 / @count
  end

  def sqrt
    return Math.sqrt(variance)
  end

end

