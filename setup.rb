# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'dotenv'
require 'active_support/all'
require 'pry'

require './lib/utils/misc_utils'
require './lib/streaming_stats'

Dotenv.load
