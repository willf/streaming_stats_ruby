# frozen_string_literal: true

class StreamingStats
  attr_reader :epsilon, :count
  def initialize(epsilon: 0.1)
    @epsilon = epsilon
    @count = 0
    @values = []
  end

  def insert(value)
    @count+= 1
    @values.push value
  end

  def mean
    @values.sum / @count
  end
end

