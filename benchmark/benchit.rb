require 'rubygems'
require 'dm-core'
require 'benchmark'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/redis_adapter.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/rubyredis.rb'))

DataMapper.setup(:default, {
  :adapter  => "redis",
  :database => 15
})

class Post
  include DataMapper::Resource
  
  property :id,   Serial
  property :text, Text
end

Benchmark.benchmark do |x|
  x.report { 1000.times { Post.create(:text => "I like ice cream") } }
end

Benchmark.benchmark do |x|
  x.report { Post.all.each {|x| x.text } }
end

redis = RedisClient.new(:db => 15)
redis.flushdb