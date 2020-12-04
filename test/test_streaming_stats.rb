# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/streaming_stats'


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
      assert_equal gk.count, i
      gk.insert i
      assert_equal gk.count, i+1
    end
  end

  def test_basic_stats
    gk = StreamingStats.new(epsilon: 0.01)
    10000.times do
      gk.insert rand
    end
    assert_in_delta gk.mean, 0.5, 0.03 
    assert_in_delta gk.variance, 1/12.0, 0.05
    assert_in_delta gk.sqrt, Math.sqrt(1/12.0), 0.05 
  end




end
