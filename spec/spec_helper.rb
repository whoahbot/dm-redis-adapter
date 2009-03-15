require 'rubygems'
require 'dm-core'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/redis_adapter'))

DataMapper.setup(:default, {
  :adapter  => "redis",
  :database => 15
})