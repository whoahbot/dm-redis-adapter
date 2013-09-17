begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require "rspec/core/rake_task"

GEM = 'dm-redis-adapter'
GEM_NAME = 'dm-redis-adapter'
AUTHORS = ['Dan Herrera']
EMAIL = "whoahbot@gmail.com"
HOMEPAGE = "http://github.com/whoahbot/dm-redis-adapter"
SUMMARY = "DataMapper adapter for the Redis key-value database"

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = GEM
    gemspec.summary = SUMMARY
    gemspec.email = EMAIL
    gemspec.homepage = HOMEPAGE
    gemspec.description = SUMMARY
    gemspec.authors = AUTHORS
    gemspec.add_dependency "dm-core", ">= 1.2.0"
    gemspec.add_dependency "dm-types", ">= 1.2.0"
    gemspec.add_dependency "hiredis", "~> 0.4.0"
    gemspec.add_dependency "redis", ">= 3.0.4"
    gemspec.files = %w(MIT-LICENSE README.textile Rakefile) + Dir.glob("{lib,spec}/**/*")
    gemspec.has_rdoc = false
    gemspec.extra_rdoc_files = ["MIT-LICENSE"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end


task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace', '--color', '--drb', '--format documentation']
end
