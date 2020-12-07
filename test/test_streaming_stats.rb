# frozen_string_literal: true

require_relative 'test_helper'

class StreamingStatsTest < Minitest::Test
  def test_default_initialization
    gk = StreamingStats.new
    assert_equal gk.epsilon, 0.1
  end

  def test_given_init
    gk = StreamingStats.new(epsilon: 0.2)
    assert_equal gk.epsilon, 0.2
  end

  def test_insert
    gk = StreamingStats.new
    300.times do |i|
      assert_equal gk.n, i
      gk.insert i
      assert_equal gk.n, i + 1
    end
  end

  def test_basic_stats
    gk = StreamingStats.new(epsilon: 0.01)
    1_000.times do
      gk.insert rand
    end
    assert_in_delta gk.mean, 0.5, 0.03
    assert_in_delta gk.variance, 1 / 12.0, 0.05
    assert_in_delta gk.stddev, Math.sqrt(1 / 12.0), 0.05
    assert_equal gk.n, 1000
    assert_in_delta gk.sum, gk.mean * gk.n, 0.01
  end

  def test_initialized_stats
    gk = StreamingStats.new(epsilon: 0.01)
    assert_in_delta gk.mean, 0.0, 0.001
    assert_in_delta gk.variance, 0.0, 0.001
    assert_in_delta gk.stddev, 0.0, 0.001
    assert_equal gk.n, 0
    assert_in_delta gk.sum, 0.0, 0.001
  end

  def test_quantiles
    gk = StreamingStats.new(epsilon: 0.01)
    10_000.times do
      gk.insert rand
    end
    assert_in_delta gk.quantile(0.1), 0.1, 0.03
    assert_in_delta gk.quantile(0.5), 0.5, 0.03
    assert_in_delta gk.quantile(0.5), gk.mean, 0.03
    assert_in_delta gk.quantile(0.9), 0.9, 0.03
    assert_equal gk.quantile(0.0), gk.min
    assert_equal gk.quantile(1.0), gk.max
  end
end
