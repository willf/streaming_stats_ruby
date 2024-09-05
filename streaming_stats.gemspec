# frozen_string_literal: true

require 'rake'

Gem::Specification.new do |s|
  s.name = 'streaming_stats'
  s.version     = '0.1.6'
  s.date        = '2020-10-08'
  s.summary     = 'Calculates descriptive statistics from streams'
  s.description = 'Calculates descriptive statistics from streams with minimal overhead'
  s.authors     = ['Will Fitzgerald']
  s.email       = 'will.fitzgerald@gmail.com'
  s.files       = FileList[
                    'lib/**/*',
                    'script/*', '[A-Z]*',
                    'test/**/*']
                  .reject! { |fn| fn.include? 'vendor' or fn.include? '.gem' }
                  .to_a
  s.homepage    = 'https://rubygems.org/gems/streaming_stats'
  s.metadata    = { 'source_code_uri' => 'https://github.com/willf/streaming_stats_ruby' }

  s.license     = 'MIT'
  s.bindir      = 'script'
  s.required_ruby_version = '>= 3.0'
end
