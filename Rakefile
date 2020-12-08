# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new :test do |t|
  t.libs << 'test'
  t.pattern = 'test/**/test_*.rb'
end

desc 'Run tests and linter w/auto-fix'
task :default do
  sh %(script/lint)
  sh %(script/test)
end
