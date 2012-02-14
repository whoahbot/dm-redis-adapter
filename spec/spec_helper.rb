begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require 'dm-core'
require 'dm-core/spec/shared/adapter_spec'
require 'dm-redis-adapter/spec/setup'

ENV['ADAPTER']          = 'redis'
ENV['ADAPTER_SUPPORTS'] = 'all'
