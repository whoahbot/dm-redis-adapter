begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require 'spec/rake/spectask'

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
    gemspec.add_dependency "dm-core", ">= 1.0.0"
    gemspec.add_dependency "dm-types", ">= 1.0.0"
    gemspec.add_dependency "redis", ">= 2.0.3"
    gemspec.files = %w(MIT-LICENSE README.textile Rakefile) + Dir.glob("{lib,spec}/**/*")
    gemspec.has_rdoc = false
    gemspec.extra_rdoc_files = ["MIT-LICENSE"]
    gemspec.post_install_message = <<-POST_INSTALL_MESSAGE
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

                       (!!)   U P G R A D I N G    (!!)

                         WAAAAAAAAAAAAAAAAAAAAAAAAIT!

                  Versions of dm-redis-adapter prior to v0.1
                 use a different method of storing properties
               which means that this version of dm-redis-adapter
                          won't read them properly.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
POST_INSTALL_MESSAGE
    end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end


task :default => :spec

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = %w(-fs --color)
end
